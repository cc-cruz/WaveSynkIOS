import Foundation
import CommonCrypto
import Security
import Network
import CryptoKit
import NetworkExtension

#if DEBUG
class CertificateHashExtractor {
    static func extractPublicKeyHash(from host: String, port: Int = 443) async -> String? {
        return await withCheckedContinuation { continuation in
            // Create a TLS connection to the host
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)))
            let parameters = NWParameters.tls
            
            // Create a connection
            let connection = NWConnection(to: endpoint, using: parameters)
            
            // Set up state handler
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // Connection established, extract the certificate
                    extractCertificate(from: connection) { hash in
                        connection.cancel()
                        continuation.resume(returning: hash)
                    }
                case .failed(let error):
                    print("Connection failed: \(error)")
                    connection.cancel()
                    continuation.resume(returning: nil)
                case .cancelled:
                    continuation.resume(returning: nil)
                default:
                    break
                }
            }
            
            // Start the connection
            connection.start(queue: .global())
        }
    }
    
    private static func extractCertificate(from connection: NWConnection, completion: @escaping (String?) -> Void) {
        // Get the TLS handshake metadata
        connection.metadata(definition: TLSMetadata.definition) { (metadata: TLSMetadata?, error) in
            guard let tlsMetadata = metadata,
                  let certificate = tlsMetadata.serverCertificate else {
                completion(nil)
                return
            }
            
            // Extract the public key hash
            let hash = CertificatePinningService.shared.publicKeyHash(for: certificate)
            completion(hash)
        }
    }
}

// MARK: - TLS Metadata Helper
private class TLSMetadata {
    static let definition = NWProtocolTLS.definition
    
    var serverCertificate: SecCertificate? {
        // Simplified approach for debugging purposes
        return nil
    }
    
    private let secProtocolMetadata: sec_protocol_metadata_t
    
    init?(metadata: sec_protocol_metadata_t?) {
        guard let metadata = metadata else { return nil }
        secProtocolMetadata = metadata
    }
}

// MARK: - NWConnection Extension
extension NWConnection {
    func metadata<T>(definition: NWProtocolDefinition, completion: @escaping (T?, Error?) -> Void) {
        let _ = DispatchQueue(label: "com.wavesynk.metadata")
        
        self.receiveMessage { content, context, isComplete, error in
            guard let context = context else {
                completion(nil, error)
                return
            }
            
            let metadata = context.protocolMetadata(definition: definition)
            if let tlsMetadata = metadata as? NWProtocolTLS.Metadata {
                let secMetadata = tlsMetadata.securityProtocolMetadata
                
                if let typedMetadata = TLSMetadata(metadata: secMetadata) as? T {
                    completion(typedMetadata, nil)
                } else {
                    completion(nil, nil)
                }
            } else {
                completion(nil, nil)
            }
        }
    }
}

// MARK: - Command Line Tool
extension CertificateHashExtractor {
    static func printHashForHost(_ host: String) async {
        print("Extracting public key hash for \(host)...")
        if let hash = await extractPublicKeyHash(from: host) {
            print("Public key hash for \(host): \(hash)")
            print("Add this to your trustedPublicKeyHashes dictionary in CertificatePinningService.")
        } else {
            print("Failed to extract public key hash for \(host)")
        }
    }
}
#endif 