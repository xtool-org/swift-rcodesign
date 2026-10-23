import Foundation
import RCodesignBinary

public enum RCodesign {
    public enum Identity: Sendable {
        case adHoc
        /// The private key must be one unencrypted PKCS#1 or PKCS#8 PEM block.
        case certificate(certificateDER: Data, privateKeyPEM: Data)
    }

    public struct SigningOptions: Sendable {
        public var identifier: String?
        /// XML or binary entitlements dictionaries keyed by bundle-relative path.
        /// Use "" for the root bundle and e.g. "PlugIns/Widget.appex" for an extension.
        /// Omitted bundles use upstream metadata import; an empty plist dictionary
        /// explicitly replaces their existing entitlements.
        public var entitlements: [String: Data]
        /// Skips nested bundles; embedded standalone Mach-O files may still be signed.
        /// Nested entitlement entries require this to be false.
        public var shallow: Bool

        public init(identifier: String? = nil, entitlements: [String: Data] = [:], shallow: Bool = false) {
            self.identifier = identifier
            self.entitlements = entitlements
            self.shallow = shallow
        }
    }

    public struct Error: Swift.Error, Sendable, LocalizedError {
        public let message: String
        public var errorDescription: String? { message }
    }

    /// Sign a filesystem path using an ad-hoc or certificate identity. A nil output signs in place.
    ///
    /// This uses apple-codesign's metadata import and bundle signing policies.
    /// In-place signing is not transactional; a failure may leave a bundle partly updated.
    public static func sign(
        at input: URL,
        to output: URL? = nil,
        identity: Identity,
        options: SigningOptions = .init()
    ) throws {
        guard input.isFileURL, output?.isFileURL != false else {
            throw Error(message: "Signing requires file URLs")
        }
        try withOptionalCString(input.path) { inputPath in
            try withOptionalCString(output?.path) { outputPath in
                try withOptionalCString(options.identifier) { identifier in
                    try withIdentity(identity) { identity in
                        try withEntitlements(options.entitlements) { entitlements in
                            var native = rcodesign_sign_options(
                                identifier: identifier,
                                entitlements: entitlements.baseAddress,
                                entitlements_count: entitlements.count,
                                shallow: options.shallow ? 1 : 0
                            )
                            try check { rcodesign_sign(inputPath, outputPath, identity, &native, $0) }
                        }
                    }
                }
            }
        }
    }

    private static func withIdentity<Result>(
        _ identity: Identity,
        body: (UnsafePointer<rcodesign_identity>?) throws -> Result
    ) rethrows -> Result {
        switch identity {
        case .adHoc:
            return try body(nil)
        case .certificate(let certificate, let key):
            return try certificate.withUnsafeBytes { certificate in
                try key.withUnsafeBytes { key in
                    var native = rcodesign_identity(
                        certificate_der: certificate.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        certificate_der_len: certificate.count,
                        private_key_pem: key.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        private_key_pem_len: key.count
                    )
                    return try withUnsafePointer(to: &native, body)
                }
            }
        }
    }

    private static func withEntitlements<Result>(
        _ mapping: [String: Data],
        body: (UnsafeBufferPointer<rcodesign_entitlements>) throws -> Result
    ) throws -> Result {
        let sorted = mapping.sorted { $0.key < $1.key }
        guard !sorted.contains(where: { $0.key.utf8.contains(0) }) else {
            throw Error(message: "Bundle paths must not contain NUL bytes")
        }
        let paths = sorted.map { $0.key as NSString }
        let plists = sorted.map { $0.value as NSData }
        let entries = zip(paths, plists).map { path, plist in
            rcodesign_entitlements(
                bundle_path: path.utf8String,
                plist: plist.bytes.assumingMemoryBound(to: UInt8.self),
                plist_len: plist.length
            )
        }
        // Each C entry borrows pointers into these Foundation objects. Keep every
        // path and plist alive until the entire synchronous signing call returns,
        // rather than letting a pointer escape a temporary withUnsafeBytes closure.
        return try withExtendedLifetime((paths, plists)) {
            try entries.withUnsafeBufferPointer(body)
        }
    }

    private static func check(_ operation: (UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) -> Int32) throws {
        var error: UnsafeMutablePointer<CChar>?
        defer { rcodesign_error_free(error) }
        guard operation(&error) == 0 else {
            throw Error(message: error.map { String(cString: $0) } ?? "Unknown apple-codesign error")
        }
    }

    private static func withOptionalCString<Result>(
        _ string: String?,
        body: (UnsafePointer<CChar>?) throws -> Result
    ) throws -> Result {
        guard let string else { return try body(nil) }
        guard !string.utf8.contains(0) else { throw Error(message: "Strings must not contain NUL bytes") }
        return try string.withCString(body)
    }
}
