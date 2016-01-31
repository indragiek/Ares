//
//  FileTransferContext.swift
//  Ares
//
//  Created by Indragie on 1/31/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Foundation

private let ArchivedFilePathKey = "filePath";

public struct FileTransferContext {
    public let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
    }
    
    init?(data: NSData) {
        if let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: AnyObject],
               filePath = dict[ArchivedFilePathKey] as? String {
            self.filePath = filePath
        } else {
            return nil
        }
    }
    
    func archive() -> NSData {
        let dict: NSDictionary = [ArchivedFilePathKey: filePath]
        return NSKeyedArchiver.archivedDataWithRootObject(dict)
    }
}
