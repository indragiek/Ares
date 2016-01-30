//
//  JSONDeserializable.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

public typealias JSONDictionary = [String: AnyObject]

public protocol JSONDeserializable {
    init?(JSON: JSONDictionary)
}
