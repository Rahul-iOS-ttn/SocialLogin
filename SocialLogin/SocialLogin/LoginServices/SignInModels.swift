//
//  File.swift
//  SocialLogin
//
//  Created by TTN on 24/06/21.
//

import Foundation


/// User Authentication model
public struct ANAuthUser: ANUserAuth {
    
    static let none = ANAuthUser(authToken: nil, authTokenSecret: nil, passwordCredentials: nil, typeOfSignInMethod: .none)

    public var authToken: String?
    public var authTokenSecret: String?
    public var passwordCredentials: ANPasswordCredential?
    public var anUser: ANUser?
    public var typeOfSignInMethod: ANSignInType
}


/// User detail model
public struct ANUserDetail: ANUser {
    public var profileName: String?
    public var userId: String
    public var isNew: Bool
    public var email: String?
}



/// SignIn Error
public enum ANSignInError: LocalizedError {
    case setupError(type : ANSignInType)
    case signInFailed(Error? = nil)
    case signInTypeUnavailable(type: ANSignInType)
    
    var error: Error? {
        switch self {
        case .setupError( _):
            return nil
        case .signInFailed(let err):
            return err
        case .signInTypeUnavailable:
            return nil
        
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .signInFailed(let error):
            return error?.localizedDescription ?? "Could not sign in, please try again"
        case .setupError(let type):
            switch type{
            case .google:
                return "Google SDK setup failed"
            case .facebook:
                return "Facebook SDK setup failed"
            case .apple:
                return "Apple Sign In setup failed"
            default:
                return "Other SDK setup failed"
            }
        
        case .signInTypeUnavailable(let type):
            switch type {
            case .google:
                return "Google sign in is unavailable."
            case .facebook:
                return "Facebook sign in is unavailable."
            case .apple:
                return "Apple sign in is unavailable."
            default:
                return "Sign in unavailable."
            }
        }
    }
}
