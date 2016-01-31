//
//  Client.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Foundation
import Alamofire
#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

private let UserDefaultsDeviceUUIDKey = "deviceUUID";

public final class Client {
    public static let ErrorDomain = "AresKitClientErrorDomain"
    public static let APIErrorKey = "api_error"
    public enum ErrorCode: Int {
        case APIError
        case InvalidJSONResponse
    }
    
    private let manager: Manager
    private let URL: NSURL
    
    public init(URL: NSURL, configuration: NSURLSessionConfiguration = .defaultSessionConfiguration()) {
        self.URL = URL
        self.manager = Manager(configuration: configuration)
    }
    
    // MARK: API
    
    public func register(user: User, completionHandler: Result<CreatedUser, NSError> -> Void) {
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
    
    public func authenticate(user: User, completionHandler: Result<AccessToken, NSError> -> Void) {
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
    
    public func registerDevice(accessToken: AccessToken, pushToken: String? = nil, completionHandler: Result<RegisteredDevice, NSError> -> Void) {
        var parameters = [
            "uuid": deviceUUID,
            "device_name": deviceName,
            "token": accessToken.token
        ]
        if let pushToken = pushToken {
            parameters["push_token"] = pushToken
        }
        let request = Request(
            method: .POST,
            path: "/register_device",
            parameters: parameters
        )
        requestModel(request, completionHandler: completionHandler)
    }
    
    public func getDevices(accessToken: AccessToken, completionHandler: Result<[RegisteredDevice], NSError> -> Void) {
        let request = Request(method: .GET, path: "/devices", parameters: [
            "token": accessToken.token
        ])
        requestModelArray(request, completionHandler: completionHandler)
    }
    
    public func send(accessToken: AccessToken, filePath: String, device: RegisteredDevice, completionHandler: Result<Void, NSError> -> Void) {
        let request = Request(method: .POST, path: "/send", parameters: [
            "token": accessToken.token,
            "file_path": filePath,
            "device_id": device.uuid
        ])
        print(request.parameters)
        requestVoid(request, completionHandler: completionHandler)
    }
    
    public var deviceUUID: String {
        let ud = NSUserDefaults.standardUserDefaults()
        let UUID: String
        if let storedUUID = ud.stringForKey(UserDefaultsDeviceUUIDKey) {
            UUID = storedUUID
        } else {
            UUID = NSUUID().UUIDString
            ud.setObject(UUID, forKey: UserDefaultsDeviceUUIDKey)
        }
        return UUID
    }
    
    private var deviceName: String {
        #if os(iOS)
            return UIDevice.currentDevice().name
        #elseif os(OSX)
            return NSHost.currentHost().localizedName ?? "Computer With No Name"
        #endif
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
                if let json = json as? JSONDictionary, model = T(JSON: json) {
                    completionHandler(.Success(model))
                } else {
                    completionHandler(.Failure(self.dynamicType.InvalidJSONResponseError))
                }
            case let .Failure(error):
                completionHandler(.Failure(error))
            }
        }
    }
    
    private func requestModelArray<T: JSONDeserializable>(request: Request, completionHandler: Result<[T], NSError> -> Void) {
        requestJSON(request) { result in
            switch result {
            case let .Success(json):
                if let jsonArray = json as? [JSONDictionary] {
                    var models = [T]()
                    for deviceDict in jsonArray {
                        if let model = T(JSON: deviceDict) {
                            models.append(model)
                        } else {
                            completionHandler(.Failure(self.dynamicType.InvalidJSONResponseError))
                            return
                        }
                    }
                    completionHandler(.Success(models))
                } else {
                    completionHandler(.Failure(self.dynamicType.InvalidJSONResponseError))
                }
            case let .Failure(error):
                completionHandler(.Failure(error))
            }
        }
    }
    
    private func requestJSON(request: Request, completionHandler: Result<AnyObject, NSError> -> Void) {
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else {
            fatalError("Invalid API base URL: \(URL)")
        }
        components.path = request.path
        guard let requestURL = components.URL else {
            fatalError("Unable to construct request URL")
        }
        manager.request(request.method, requestURL, parameters: request.parameters, encoding: .URL)
            .responseJSON { response in
                switch response.result {
                case let .Success(responseObject):
                    if let json = responseObject as? JSONDictionary {
                        print(json)
                        if let success = json["success"] as? Bool,
                               result = json["result"] where success {
                            completionHandler(.Success(result))
                        } else {
                            let error = self.dynamicType.constructAPIErrorFromJSON(json)
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
    
    private func requestVoid(request: Request, completionHandler: Result<Void, NSError> -> Void) {
        requestJSON(request) { result in
            switch result {
            case .Success:
                completionHandler(.Success(()))
            case let .Failure(error):
                completionHandler(.Failure(error))
            }
        }
    }
    
    private static func constructAPIErrorFromJSON(json: JSONDictionary) -> NSError {
        var userInfo = [String: AnyObject]()
        if let error = json["error"] as? String {
            userInfo[APIErrorKey] = error
            if let description = localizedDescriptionForAPIError(error) {
                userInfo[NSLocalizedDescriptionKey] = description
            }
        }
        return NSError(domain: ErrorDomain, code: ErrorCode.APIError.rawValue, userInfo: userInfo)
    }
}

private func localizedDescriptionForAPIError(error: String) -> String? {
    switch error {
    case "USER_EXISTS":
        return "A user with the specified username already exists.";
    case "USER_DOES_NOT_EXIST":
        return "A user with the specified username does not exist.";
    case "PASSWORD_INCORRECT":
        return "The specified password is incorrect.";
    case "INVALID_TOKEN":
        return "The specified access token is invalid.";
    default: return nil
    }
}
