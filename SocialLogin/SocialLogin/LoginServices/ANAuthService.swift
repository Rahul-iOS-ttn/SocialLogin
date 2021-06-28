//
//  ANAuthService.swift
//  SocialLogin
//
//  Created by TTN on 24/06/21.
//

import Foundation
import UIKit
import KeychainAccess

@available(iOS 13.0, *)
public class ANAuthService : NSObject , SignInWrappable {
    
    public var typeOfSignInMethod: ANSignInType {
        currentSignInBy?.typeOfSignInMethod ?? .none
    }
    
    public var currentProfile: ANUserAuth? {
        currentSignInBy?.currentProfile
    }
    
    /// shared singleton object for ANAuthService
    @objc public static var shared: ANAuthService = {
        let instance = ANAuthService()
        instance.getCurrentSignInBy()
        return instance
    }()
    
    /// Keychain for ANAuthService
    private lazy var keychain: Keychain = {
        return Keychain(service: keychainServiceName).synchronizable(true)
    }()
    
    /// keychainServiceName
    private var keychainServiceName: String = ".ANAuthLogin"
    
    /// Array of SingInWrappable types
    lazy private var signInWrappables: [SignInWrappable] = [GoogleSignInWrapper(),FBSignInWrapper(),AppleSignInWrapper()]
    
    /// Array of SingUpWrappable types
    lazy private var signUpWrappables: [SignUpWrappable] = {
        return signInWrappables.compactMap({ $0 as? SignUpWrappable})
        
    }()
    
    /// This property holds the current sign in type object
    private var currentSignInBy: SignInWrappable?
    
    /// This property holds the current sign in type.
    private var currentSignType: ANSignInType?
    
    public func hasPreviousSignIn(handler: @escaping (Bool) -> ()) {
        
        if let signInBy = currentSignInBy {
            signInBy.hasPreviousSignIn(handler: handler)
        }else {
            handler(false)
        }
        
    }
    
    /// Fetch current sign in type from userdefault.
    private func getCurrentSignInBy() {
        
        if let loginBy = UserDefaults.standard.value(forKey: "ANAuthLogin") as? String {
            
            if let currentSignInBy = signInWrappables.filter({ $0.typeOfSignInMethod.signInTypeKey == loginBy}).first {
                self.currentSignInBy = currentSignInBy
                currentSignType = currentSignInBy.typeOfSignInMethod
            }
        }
    }
    
    public func addSignInWrapper(_ wrapper: SignInWrappable) {
        signInWrappables.append(wrapper)
    }
    
    public func addSignUpWrapper(_ wrapper: SignUpWrappable) {
        signUpWrappables.append(wrapper)
    }
    
    public func setUpLoginService(setUpConfig: ANAuthServiceSetupConfig?) throws {
        
        
        /// Setting the keychainServiceName
        if let config = setUpConfig {
            keychainServiceName =  config.keychainServiceName + keychainServiceName
        }
        
        /// Setting up all the services for Login
        for typeObj in signInWrappables {
            try typeObj.setUpLoginService(setUpConfig: setUpConfig)
        }
    }
    
    
    public func signIn(with type: ANSignInType, fromView: UIViewController?, handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        
        if let currentSignInBy = signInWrappables.filter({ $0.typeOfSignInMethod == type}).first {
            self.currentSignInBy = currentSignInBy
            currentSignType = currentSignInBy.typeOfSignInMethod
        }
        
        currentSignInBy?.signIn(with: type, fromView: fromView) { (result) in
            print("result is \(result)")
            
            switch result{
            case .success(_):
                //self?.loginWith(type: loginType, token: successObj, handler: handler)
                UserDefaults.standard.set(type.signInTypeKey, forKey: "ANAuthLogin")
                handler(result)
            case .failure:
                handler(result)
            }
            
        }
        
    }
    
    public func signOut(handler: @escaping (Result<Bool, Error>) -> ()) {
        
        
        currentSignInBy?.signOut(handler: { [weak self] result in
            switch result {
            case .success:
                self?.clearData()
                handler(result)
            case .failure:
                handler(result)
            }
            
        })
    }
    
    public func clearSessionOnExternalError() {
        
        currentSignInBy?.clearSessionOnExternalError()
        clearData()
    }
    
    public func handle(_ app: UIApplication?, open url: URL?, options: [UIApplication.OpenURLOptionsKey : Any]?) -> Bool {
        return currentSignInBy?.handle(app, open: url, options: options) ?? false
    }
    
    
    public func restoreUserSession( completion handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        guard let loginType = currentSignType else {
            handler(.failure(ANSignInError.signInFailed()))
            return
            
        }
        
        currentSignInBy?.restoreUserSession(completion: { (result) in
            print("result is \(result)")
            
            switch result{
            case .success(_):
                UserDefaults.standard.set(loginType.signInTypeKey, forKey: "ANAuthLogin")
                handler(result)
            case .failure:
                handler(result)
            }
            
        })
    }
    
    public func restoreUserSessionExplicit(with type: ANSignInType, completion handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        if let signInBy = signInWrappables.filter({ $0.typeOfSignInMethod == type}).first {
            
            signInBy.restoreUserSessionExplicit(with: type) { [weak self] (result) in
                print("result is \(result)")
                
                switch result{
                case .success(_):
                    self?.currentSignInBy = signInBy
                    self?.currentSignType = signInBy.typeOfSignInMethod
                    UserDefaults.standard.set(type.signInTypeKey, forKey: "ANAuthLogin")
                    
                    handler(result)
                case .failure:
                    handler(result)
                }
            }
            
        }else {
            handler(.failure(ANSignInError.signInTypeUnavailable(type: type)))
        }
        
        
        
    }
    
    private func clearData() {
        UserDefaults.standard.set(nil, forKey: "ANAuthLogin")
        currentSignType = nil
        currentSignInBy = nil
    }
}

@available(iOS 13.0, *)
extension ANAuthService: SignUpWrappable {
    
    public func signUpWith(parameter: [String: Any], handler: @escaping (Result<ANUserAuth,Error>) -> ()) {
        
    }
    
    
}

@available(iOS 13.0, *)
extension ANAuthService {
    
    func loginWith(type: ANSignInType ,token: ANUserAuth, handler: @escaping (Result<ANUserAuth, Error>) -> ()) {
        
        
        // Based on type we can create request to login on our server.
        // Though this can also be routed through a login request protocol that each type can define.
        var signInRequest: URLRequest?
        switch type {
        case .google:
            // google signin request
            break
        case .facebook:
            // facebook sign request
            break
        default:
            break
        }
        
        // For demo
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            
            UserDefaults.standard.set(type.signInTypeKey, forKey: "ANAuthLogin")
            handler(.success(token))
            
        }
        
    }
}
