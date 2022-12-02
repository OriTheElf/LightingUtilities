//
//  BLEChannelInput.swift
//  
//
//  Created by Choi on 2022/12/1.
//

import Foundation

public struct BLEChannelInput {
    
    /// 最终二进制数据
    public private(set) var resultData: Data
    
    /// 初始化
    public init?(range: ClosedRange<UInt16>, inputs: [UInt8]) {
        
        let channelRange: ClosedRange<UInt16> = 1...512
        
        guard channelRange ~= range else {
            print("通道编号非法")
            return nil
        }
        guard range.count <= 127 else {
            print("通道数过大")
            return nil
        }
        guard range.count == inputs.count else {
            print("通道数和输入数据量不匹配")
            return nil
        }
        
        /// 开始计算二进制
        let channelStart = range.lowerBound
        let channelCount = UInt16(range.count)

        let channelCountBitwise = channelCount << 9
        let channelStartBitwise = channelStart - 1

        /// 通道数和通道起始值
        let headerOrigin = channelCountBitwise ^ channelStartBitwise
        /// 跨字节转换 | 这里转换时内部自动进行了比特翻转
        let byteFlippedHeaderData = headerOrigin.byteFlippedData
        print("header : \(headerOrigin.data.hexString)")
        print("byte flipped header hex: \(byteFlippedHeaderData.hexString)")
        
        /// 二进制拼接
        resultData = inputs.reduce(byteFlippedHeaderData) { result, new in
            result + new.data
        }
        
        print("最终二进制: \(resultData.hexString)", "bytes: \(resultData)", terminator: "\n\n")
    }
    
    static func <<- (lhs: BLEChannelInput, rhs: BLEChannelInput) -> Data {
        lhs.resultData + rhs.resultData
    }
}
