//
//  GoogleSignInWrapper.swift
//  SocialLogin
//
//  Created by TTN on 24/06/21.
//

import Foundation
import GoogleSignIn


enum GSignInError: LocalizedError {
    case error(code: Int, error: Error)
    
    var errorDescription: String? {
        switch self {
        case .error(let code, let error):
            switch code {
            case GIDSignInErrorCode.unknown.rawValue:
                fallthrough
            case GIDSignInErrorCode.canceled.rawValue:
                return "Google Sign In request is cancelled"
            case GIDSignInErrorCode.hasNoAuthInKeychain.rawValue, GIDSignInErrorCode.keychain.rawValue:
                return "SignIn can not be performed due to no valid auth tokens can be read from keychain"
            default:
                return error.localizedDescription
            }
        default:
            break
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
    
    func addSignUpWrapper(_ wrapper: SignUpWrappable) {}
    
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
            signInHandler?(.failure(ANSignInError.signInFailed(GSignInError.error(code: (error as NSError).code, error: error))))
            
            return
        }
        
        signInHandler?(.success(user))
        
        
    }
}
