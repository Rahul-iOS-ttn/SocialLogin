//
//  FBSignInWrapper.swift
//  SocialLogin
//
//  Created by TTN on 24/06/21.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit



enum FBSignInError: LocalizedError {
    case cancelled
    case permissionDeclined
    case profileFetchError
    case sessionRestoreError
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Cancelled by user"
        case .permissionDeclined:
            return "Permission is declined"
        case .profileFetchError:
            return "Could not fetch user profile"
        case .sessionRestoreError:
            return "Could not restore session, Please re-login"
        @unknown default:
            return "Facebook login failed - undefined"
        }
    }
}

extension AccessToken : ANUserAuth {
    
    public var typeOfSignInMethod: ANSignInType {
        .facebook
    }
    
    public var passwordCredentials: ANPasswordCredential? {
        nil
    }
    
    public var authToken: String? {
        tokenString
    }
    
    public var authTokenSecret: String? {
        nil
    }
    
    public var anUser: ANUser? {
        Profile.current
    }
    
}

extension Profile : ANUser {
    
    public var profileName: String? {
        name ?? ""
    }
    
    public var email: String? {
        ""
    }
    
    public var userId: String {
        userID
    }
    
    public var isNew: Bool {
        false
    }
    
    
}


class FBSignInWrapper : SignInWrappable {
    
    public var typeOfSignInMethod: ANSignInType {
        .facebook
    }
    
    var currentProfile: ANUserAuth? {
        AccessToken.current
    }
    
    lazy var loginManager : LoginManager = {
        let fblogin = LoginManager()
        
        return fblogin
    }()
    
    private var hasPreviousSignIn: Bool {
        AccessToken.current != nil
    }
    
    func hasPreviousSignIn(handler: @escaping (Bool) -> ()) {
        handler(hasPreviousSignIn)
    }
    
    func addSignInWrapper(_ wrapper: SignInWrappable) {}
    func disableSignInType(_ signInType: ANSignInType) {}
    
    func setUpLoginService(setUpConfig: ANAuthServiceSetupConfig?) throws {
        
        guard let app = setUpConfig?.application else { throw ANSignInError.setupError(type: ANSignInType.facebook) }
        
        ApplicationDelegate.shared.application(app, didFinishLaunchingWithOptions: setUpConfig?.loginOptions)
        
    }
    
    func signIn(with type: ANSignInType, fromView: UIViewController?, handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        
        
        loginManager.logIn(permissions: [Permission.publicProfile.name,Permission.email.name], from: fromView) { result, error in
            
            if let fbError = error {
                handler(.failure(ANSignInError.signInFailed(fbError)))
                
            }else if let fbResult = result {
                
                if fbResult.isCancelled {
                    handler(.failure(FBSignInError.cancelled))
                }else if fbResult.token == nil {
                    if fbResult.declinedPermissions.count > 0 {
                        handler(.failure(FBSignInError.permissionDeclined))
                    }
                }else {
                    //handler(.success(fbResult.token!))
                    self.getCurrentUser(handler: handler)
                }
            }
            
        }
        
    }
    
    func signOut(handler: @escaping (Result<Bool, Error>) -> ()) {
        
        if AccessToken.current != nil {
            
            loginManager.logOut()
            
        }
        
        handler(.success(true))
    }
    
    func clearSessionOnExternalError() {
        signOut(handler: {_ in })
    }
    
    func handle(_ app: UIApplication?, open url: URL?, options: [UIApplication.OpenURLOptionsKey : Any]?) -> Bool {
        
        guard let openUrl = url else { return false }
        guard let app = app else { return false }
        guard let options = options else { return false }
        return ApplicationDelegate.shared.application(app, open: openUrl, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        //return ApplicationDelegate.shared.application(app, open: openUrl, options: options)
    }
    
    func restoreUserSession(completion handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        if AccessToken.current != nil {
            getCurrentUser(handler: handler)
        }else {
            handler(.failure(FBSignInError.sessionRestoreError))
        }
    }
    
    func restoreUserSessionExplicit(with type: ANSignInType, completion handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        restoreUserSession(completion: handler)
    }
    
    private func getCurrentUser(handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        /* Profile.loadCurrentProfile { (profile, error) in
         
         if let errorLc = error  {
         handler(.failure(errorLc))
         }else if let token = AccessToken.current {
         handler(.success(token))
         }else {
         handler(.failure(FBSignInError.profileFetchError))
         }
         }*/
        
        GraphRequest(graphPath: "me", parameters: ["fields":"id, email, name, picture.width(480).height(480)"]).start { connecction, result, error in
            Profile.current = Profile(userID: "ddas", firstName: "dasda", middleName: "dsada", lastName: "dasda", name: "dasda", linkURL: nil, refreshDate: nil)
            if let errorLc = error  {
                handler(.failure(errorLc))
            }else if let token = AccessToken.current {
                print( "result - \(String(describing: result))")
                handler(.success(token))
            }else {
                handler(.failure(FBSignInError.profileFetchError))
            }
            
        }
    }
    
}

