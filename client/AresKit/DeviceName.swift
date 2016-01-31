//
//  DeviceName.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

func getDeviceName() -> String {
    #if os(iOS)
        return UIDevice.currentDevice().name
    #elseif os(OSX)
        return NSHost.currentHost().localizedName ?? "Computer With No Name"
    #endif
}
