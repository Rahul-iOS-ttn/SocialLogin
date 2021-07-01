//
//  AppleSignInWrapper.swift
//  SocialLogin
//
//  Created by TTN on 24/06/21.
//

import Foundation
import AuthenticationServices
import KeychainAccess


@available(iOS 12.0, *)
extension ASPasswordCredential: ANUserAuth {
    
    public var typeOfSignInMethod: ANSignInType {
        .apple
    }
    
    public var authToken: String? {
        nil
    }
    
    public var authTokenSecret: String? {
        nil
    }
    
    public var passwordCredentials: ANPasswordCredential? {
        self
    }
    
    public var anUser: ANUser? {
        nil
    }
    
    
}


@available(iOS 12.0, *)
extension ASPasswordCredential: ANPasswordCredential {
    public var username: String {
        user
    }
}



@available(iOS 13.0, *)
extension ASAuthorizationAppleIDCredential: ANUserAuth, ANUser {
    
    public var typeOfSignInMethod: ANSignInType {
        .apple
    }
    
    
    public var isNew: Bool {
        email != nil
    }
    
    
    public var authToken: String? {
        guard let token = identityToken else {
            return ""
        }
        return String(data: token, encoding: .utf8) ?? ""
    }
    
    public var authTokenSecret: String? {
        guard let authCode = authorizationCode else {
            return ""
        }
        return String(data: authCode, encoding: .utf8) ?? ""
    }
    
    public var passwordCredentials: ANPasswordCredential? {
        nil
    }
    
    public var anUser: ANUser? {
        self
    }
    
    public var profileName: String? {
        
        var name: String = ""
        if let givenName = fullName?.givenName {
            name += givenName
        }
        
        if let middleName = fullName?.middleName {
            name = name.isEmpty ? middleName : name + " " + middleName
        }
        
        if let familyName = fullName?.familyName {
            name = name.isEmpty ? familyName : name + " " + familyName
        }
        
        return name
    }
    
    public var userId: String {
        user
    }
    
}


/// Apple SignIn Error
@available(iOS 13.0, *)
enum AppleSignInError: LocalizedError {
    case canceled
    case failed
    case invalidResponse
    case notHandled
    case unknown
    case unknownDefault(Error?)
    
    var errorDescription: String? {
        switch self {
        case .canceled:
            return "Sign In request is cancelled"
        case .failed:
            return "Apple Sign In authorization failed"
        case .invalidResponse:
            return "Apple Sign In can not be performed due to no valid auth tokens"
        case .notHandled:
            return "Apple Sign In authorization failed"
        case .unknown:
            return "It seems you are'nt login with your Apple ID on the device"
        case .unknownDefault:
            return localizedDescription
        }
    }
    
    static func parseError(error: Error) -> Error {
        
        if let error = error as? ASAuthorizationError {
        
            switch error.code {
            case .canceled:
                return AppleSignInError.canceled
            case .failed:
                return AppleSignInError.failed
            case .invalidResponse:
                return AppleSignInError.invalidResponse
            case .notHandled:
                return AppleSignInError.notHandled
            case .unknown:
                return AppleSignInError.unknown
            @unknown default:
                return AppleSignInError.unknownDefault(error)
            }
        }else {
            return AppleSignInError.unknownDefault(error)
        }
    }
}

@available(iOS 13.0, *)
class AppleSignInWrapper: NSObject, SignInWrappable {
    
    var typeOfSignInMethod: ANSignInType {
        .apple
    }
    
    var currentProfile: ANUserAuth? {
        appleIDCredential ?? applePasswordCredential
    }
    
    
    private lazy var keychain: Keychain = {
        return Keychain(service: keychainServiceName).synchronizable(true)
    }()
    
    private var signInHandler : ((Result<ANUserAuth, Error>) -> ())?
    private var keychainServiceName: String = ".ANAuthLogin"
    private weak var contextView: UIViewController!
    private var appleIDCredential: ANAuthUser?
    private var applePasswordCredential: ANAuthUser?
    
    
    func hasPreviousSignIn(handler: @escaping (Bool) -> ()) {
        
        guard let appleId = keychain["identifier"] else {
            handler(false)
            return
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: appleId) { (credentialState, error) in
            switch credentialState {
            case .authorized:
                 // The Apple ID credential is valid.
                if Thread.isMainThread {
                    handler(true)
                }else {
                    DispatchQueue.main.async {
                        handler(true)
                    }
                }
                
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                
                
                if Thread.isMainThread {
                    handler(false)
                }else {
                    DispatchQueue.main.async {
                        handler(false)
                    }
                }
            default:
                break
            }
        }
    }
    
    func setUpLoginService(setUpConfig: ANAuthServiceSetupConfig?) throws {
        
        /// Setting the keychainServiceName
        if let config = setUpConfig {
            keychainServiceName = config.keychainServiceName + keychainServiceName + ".AppleSignIn"
        }
        
    }
    
    func addSignInWrapper(_ wrapper: SignInWrappable) {}
    func disableSignInType(_ signInType: ANSignInType) {}
    
    func signIn(with type: ANSignInType, fromView: UIViewController?, handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        guard let view = fromView else {
            handler(.failure(ANSignInError.setupError(type: .apple)))
            return
            
        }
        
        contextView = view
        signInHandler = handler
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
        
    }
    
    func signOut(handler: @escaping (Result<Bool, Error>) -> ()) {
        appleIDCredential = nil
        applePasswordCredential = nil
        unobserveAppleIdRevokedNotification()
        contextView = nil
        handler(.success(true))
        
    }
    
    func clearSessionOnExternalError() {
        
        keychain["username"] = nil
        keychain["password"] = nil
        signOut(handler: {_ in })
    }
    
    func handle(_ app: UIApplication?, open url: URL?, options: [UIApplication.OpenURLOptionsKey : Any]?) -> Bool {
        return true
    }
    
    func restoreUserSession(completion handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        signInHandler = handler
        
        let requests = [
          ASAuthorizationAppleIDProvider().createRequest(),
          ASAuthorizationPasswordProvider().createRequest()
        ]
        
        
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func restoreUserSessionExplicit(with type: ANSignInType, completion handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        restoreUserSession(completion: handler)
    }
    
    private func observeAppleIdRevokedNotification() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(appleIDStateRevoked), name: ASAuthorizationAppleIDProvider.credentialRevokedNotification, object: nil)
    }
    
    private func unobserveAppleIdRevokedNotification() {
        NotificationCenter.default.removeObserver(self, name: ASAuthorizationAppleIDProvider.credentialRevokedNotification, object: nil)
    }
    
    private func saveAppleIdCredential(credential: ASAuthorizationAppleIDCredential) {
        if let email = credential.email {
            keychain["email"] = email
        }
        if let name = credential.profileName, !name.isEmpty {
            keychain["name"] = name
        }
        
        keychain["identifier"] = credential.userId
    }
    
    private func savePasswordCredential(credential: ASPasswordCredential) {
        keychain["username"] = credential.user
        keychain["password"] = credential.password
    }
    
    @objc func appleIDStateRevoked() {
        
        func applyOnIdRevoked() {
            keychain["email"] = nil
            keychain["name"] = nil
            keychain["identifier"] = nil
            
            NotificationCenter.default.post(name: Notification.Name.ANCredentialRevoked, object: nil)
        }
        if Thread.isMainThread {
            applyOnIdRevoked()
        } else {
            DispatchQueue.main.async {
                applyOnIdRevoked()
            }
        }
        
    }
    
}

@available(iOS 13.0, *)
extension AppleSignInWrapper: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let authorizedAppleIdCredential as ASAuthorizationAppleIDCredential:
            
            let appleIdCredentialCustomObj = ANAuthUser(authToken: authorizedAppleIdCredential.authToken, authTokenSecret: authorizedAppleIdCredential.authTokenSecret, passwordCredentials: nil, anUser: ANUserDetail(profileName: (authorizedAppleIdCredential.profileName ?? "").isEmpty ? keychain["name"] : (authorizedAppleIdCredential.profileName ?? "") , userId: authorizedAppleIdCredential.userId, isNew: authorizedAppleIdCredential.isNew, email: authorizedAppleIdCredential.email ?? keychain["email"]), typeOfSignInMethod: authorizedAppleIdCredential.typeOfSignInMethod)
        
            appleIDCredential = appleIdCredentialCustomObj
            applePasswordCredential = nil
            saveAppleIdCredential(credential: authorizedAppleIdCredential)
            observeAppleIdRevokedNotification()
            signInHandler?(.success(appleIdCredentialCustomObj))
            signInHandler = nil
            
           /*
          if let _ = authorizedAppleIdCredential.email {
            
           // registerNewAccount(credential: appleIdCredential)
          } else {
           // signInWithExistingAccount(credential: appleIdCredential)
          }*/

          break
          
        case let passwordCredential as ASPasswordCredential:
          //signInWithUserAndPassword(credential: passwordCredential)
            
            let applePasswordCredentialCustomObj = ANAuthUser(authToken: nil, authTokenSecret: nil, passwordCredentials: passwordCredential, anUser: nil, typeOfSignInMethod: passwordCredential.typeOfSignInMethod)
            applePasswordCredential = applePasswordCredentialCustomObj
            appleIDCredential = nil
            savePasswordCredential(credential: passwordCredential)
            signInHandler?(.success(applePasswordCredentialCustomObj))
            signInHandler = nil
            
          break
          
        default:
          break
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        signInHandler?(.failure(AppleSignInError.parseError(error: error)))
        signInHandler = nil
        
    }
}


@available(iOS 13.0, *)
extension AppleSignInWrapper: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return contextView.view.window ?? UIApplication.shared.windows.first!
    }
    
    
}
