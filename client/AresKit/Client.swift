//
//  Client.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Foundation
import Alamofire

public final class Client {
    public static let ErrorDomain = "AresKitClientErrorDomain"
    public static let APIErrorKey = "api_error"
    public enum ErrorCode: Int {
        case APIError
        case InvalidJSONResponse
    }
    
    private let manager: Manager
    private let URL: NSURL
    
    init(URL: NSURL, configuration: NSURLSessionConfiguration = .defaultSessionConfiguration()) {
        self.URL = URL
        self.manager = Manager(configuration: configuration)
    }
    
    // MARK: API
    
    func register(user: User, completionHandler: Result<User, NSError> -> Void) {
        let request = Request(
            method: .POST,
            path: "/register",
            parameters: [
                "username": user.username,
                "password": user.password
            ]
        )
        requestModel(request, completionHandler: completionHandler)
    }
    
    func authenticate(user: User, completionHandler: Result<AccessToken, NSError> -> Void) {
        let request = Request(
            method: .POST,
            path: "/authenticate",
            parameters: [
                "username": user.username,
                "password": user.password
            ]
        )
        requestModel(request, completionHandler: completionHandler)
    }
    
    // MARK: Primitives
    
    private struct Request {
        let method: Alamofire.Method
        let path: String
        let parameters: [String: AnyObject]
    }
    
    private static let InvalidJSONResponseError = NSError(domain: ErrorDomain, code: ErrorCode.InvalidJSONResponse.rawValue, userInfo: nil)
    
    private func requestModel<T: JSONDeserializable>(request: Request, completionHandler: Result<T, NSError> -> Void) {
        requestJSON(request) { result in
            switch result {
            case let .Success(json):
                if let model = T(JSON: json) {
                    completionHandler(.Success(model))
                } else {
                    completionHandler(.Failure(self.dynamicType.InvalidJSONResponseError))
                }
            case let .Failure(error):
                completionHandler(.Failure(error))
            }
        }
    }
    
    private func requestJSON(request: Request, completionHandler: Result<JSONDictionary, NSError> -> Void) {
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            fatalError("Invalid API base URL: \(URL)")
        }
        components.path = request.path
        guard let requestURL = components.URL else {
            fatalError("Unable to construct request URL")
        }
        manager.request(request.method, requestURL, parameters: request.parameters, encoding: .URL)
            .validate()
            .responseJSON { response in
                switch response.result {
                case let .Success(responseObject):
                    if let json = responseObject as? JSONDictionary {
                        if let success = json["success"] as? Bool,
                               result = json["result"] as? JSONDictionary where success {
                            completionHandler(.Success(result))
                        } else {
                            var userInfo = [String: AnyObject]()
                            if let error = json["error"] as? String {
                                userInfo[self.dynamicType.APIErrorKey] = error
                            }
                            let error = NSError(domain: self.dynamicType.ErrorDomain, code: ErrorCode.APIError.rawValue, userInfo: userInfo)
                            completionHandler(.Failure(error))
                        }
                    } else {
                        completionHandler(.Failure(self.dynamicType.InvalidJSONResponseError))
                    }
                case let .Failure(error):
                    completionHandler(.Failure(error))
                }
            }
    }
}
