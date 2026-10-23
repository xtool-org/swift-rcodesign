import Foundation
import RCodesign
import Testing

struct RCodesignTests {
    @Test func signingErrorsCrossTheCBridge() {
        #expect(throws: RCodesign.Error.self) {
            try RCodesign.sign(at: URL(fileURLWithPath: "/dev/null"), identity: .adHoc)
        }
    }

    @Test func invalidIdentityDoesNotFallBackToAdHoc() {
        do {
            try RCodesign.sign(
                at: URL(fileURLWithPath: "/dev/null"),
                identity: .certificate(certificateDER: Data(), privateKeyPEM: Data())
            )
            Issue.record("An empty certificate identity was accepted")
        } catch let error as RCodesign.Error {
            #expect(error.message.contains("invalid signing certificate"))
        } catch {
            Issue.record(error)
        }
    }

    @Test func entitlementPathsCrossTheCBridge() {
        let xml = Data("<plist><dict/></plist>".utf8)
        do {
            try RCodesign.sign(
                at: URL(fileURLWithPath: "/dev/null"), identity: .adHoc,
                options: .init(entitlements: ["../Widget.appex": xml])
            )
            Issue.record("A non-relative entitlement path was accepted")
        } catch let error as RCodesign.Error {
            #expect(error.message.contains("normalized relative bundle path"))
        } catch {
            Issue.record(error)
        }
    }

}
