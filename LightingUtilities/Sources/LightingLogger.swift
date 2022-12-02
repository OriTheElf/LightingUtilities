//
//  LightingLogger.swift
//  
//
//  Created by Choi on 2022/12/2.
//

import Foundation

public enum LightingLogger {
    
    public static var isDebug = true
    
    public static func log(_ items: Any...) {
        if isDebug {
            print(items)
        }
    }
}
