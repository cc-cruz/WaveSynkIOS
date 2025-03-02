import Foundation
import CommonCrypto
import Security

class CertificatePinningService: NSObject {
    static let shared = CertificatePinningService()
    
    // Store the public key hashes for our servers
    private var trustedPublicKeyHashes: [String: [String]] = [
        "api.wavesynk.com": [
            // Production server public key hash (SHA-256)
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Replace with actual hash
        ],
        "dev-api.wavesynk.com": [
            // Development server public key hash (SHA-256)
            "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=", // Replace with actual hash
        ],
        "staging-api.wavesynk.com": [
            // Staging server public key hash (SHA-256)
            "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=", // Replace with actual hash
        ]
    ]
    
    // Track if certificate pinning is enabled
    private var isPinningEnabled = true
    
    // Create a URLSession with the delegate for certificate pinning
    private(set) lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // Session without certificate pinning for fallback
    private lazy var unpinnedSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        
        return URLSession(configuration: configuration)
    }()
    
    private override init() {
        super.init()
        
        // Load any saved hashes from secure storage
        loadSavedHashes()
    }
    
    // MARK: - Certificate Management
    
    /// Updates the trusted hashes for a specific host
    /// - Parameters:
    ///   - host: The host domain to update hashes for
    ///   - hashes: The new array of trusted hashes
    ///   - shouldSave: Whether to persist the changes to secure storage
    func updateTrustedHashes(for host: String, with hashes: [String], shouldSave: Bool = true) {
        trustedPublicKeyHashes[host] = hashes
        
        if shouldSave {
            saveTrustedHashes()
        }
    }
    
    /// Adds a new trusted hash for a host
    /// - Parameters:
    ///   - hash: The certificate hash to trust
    ///   - host: The host domain
    ///   - shouldSave: Whether to persist the changes to secure storage
    func addTrustedHash(_ hash: String, for host: String, shouldSave: Bool = true) {
        if var existingHashes = trustedPublicKeyHashes[host] {
            if !existingHashes.contains(hash) {
                existingHashes.append(hash)
                trustedPublicKeyHashes[host] = existingHashes
                
                if shouldSave {
                    saveTrustedHashes()
                }
            }
        } else {
            trustedPublicKeyHashes[host] = [hash]
            
            if shouldSave {
                saveTrustedHashes()
            }
        }
    }
    
    /// Removes a trusted hash for a host
    /// - Parameters:
    ///   - hash: The certificate hash to remove
    ///   - host: The host domain
    ///   - shouldSave: Whether to persist the changes to secure storage
    func removeTrustedHash(_ hash: String, for host: String, shouldSave: Bool = true) {
        if var existingHashes = trustedPublicKeyHashes[host] {
            existingHashes.removeAll { $0 == hash }
            trustedPublicKeyHashes[host] = existingHashes
            
            if shouldSave {
                saveTrustedHashes()
            }
        }
    }
    
    // MARK: - Persistence
    
    /// Saves the trusted hashes to secure storage
    private func saveTrustedHashes() {
        // Convert to Data
        guard let data = try? JSONSerialization.data(withJSONObject: trustedPublicKeyHashes) else {
            return
        }
        
        // Save to Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.wavesynk.certificatePinning",
            kSecAttrAccount as String: "trustedHashes",
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Loads the trusted hashes from secure storage
    private func loadSavedHashes() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.wavesynk.certificatePinning",
            kSecAttrAccount as String: "trustedHashes",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let savedHashes = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] else {
            return
        }
        
        // Merge with default hashes, keeping both
        for (host, hashes) in savedHashes {
            if var existingHashes = trustedPublicKeyHashes[host] {
                for hash in hashes {
                    if !existingHashes.contains(hash) {
                        existingHashes.append(hash)
                    }
                }
                trustedPublicKeyHashes[host] = existingHashes
            } else {
                trustedPublicKeyHashes[host] = hashes
            }
        }
    }
    
    // MARK: - Certificate Validation
    
    /// Helper method to extract the public key hash from a certificate
    func publicKeyHash(for certificate: SecCertificate) -> String? {
        // Get the public key from the certificate
        var publicKey: SecKey?
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
        if status == errSecSuccess, let trust = trust {
            publicKey = SecTrustCopyPublicKey(trust)
        }
        
        guard let publicKey = publicKey else { return nil }
        
        // Get the public key data
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }
        
        // Hash the public key data using SHA-256
        let hash = publicKeyData.sha256()
        return hash.base64EncodedString()
    }
    
    /// Method to verify if a certificate is trusted
    func isCertificateTrusted(_ certificate: SecCertificate, for host: String) -> Bool {
        // If pinning is disabled, always return true
        if !isPinningEnabled {
            return true
        }
        
        guard let hash = publicKeyHash(for: certificate),
              let trustedHashes = trustedPublicKeyHashes[host] else {
            return false
        }
        
        return trustedHashes.contains(hash)
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// Disables certificate pinning for testing purposes
    /// - Returns: The unpinned URLSession
    func disableCertificatePinning() -> URLSession {
        isPinningEnabled = false
        return unpinnedSession
    }
    
    /// Re-enables certificate pinning
    func enableCertificatePinning() {
        isPinningEnabled = true
    }
    
    /// Extracts and adds the certificate hash for a host
    func extractAndTrustCertificate(for host: String) async {
        if let hash = await CertificateHashExtractor.extractPublicKeyHash(from: host) {
            addTrustedHash(hash, for: host)
            print("Added trusted hash for \(host): \(hash)")
        }
    }
    #endif
}

// MARK: - URLSessionDelegate
extension CertificatePinningService: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // If pinning is disabled, accept the challenge
        if !isPinningEnabled {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            return
        }
        
        // Check if the challenge is for server trust
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host.components(separatedBy: ":").first else {
            // If not, reject the challenge
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Check if we have trusted hashes for this host
        guard let trustedHashes = trustedPublicKeyHashes[host] else {
            // If we don't have trusted hashes for this host, use default handling
            #if DEBUG
            // In debug mode, accept the certificate to allow testing with different servers
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            #else
            // In production, reject unknown hosts
            completionHandler(.cancelAuthenticationChallenge, nil)
            #endif
            return
        }
        
        // Evaluate the server trust
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)
        
        var secResult = SecTrustResultType.invalid
        SecTrustEvaluate(serverTrust, &secResult)
        
        // Only proceed if the trust evaluation succeeded
        guard secResult == .proceed || secResult == .unspecified else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get the server's certificate chain
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        // Check if we have at least one certificate
        guard certificateCount > 0,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get the public key hash from the certificate
        guard let hash = publicKeyHash(for: certificate) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Check if the hash is in our trusted hashes
        if trustedHashes.contains(hash) {
            // If it is, accept the challenge
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // If not, reject the challenge
            completionHandler(.cancelAuthenticationChallenge, nil)
            
            // Log the untrusted hash for debugging
            #if DEBUG
            print("Untrusted certificate hash for \(host): \(hash)")
            #endif
        }
    }
}

// MARK: - Data Extension for SHA-256
extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}

// MARK: - Environment-specific Configuration
extension CertificatePinningService {
    // Helper method to get the appropriate host for the current environment
    static func hostForCurrentEnvironment() -> String {
        switch AppEnvironment.current {
        case .development:
            return "dev-api.wavesynk.com"
        case .staging:
            return "staging-api.wavesynk.com"
        case .production:
            return "api.wavesynk.com"
        }
    }
} 