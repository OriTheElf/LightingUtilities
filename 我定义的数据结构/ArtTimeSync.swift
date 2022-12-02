//
//  ArtTimeSync.swift
//  TimoTwo
//
//  Created by Choi on 2022/11/30.
//

import Foundation

struct ArtTimeSync: CustomStringConvertible {
    static let opCode: UInt16 = 0x9800
    let id: Data
    let opCode: UInt16
    let protVer: Int
    let filler: UInt16
    let prog: UInt8
    let sec: UInt8
    let min: UInt8
    let hour: UInt8
    let mDay: UInt8
    let mon: UInt8
    let year: UInt16
    let wDay: UInt8
    let isDST: UInt8
    
    init?(date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents(in: .current, from: date)
        guard let seconds = dateComponents.second else { return nil }
        guard let minute = dateComponents.minute else { return nil }
        guard let hour = dateComponents.hour else { return nil }
        guard let mDay = dateComponents.day else { return nil }
        guard let month = dateComponents.month else { return nil }
        guard let year = dateComponents.year else { return nil }
        guard let weekday = dateComponents.weekday, 1...7 ~= weekday else { return nil }
        
        self.init(
            seconds: seconds.uInt8,
            minutes: minute.uInt8,
            hours: hour.uInt8,
            mDay: mDay.uInt8,
            month: month.uInt8,
            year: (year - 1900).uInt16,
            wDay: (weekday - 1).uInt8,
            isDST: false)
    }
    
    init?(_ binary: Data) {
        let opcodeRange = 8...9
        guard opcodeRange.upperBound < binary.count else { return nil }
        let reversedBinary = binary.reversed
        guard reversedBinary[opcodeRange].reversed.intValue == Self.opCode else { return nil }
        let clips = [
            0...7,
            opcodeRange,
            10...11,
            12...13,
            14...14,
            15...15,
            16...16,
            17...17,
            18...18,
            19...19,
            20...21,
            22...22,
            23...23
        ].map { section in
            reversedBinary[section]
        }
        id      = clips[0].reversed
        opCode  = clips[1].reversed.intValue.uInt16
        protVer = clips[2].intValue
        filler  = clips[3].intValue.uInt16
        prog    = clips[4].intValue.uInt8
        sec     = clips[5].intValue.uInt8
        min     = clips[6].intValue.uInt8
        hour    = clips[7].intValue.uInt8
        mDay    = clips[8].intValue.uInt8
        mon     = clips[9].intValue.uInt8
        year    = clips[10].intValue.uInt16
        wDay    = clips[11].intValue.uInt8
        isDST   = clips[12].intValue.uInt8
    }
    
    /// 初始化方法
    /// - Parameters:
    ///   - isResponse: 是否是响应数据
    ///   - wDay: 星期
    ///   - isDST: 是否是夏令时
    init(isResponse: Bool = false, seconds: UInt8, minutes: UInt8, hours: UInt8, mDay: UInt8, month: UInt8, year: UInt16, wDay: UInt8, isDST: Bool = false) {
        
        self.id = .artNet
        self.opCode = Self.opCode
        self.protVer = 14
        self.filler = 0
        self.prog = isResponse ? 0 : 1
        self.sec = seconds
        self.min = minutes
        self.hour = hours
        self.mDay = mDay
        self.mon = month
        self.year = year
        self.wDay = wDay
        self.isDST = isDST ? 1 : 0
    }
    
    var data: Data {
        let dataBuilder = [
            isDST.data,
            wDay.data,
            year.byteFlippedData,
            mon.data,
            mDay.data,
            hour.data,
            min.data,
            sec.data,
            prog.data,
            filler.data,
            artNetProtocolVersion.byteFlippedData,
            opCode.data,
            id
        ]
        return dataBuilder.reduce(Data(), +)
    }
    
    var description: String {
        [
            id.asciiString,
            String(opCode),
            String(protVer),
            String(filler),
            String(prog),
            String(sec),
            String(min),
            String(hour),
            String(mDay),
            String(mon),
            String(year),
            String(wDay),
            String(isDST)
        ]
            .joined(separator: "\n\n")
    }
}
