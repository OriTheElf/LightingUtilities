//
//  FoundationExtensions.swift
//  
//
//  Created by Choi on 2022/12/1.
//

import Foundation

let artNetProtocolVersion: UInt16 = 14

infix operator <<- : MultiplicationPrecedence

extension Array where Element: Equatable {
    
    @discardableResult
    /// 替换指定元素
    /// - Parameter newElement: 新元素
    /// - Returns: 是否替换成功
    public mutating func replace(
        with newElement: Element,
        if prediction: (_ old: Element, _ new: Element) -> Bool = { $0 == $1 }
    ) -> Bool {
        let index = firstIndex { oldElement in
            prediction(oldElement, newElement)
        }
        if let index {
            let range = index..<index + 1
            let updated = [newElement]
            replaceSubrange(range, with: updated)
            return true
        } else {
            append(newElement)
            return false
        }
    }
    
    @discardableResult
    /// 移除指定元素
    /// - Parameter element: 要移除的元素
    /// - Returns: 更新后的数组
    public mutating func remove(_ element: Element) -> Array {
        if let foundIndex = firstIndex(of: element) {
            remove(at: foundIndex)
        }
        return self
    }
}

extension Array where Element : Hashable {
    
    public mutating func appendUnique<S>(contentsOf newElements: S) where Element == S.Element, S : Sequence {
        newElements.forEach { element in
            appendUnique(element)
        }
    }
    
    /// 添加唯一的元素
    /// - Parameter newElement: 遵循Hashable的元素
    public mutating func appendUnique(_ newElement: Element) {
        let isNotUnique = contains { element in
            element.hashValue == newElement.hashValue
        }
        guard !isNotUnique else { return }
        append(newElement)
    }
}

extension UInt8 {
    var binaryString: String {
        let binary = String(self, radix: 2)
        return repeatElement("0", count: 8 - binary.count) + binary
    }
}

extension Data {
    
    var reversed: Data {
        var temp = self
        temp.reverse()
        return temp
    }
    
    private func hex(_ byte: Element) -> String {
        /// %02hhx: Lower cased
        String(format: "%02hhX", byte)
    }
    
    public var binaryString: String {
        map(\.binaryString).joined()
    }
    
    /// 2进制转16进制字符串
    public var hexString: String {
        map(hex).joined()
    }
    
    public var intValue: Int {
        hexString.intFromHex ?? 0
    }
}


extension Data {
    
    var ipAddress: String {
        guard count == 4 else { return "" }
        return map(String.init).joined(separator: ".")
    }
    
    var asciiString: String {
        let characters = compactMap { element -> Character? in
            guard element > 0 else { return nil }
            let unicodeScalar = UnicodeScalar(element)
            return Character(unicodeScalar)
        }
        return String(characters)
    }
    
    static func artNzs(sequence: UInt8, for net: UInt8, subUni: UInt8, data: Data) -> Data {
        /// 参考: https://art-net.org.uk/how-it-works/streaming-packets/artnzs-packet-definition/
        let opCode: UInt16 = 0x5200
        let dataLenth = data.count.uInt16
        
        /// The Length field can be set to any even value in the range 2 – 512.
        guard dataLenth.isMultiple(of: 2) else {
            assertionFailure("数据长度必须为偶数")
            return Data()
        }
        let lengthHi = dataLenth >> 8
        let lengthLo = dataLenth & 0xFF
        let dataBuilder = [
            data,
            lengthLo.uInt8.data,
            lengthHi.uInt8.data,
            net.data,
            subUni.data,
            sequence.data,
            artNetProtocolVersion.byteFlippedData,
            opCode.data,
            artNet
        ]
        return dataBuilder.reduce(Data(), +)
    }
    
    var artSync: Data {
        let opCode: UInt16 = 0x5200
        let aux: UInt16 = 0x0
        
        let data = [
            aux.data,
            artNetProtocolVersion.byteFlippedData,
            opCode.data,
            Data.artNet
        ]
        return data.reduce(Data(), +)
    }
    
    var artPollData: Data {
        
        /// 参考: https://art-net.org.uk/how-it-works/discovery-packets/artpoll/
        let opCode: UInt16 = 0x2000
        let flags: UInt8 = 0x06
        let priority: UInt8 = 0x00
        
        let data = [
            priority.data,
            flags.data,
            artNetProtocolVersion.byteFlippedData,
            opCode.data,
            Data.artNet
        ]
        return data.reduce(Data(), +)
    }
    
    static let artNet: Data = {
        let artNet = "Art-Net"
        let asciiValues = artNet.compactMap(\.asciiValue) + [0]
        let asciiData = asciiValues.reversed()
            .map(\.data)
            .reduce(Data(), +)
        return asciiData
    }()
}

extension BinaryInteger {
    
    var int: Int {
        Int(truncatingIfNeeded: self)
    }
    
    var int64: Int64 {
        Int64(truncatingIfNeeded: self)
    }
    
    var int32: Int32 {
        Int32(truncatingIfNeeded: self)
    }
    
    var int16: Int16 {
        Int16(truncatingIfNeeded: self)
    }
    
    var int8: Int8 {
        Int8(truncatingIfNeeded: self)
    }
    
    var uInt64: UInt64 {
        UInt64(truncatingIfNeeded: self)
    }
    
    var uInt32: UInt32 {
        UInt32(truncatingIfNeeded: self)
    }
    
    public var uInt16: UInt16 {
        UInt16(truncatingIfNeeded: self)
    }
    
    public var uInt8: UInt8 {
        UInt8(truncatingIfNeeded: self)
    }
    
    /// 二进制
    public var data: Data {
        dataInBytes(byteSize)
    }
    
    /// 字节翻转过的二进制
    public var byteFlippedData: Data {
        byteFlippedDataInBytes(byteSize)
    }
    
    /// 整型 -> 二进制
    /// - Parameter byteCount: 放入几个字节中
    /// - Returns: 二进制对象
    func dataInBytes(_ byteCount: Int? = nil) -> Data {
        let sequence = byteFlippedDataInBytes(byteCount).reversed()
        return Data(sequence)
    }
    
    /// 整型 -> 二进制(字节翻转过的)
    /// - Parameter byteCount: 放入几个字节中
    /// - Returns: 字节翻转后的二进制对象
    func byteFlippedDataInBytes(_ byteCount: Int? = nil) -> Data {
        var myInt = self
        let count = byteCount ?? MemoryLayout.size(ofValue: myInt)
        return Data(bytes: &myInt, count: count)
    }
    
    /// 占用的二进制位数
    var bitSize: Int {
        byteSize * 8
    }
    
    /// 占用的二进制字节数
    var byteSize: Int {
        MemoryLayout.size(ofValue: self)
    }
    
    var byteHexString: String {
        hexString(2)
    }
    
    func hexString(_ minLength: Int = 2) -> String {
        String(format: "%0\(minLength)X", self.int)
    }
    
    var hexString: String {
        stringOfRadix(16, uppercase: true)
    }
    
    /// 数字转换为指定进制字符串
    /// - Parameters:
    ///   - radix: 进制: 取值范围: 2...36
    ///   - uppercase: 字母是否大写
    /// - Returns: 转换成功后的字符串
    func stringOfRadix(_ radix: Int, uppercase: Bool = true) -> String {
        guard (2...36) ~= radix else {
            assertionFailure("NO SUCH RADIX 🤯")
            return ""
        }
        return String(self, radix: radix, uppercase: uppercase)
    }
    
    /// 根据二进制位置取值
    subscript (_ position: Int) -> Int {
        self[position...position]
    }

    /// 根据二进制范围取值
    subscript (_ range: ClosedRange<Int>) -> Int {
        guard range.upperBound < bitSize else {
            assertionFailure("OUT OF RANGE!")
            return 0
        }
        var mask: Int {
            var flag = 0
            range.forEach { position in
                flag = (flag << 1) + 1
            }
            return flag << (range.upperBound - range.count + 1)
        }
        let intSelf = Int(self)
        return (intSelf & mask) >> range.lowerBound
    }
}

extension String {
    
    var asciiData: Data {
        reduce(Data()) { result, char in
            guard let data = char.asciiValue?.data else {
                return result
            }
            return result + data
        }
    }
}

extension StringProtocol {
    
    var intValueFromHex: Int {
        intFromHex ?? 0
    }
    
    /// 将字符串按照十六进制转换成十进制
    public var intFromHex: Int? {
        intFromRadix(16)
    }
    
    /// 将字符串按照指定的进制转换成十进制
    /// FF -> 255
    /// 0000FF -> 255
    /// - Parameter radix: 进制: 取值范围: 2...36
    /// - Returns: 转换成功返回十进制数字
    func intFromRadix(_ radix: Int) -> Int? {
        guard (2...36) ~= radix else {
            assertionFailure("NO SUCH RADIX 🤯")
            return nil
        }
        return Int(self, radix: radix)
    }
    
    typealias Byte = UInt8
    
    var hexToBinary: Data {
        var start = startIndex
        /// 两个16进制位为1个字节
        let byteArray = stride(from: 0, to: count, by: 2)
            .compactMap { _ in
                let end = index(after: start)
                defer {
                    start = index(after: end)
                }
                return Byte(self[start...end], radix: 16)
            }
        return Data(byteArray)
    }
}

extension Range {
    
    /// 判断左面的范围是否包含右面
    /// - Returns: 包含则返回true, 否则返回false
    static func ~=(lhs: Self, rhs: Self) -> Bool {
        /// clamped -> Always return a smaller range
        rhs.clamped(to: lhs) == rhs
    }
}

extension ClosedRange {
    
    /// 判断左面的范围是否包含右面
    /// - Returns: 包含则返回true, 否则返回false
    static func ~=(lhs: Self, rhs: Self) -> Bool {
        /// clamped -> Always return a smaller range
        rhs.clamped(to: lhs) == rhs
    }
}
