//
//  GoogleSignInWrapper.swift
//  SocialLogin
//
//  Created by TTN on 24/06/21.
//

import Foundation
import GoogleSignIn

/// Google SignIn Error
enum GSignInError: LocalizedError {
    case canceled
    case hasNoAuthInKeychain
    case keychainReadWrite
    case unknown
    case unknownDefault(Error?)
    
    var errorDescription: String? {
        switch self {
        case .canceled:
            return "Sign In request is cancelled"
        case .hasNoAuthInKeychain:
            return "Sign In can not be performed due to no valid auth tokens can be read from keychain"
        case .keychainReadWrite:
            return "Sign In can not be performed due to issue with reading or writing to the application keychain"
        case .unknown:
            return "Some error has occurred, Please try again."
        case .unknownDefault:
            return localizedDescription
        }
    }
    
    static func parseError(error: Error) -> Error {
        
        let error = error as NSError
        
        switch error.code {
        
        case GIDSignInErrorCode.unknown.rawValue:
            return GSignInError.unknown
        case GIDSignInErrorCode.canceled.rawValue:
            return GSignInError.canceled
        case GIDSignInErrorCode.hasNoAuthInKeychain.rawValue:
            return GSignInError.hasNoAuthInKeychain
        case GIDSignInErrorCode.keychain.rawValue:
            return GSignInError.keychainReadWrite
        default:
            return GSignInError.unknownDefault(error)
        }
        
    }
}

extension GIDGoogleUser : ANUserAuth {
    
    public var typeOfSignInMethod: ANSignInType {
        .google
    }
    
    
    public var passwordCredentials: ANPasswordCredential? {
        nil
    }
    
    public var authToken: String? {
        return authentication.idToken
    }
    
    public var authTokenSecret: String? {
        return nil
    }
    
    public var anUser: ANUser? {
        return self
    }
}

extension GIDGoogleUser : ANUser {
    
    
    public var email: String? {
        return self.profile.email
    }
    
    public var isNew: Bool {
        return false
    }
    
    public var profileName: String? {
        return self.profile.name
    }
    
    public var userId: String {
        return userID
    }
    
}

class GoogleSignInWrapper : NSObject ,SignInWrappable, GIDSignInDelegate {
    
    
    
    var typeOfSignInMethod: ANSignInType {
        
        .google
    }
    
    
    var currentProfile: ANUserAuth? {
        GIDSignIn.sharedInstance().currentUser
    }
    
    private var signInHandler : ((Result<ANUserAuth, Error>) -> ())?
    
    private var hasPreviousSignIn: Bool {
        return GIDSignIn.sharedInstance()?.hasPreviousSignIn() ?? false
    }
    
    func hasPreviousSignIn(handler: @escaping (Bool) -> ()) {
        handler(GIDSignIn.sharedInstance()?.hasPreviousSignIn() ?? false)
    }
    
    func setUpLoginService(setUpConfig: ANAuthServiceSetupConfig?) throws {
        
        guard let clientId = setUpConfig?.googleClientId else { throw ANSignInError.setupError(type: ANSignInType.google) }
        
        // Initialize sign-in
        GIDSignIn.sharedInstance().clientID = clientId
        GIDSignIn.sharedInstance().delegate = self
    }
    
    func addSignInWrapper(_ wrapper: SignInWrappable) {}
    func disableSignInType(_ signInType: ANSignInType) {}
    
    func signIn(with type: ANSignInType, fromView: UIViewController?, handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        guard let view = fromView else {
            handler(.failure(ANSignInError.setupError(type: .google)))
            return
            
        }
        
        signInHandler = handler
        GIDSignIn.sharedInstance()?.presentingViewController = view
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    
    func signOut(handler: @escaping (Result<Bool, Error>) -> ()) {
        GIDSignIn.sharedInstance()?.signOut()
        handler(.success(true))
    }
    
    func clearSessionOnExternalError() {
        signOut(handler: {_ in })
    }
    
    func handle(_ app: UIApplication?, open url: URL?, options: [UIApplication.OpenURLOptionsKey : Any]?) -> Bool {
        
        guard let openUrl = url else { return false }
        return GIDSignIn.sharedInstance().handle(openUrl)
    }
    
    func restoreUserSession(completion handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        // add body for restore session
        signInHandler = handler
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
    }
    
    func restoreUserSessionExplicit(with type: ANSignInType, completion handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        restoreUserSession(completion: handler)
    }
    
    
    // [START signin_handler]
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            signInHandler?(.failure(GSignInError.parseError(error: error)))
            
            return
        }
        
        signInHandler?(.success(user))
        
        
    }
}
