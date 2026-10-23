These are public, generated test credentials, never used for real signing.
`certificate.der` is a self-signed RSA code-signing certificate; `key-pkcs1.pem`
and `key-pkcs8.pem` encode the same matching key. `unrelated-key.pem` exercises
rejection of mismatched credentials. No test relies on trusting this certificate
or on its expiration date.
