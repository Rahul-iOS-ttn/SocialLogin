//
//  SignInWrappable.swift
//  SocialLogin
//
//  Created by TTN on 24/06/21.
//

import Foundation
import UIKit
//import KeychainAccess


/// Auth service setup config
public struct ANAuthServiceSetupConfig {
    var application : UIApplication?
    var loginOptions : [UIApplication.LaunchOptionsKey: Any]?
    var googleClientId: String?
    var keychainServiceName: String
}

/// ANSignInType has some pre define sign in type whose wrapper are already included. create an extension on the ANSignInType to addd more type to it and add its implented wrapper to ANSignInWrapper class.
public struct ANSignInType {
    
    static let facebook: ANSignInType = ANSignInType(signInTypeKey: "facebookLogin")
    static let google: ANSignInType = ANSignInType(signInTypeKey: "googleLogin")
    static let apple: ANSignInType = ANSignInType(signInTypeKey: "appleLogin")
    static let manual: ANSignInType = ANSignInType(signInTypeKey: "manualLogin")
    static let none: ANSignInType = ANSignInType(signInTypeKey: "none")
    static let twitter: ANSignInType = ANSignInType(signInTypeKey: "twitterLogin")
    
    
    let signInTypeKey : String
    var username: String?
    var password: String?
}

extension ANSignInType: Equatable {
    
    public static func == (lhs: ANSignInType, rhs: ANSignInType) -> Bool {
        if lhs.signInTypeKey == rhs.signInTypeKey {
            return true
        }
        
        return false

    }
}

// Example to how to add other SignInType
public extension ANSignInType {
    static let aws: ANSignInType = ANSignInType(signInTypeKey: "")
}

/// Confirm to ANUserAuth to wrap and expose speicif peoprty to other modules.
public protocol ANUserAuth {
    var authToken: String? { get }
    var authTokenSecret: String? { get }
    var passwordCredentials: ANPasswordCredential? { get }
    var anUser: ANUser? { get }
    var typeOfSignInMethod: ANSignInType { get }
}

/// Confirn to ANPasswordCredential to expose the username and password from a concrete type
public protocol ANPasswordCredential {
    var username: String { get }
    var password: String { get }
}

/// Confirm to ANUser to expose the require property from exixting model
public protocol ANUser {
    var profileName: String? { get }
    var userId: String { get }
    var isNew: Bool { get }
    var email: String? { get }
    
}


/// Confirm to SingInWrappable to make a social login layer a sing in type.
public protocol SignInWrappable {
    
    /// Current profile
    var currentProfile: ANUserAuth? { get }
    
    /// Returns the type of Sign In impented by the self class
    var typeOfSignInMethod: ANSignInType { get }
    
    /// Add a custom Sign in type
    /// - Parameter wrapper: a custom type confirming to SignInWrappable
    func addSignInWrapper(_ wrapper: SignInWrappable)
    
    /// Add a custom Sign up Type
    /// - Parameter wrapper: a custom type confirming to SignUpWrappable
    func addSignUpWrapper(_ wrapper: SignUpWrappable)
    
    /// Check and execute the handler if user has logged in previously using this sign in type
    /// - Parameter handler: handler to execute
    func hasPreviousSignIn(handler: @escaping (Bool) -> ())
    
    /// Set up login types
    /// - Parameter setUpConfig: a config model
    func setUpLoginService(setUpConfig : ANAuthServiceSetupConfig?) throws
    
    /// Handles the open urll
    /// - Parameters:
    ///   - app: Appliaction
    ///   - url: url to handle
    ///   - options: launch options
    func handle(_ app: UIApplication?, open url: URL?, options: [UIApplication.OpenURLOptionsKey : Any]?) -> Bool
    
    /// Sign In call
    /// - Parameters:
    ///   - type: type of sign in
    ///   - fromView: from the view controller
    ///   - handler: handler to execute on sucess/failed sing in.
    func signIn(with type: ANSignInType, fromView: UIViewController? ,handler: @escaping (Result<ANUserAuth,Error>) -> ())
    
    /// Sign out from current sing in type
    /// - Parameter handler: handler to execute on sucess/failed sing out.
    func signOut(handler: @escaping (Result<Bool,Error>) -> ())
    
    /// Call this clear the session if external/System server error out.
    func clearSessionOnExternalError()
    
    /// Restore session from current sign in type
    /// - Parameter handler: handler to execute on success/failed session restore.
    func restoreUserSession(completion handler: @escaping (Result<ANUserAuth,Error>) -> ())
    
    /// Restore session from explicit type
    /// - Parameters:
    ///   - type: SignIn type
    ///   - handler: handler to execute on success/failed session restore.
    func restoreUserSessionExplicit(with type: ANSignInType, completion handler: @escaping (Result<ANUserAuth,Error>) -> ())
    
    
}


/// Confirm to this protocol adding a type to with Sign Up
public protocol SignUpWrappable {
    func signUpWith(parameter: [String: Any], handler: @escaping (Result<ANUserAuth,Error>) -> ())
}

public typealias AuthWrappable = SignInWrappable & SignUpWrappable
