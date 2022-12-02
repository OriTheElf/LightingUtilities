//
//  ArtDmx.swift
//  TimoTwo
//
//  Created by Choi on 2022/11/28.
//

import Foundation

public struct ArtDmx {
    let id: String
    let opCode: Int
    let protVer: Int
    /// 跟踪数据包发送的序列
    let sequence: Int
    /// 发送数据包的物理接口(0-3)
    let physical: Int
    let portAddress: Int
    let length: Int
    let data: Data
    
    public init?(_ binary: Data) {
        let opcodeRange = 8...9
        guard opcodeRange.upperBound < binary.count else { return nil }
        guard binary[opcodeRange].reversed.intValue == 0x5000 else { return nil }
        let clips = [
            0...7,
            opcodeRange,
            10...11,
            12...12,
            13...13,
            14...15,
            16...17,
            18...max(18, binary.endIndex - 1)
        ].map { section in
            binary[section]
        }
        
        id          = clips[0].asciiString
        opCode      = clips[1].reversed.intValue
        protVer     = clips[2].intValue
        sequence    = clips[3].intValue
        physical    = clips[4].intValue
        portAddress = clips[5].reversed.intValue
        length      = clips[6].intValue
        data        = clips[7]
    }
}
