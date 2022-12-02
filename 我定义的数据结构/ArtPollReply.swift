//
//  ArtPollReply.swift
//  TimoTwo
//
//  Created by Choi on 2022/11/25.
//

import Foundation

public struct ArtPollReply {
    
    struct Status1: CustomStringConvertible {
        
        enum FrontPanelIndicatorControl: Int, CustomStringConvertible {
            case unknown = 0b00
            case locate  = 0b01
            case mute    = 0b10
            case normal  = 0b11
            
            var description: String {
                switch self {
                case .unknown: return "unknown"
                case .locate: return "locate"
                case .mute: return "mute"
                case .normal: return "normal"
                }
            }
        }
        
        enum PortAddressProgrammingAuthority: Int, CustomStringConvertible {
            case unknown         = 0b00
            case setByFrontPanel = 0b01
            case setByNetwork    = 0b10
            case illegal         = 0b11
            
            var description: String {
                switch self {
                case .unknown: return "unknown"
                case .setByFrontPanel: return "setByFrontPanel"
                case .setByNetwork: return "setByNetwork"
                case .illegal: return "illegal"
                }
            }
        }
        
        enum BootMode: Int, CustomStringConvertible {
            case normal = 0
            case factoryStart = 1
            
            var description: String {
                switch self {
                case .normal: return "normal"
                case .factoryStart: return "factoryStart"
                }
            }
        }
        
        let frontPanelIndicatorControl: FrontPanelIndicatorControl
        let portAddressProgrammingAuthority: PortAddressProgrammingAuthority
        let bootMode: BootMode
        let isRDMCapable: Bool /// 是否可以RDM
        let isUBEASupported: Bool
        init(_ byte: UInt8) {
            frontPanelIndicatorControl = FrontPanelIndicatorControl(rawValue: byte[6...7]).unsafelyUnwrapped
            portAddressProgrammingAuthority = PortAddressProgrammingAuthority(rawValue: byte[4...5]).unsafelyUnwrapped
            bootMode = BootMode(rawValue: byte[2]).unsafelyUnwrapped
            isRDMCapable = byte[1] == 1
            isUBEASupported = byte[0] == 1
        }
        
        var description: String {
            [
                frontPanelIndicatorControl.description,
                portAddressProgrammingAuthority.description,
                bootMode.description,
                isRDMCapable.description,
                isUBEASupported.description
            ]
                .joined(separator: "\n")
        }
    }
    struct Status2 {
        enum PortAddressStyle: Int {
            case legacy = 0
            case modern
        }
        let portAddressStyle: PortAddressStyle
        let isDHCPCapable: Bool
        let isIpDHCPConfigured: Bool
        let isDeviceConfigurableByWebBrowser: Bool
        init(_ byte: UInt8) {
            portAddressStyle = .init(rawValue: byte[3]).unsafelyUnwrapped
            isDHCPCapable = byte[2] == 1
            isIpDHCPConfigured = byte[1] == 1
            isDeviceConfigurableByWebBrowser = byte[0] == 1
        }
    }
    struct Port {
        enum PortType: Int, CustomStringConvertible {
            case dmx512       = 0b00_0000
            case midi         = 0b00_0001
            case aVab         = 0b00_0010
            case colortranCMX = 0b00_0011
            case adb625       = 0b00_0100
            case artNet       = 0b00_0101
            
            var description: String {
                switch self {
                case .dmx512: return "dmx512"
                case .midi: return "midi"
                case .aVab: return "aVab"
                case .colortranCMX: return "colortranCMX"
                case .adb625: return "adb625"
                case .artNet: return "artNet"
                }
            }
        }
        let isOutputImplemented: Bool
        let isInputImplemented: Bool
        let type: PortType
        
        init?(_ byte: UInt8) {
            isOutputImplemented = byte[7] == 1
            isInputImplemented = byte[6] == 1
            guard let portType = PortType(rawValue: byte[0...5]) else { return nil }
            type = portType
        }
    }
    struct GoodInput {
        let isDataReceived: Bool
        let isTestPacketsReceived: Bool
        let isSIPPacketsReceived: Bool
        let isTextPacketsReceived: Bool
        let isInputEnabled: Bool
        let isErrorReceived: Bool
        
        init(_ byte: UInt8) {
            isDataReceived        = byte[7] == 1
            isTestPacketsReceived = byte[6] == 1
            isSIPPacketsReceived  = byte[5] == 1
            isTextPacketsReceived = byte[4] == 1
            isInputEnabled        = byte[3] == 1
            isErrorReceived       = byte[2] == 1
        }
    }
    struct GoodOutput {
        enum MergeMode: Int {
            case htp
            case ltp
        }
        
        let isDataTransmitted: Bool
        let isTestPacketsTransmitted: Bool
        let isSIPPacketsTransmitted: Bool
        let isTextPacketsTransmitted: Bool
        let isMerging: Bool
        let isShortCircuitDetected: Bool
        let mergeMode: MergeMode
        
        init?(_ byte: UInt8) {
            isDataTransmitted        = byte[7] == 1
            isTestPacketsTransmitted = byte[6] == 1
            isSIPPacketsTransmitted  = byte[5] == 1
            isTextPacketsTransmitted = byte[4] == 1
            isMerging                = byte[3] == 1
            isShortCircuitDetected   = byte[2] == 1
            guard let mode = MergeMode(rawValue: byte[1]) else { return nil }
            mergeMode = mode
        }
    }
    
    let id: String
    let opCode: Int
    let ipAddress: String
    let portNumber: Int
    let versInfo: Int
    let netSwitch: Int
    let subSwitch: Int
    let oem: Int
    let ubeaVersion: Int
    let status1: Status1
    let estaMan: Int
    let shortName: String
    let longName: String
    let nodeReport: String
    let numPorts: Int /// the maximum number of Input-Ports or Output-Ports implemented by the device.
    let portTypes: [Port]
    let goodInput: [GoodInput]
    let goodOutput: [GoodOutput]
    let swIns: Data
    let swOuts: Data
    
    let mac: String
    let bindIp: String
    let bindIndex: Int
    let status2: Status2
    let filler: String
    
    public init?(_ binary: Data) {
        guard binary.count <= 239 else { return nil }
        let opcodeRange = 8...9
        guard opcodeRange.upperBound < binary.count else { return nil }
        guard binary[opcodeRange].reversed.intValue == 0x2100 else { return nil }
        let clips = [
            0...7,
            opcodeRange,
            10...13,
            14...15,
            16...17,
            18...18,
            19...19,
            20...21,
            22...22,
            23...23,
            24...25,
            26...43,
            44...107,
            108...171,
            172...173,
            174...177,
            178...181,
            182...185,
            186...189,
            190...193,
            194...194,
            195...195,
            196...196,
            197...197,
            198...198,
            199...199,
            200...200,
            201...206,
            207...210,
            211...211,
            212...212,
            213...max(213, binary.endIndex - 1)
        ].map { section in
            binary[section]
        }
        
        id          = clips[0].asciiString
        opCode      = clips[1].reversed.intValue
        ipAddress   = clips[2].ipAddress
        portNumber  = clips[3].reversed.intValue
        versInfo    = clips[4].intValue
        netSwitch   = clips[5].intValue
        subSwitch   = clips[6].intValue
        oem         = clips[7].intValue
        ubeaVersion = clips[8].intValue
        status1     = Status1(clips[9].intValue.uInt8)
        estaMan     = clips[10].reversed.intValue
        shortName   = clips[11].asciiString
        longName    = clips[12].asciiString
        nodeReport  = clips[13].asciiString
        numPorts    = clips[14].intValue
        portTypes   = clips[15].compactMap(Port.init)
        goodInput   = clips[16].compactMap(GoodInput.init)
        goodOutput  = clips[17].compactMap(GoodOutput.init)
        swIns       = clips[18]
        swOuts      = clips[19]
        _           = clips[20].asciiString
        _           = clips[21].asciiString
        _           = clips[22].asciiString
        _           = clips[23].asciiString
        _           = clips[24].asciiString
        _           = clips[25].asciiString
        _           = clips[26].asciiString
        mac         = clips[27].map(\.byteHexString).joined(separator: ":")
        bindIp      = clips[28].ipAddress
        bindIndex   = clips[29].intValue
        status2     = Status2(clips[30].intValue.uInt8)
        filler      = clips[31].asciiString
    }
    
    var outputPorts: [UInt16] {
        let netSwitch = netSwitch.uInt16 << 8
        let subSwitch = subSwitch.uInt16 << 4
        return swOuts.map(\.uInt16).map { swOut in
            netSwitch ^ subSwitch ^ swOut
        }
    }
    
    var inputPorts: [UInt16] {
        let netSwitch = netSwitch.uInt16 << 8
        let subSwitch = subSwitch.uInt16 << 4
        return swIns.map(\.uInt16).map { swIn in
            netSwitch ^ subSwitch ^ swIn
        }
    }
}
