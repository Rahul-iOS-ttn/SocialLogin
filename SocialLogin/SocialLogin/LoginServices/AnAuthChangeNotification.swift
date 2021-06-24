//
//  AnAuthChangeNotification.swift
//  SocialLogin
//
//  Created by TTN on 24/06/21.
//

import Foundation


// MARK: Credential Observer Protocol
extension NSNotification.Name {
    static var ANCredentialRevoked = NSNotification.Name(rawValue: "ANCredentialRevokedNotification")
    
}


/// Confirm to CredentialRevokedObservable and observing to Credential Revoked notification will immidiately fire credentialRevoked function call
public protocol CredentialRevokedObservable: AnyObject {
    var observerToken: NSObjectProtocol? { get set}
    func observeCredential()
    func unobserveCredential()
    func credentialRevoked()
}

public extension CredentialRevokedObservable {
    
    func observeCredential() {
        
       observerToken = NotificationCenter.default.addObserver(forName: NSNotification.Name.ANCredentialRevoked, object: nil, queue: nil) { [weak self] _ in
            self?.credentialRevoked()
        }
        
    }
    
    func unobserveCredential() {
        
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
        } else {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.ANCredentialRevoked, object: nil)
        }
        
    }
}
