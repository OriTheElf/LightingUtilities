//
//  TimoTwoSDK.swift
//  TimoTwo
//
//  Created by Choi on 2022/11/16.
//

import Foundation
import CoreBluetooth

extension String: Error {
    
}

public enum TimoError: LocalizedError {
    case unknown
}

public struct TimoPeripheral: Equatable {
    public let core: CBPeripheral
    private let serviceUUIDs: [CBUUID]
    private let manufacturerData: Data
    
    init?(_ dict: [String: Any], core: CBPeripheral) {
        self.core = core
        
        guard let uuids = dict["kCBAdvDataServiceUUIDs"] as? [CBUUID] else { return nil }
        self.serviceUUIDs = uuids
        
        guard let data = dict["kCBAdvDataManufacturerData"] as? Data else { return nil }
        self.manufacturerData = data
    }
    
    public var name: String? {
        core.name
    }
    
    var identifier: UUID {
        core.identifier
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

public typealias PeripheralScanningCallback = (TimoPeripheral) -> Void
public typealias TimoResultCallback<T> = (Result<T, Error>) -> Void
public typealias TimoConnectionResultCallback = TimoResultCallback<CBPeripheral>
public typealias TimoDisconnectionResultCallback = TimoResultCallback<CBPeripheral>
public typealias TimoNormalResultCallback = TimoResultCallback<Bool>

public final class TimoTwo: NSObject {
    
    /// 单例
    fileprivate static let shared = TimoTwo()
    
    /// 中心设备管理器
    fileprivate var centralManager: CBCentralManager!
    
    /// 当前蓝牙状态
    fileprivate var currentState: CBManagerState! {
        didSet {
            guard currentState == .poweredOn else { return }
            searchPeripherals()
        }
    }
    
    /// 扫描蓝牙回调
    fileprivate var scanningPeripheral: PeripheralScanningCallback = { _ in }
    fileprivate var connectionResult: TimoConnectionResultCallback = { _ in }
    fileprivate var disconnectionResult: TimoDisconnectionResultCallback = { _ in }
    fileprivate var sendDataResult: TimoNormalResultCallback = { _ in }
    
    /// 找到的设备
    fileprivate var foundPeripherals: [TimoPeripheral] = []
    
    fileprivate var dmxChannelCharacteristic: CBCharacteristic?
    
    /// UUIDs
    fileprivate let dmxDataServiceUUID = CBUUID(string: "bfa00000-247d-6e1c-448c-223dfa0bd00c")
    fileprivate let dmxChannelCharacteristicUUID = CBUUID(string: "bfa00001-247d-6e1c-448c-223dfa0bd00c")
    /// 单例模式
    private override init() {
        super.init()
        
        let options: [String: Any] = [CBCentralManagerOptionShowPowerAlertKey: true]
        
        centralManager = CBCentralManager(
            delegate: self,
//            queue: .global(qos: .background),
            queue: .main,
            options: options)
    }
    
    public static func sendChannelInputs(_ inputs: BLEChannelInput..., to peripheral: TimoPeripheral, callback: @escaping TimoNormalResultCallback) {
        sendChannelInputs(inputs, to: peripheral, callback: callback)
    }
    
    public static func sendChannelInputs(_ inputs: [BLEChannelInput], to peripheral: TimoPeripheral, callback: @escaping TimoNormalResultCallback) {
        
        shared.sendDataResult = { result in
            callback(result)
        }
        
        guard let dmxChannelCharacteristic = shared.dmxChannelCharacteristic else {
            callback(.failure("DID NOT FOUND CHARACTERISTIC"))
            return
        }
        
        let datas = inputs.map(\.resultData)
        let mtu = 247 // Bytes
        var temp: Data?
        for (index, data) in datas.enumerated() {
            
            /// 如果超过MTU则跳过
            guard data.count <= mtu else {
                print("DATA TO LARGE")
                continue
            }
            
            print(data.hexString, "\(data.count) bytes")
            
            /// 是最后一个元素
            let isLast = index == datas.endIndex - 1
            
            if let unwrapTemp = temp {
                
                /// 累加
                let add = unwrapTemp + data
                
                
                /// 确保累加二进制不超过MTU
                guard add.count <= mtu else {
                    
                    print("发送上次累加值\(unwrapTemp.count) 字节: \(unwrapTemp.hexString) \n\n")
                    peripheral.core.writeValue(unwrapTemp, for: dmxChannelCharacteristic, type: .withResponse)
                    /// 将临时二进制复制为当前变量 | 继续执行循环
                    temp = data
                    
                    if isLast {
                        print("发送最后一个(\(data.count))字节: : \(data.hexString)")
                        peripheral.core.writeValue(data, for: dmxChannelCharacteristic, type: .withResponse)
                    }
                    
                    continue
                }
                
                /// 更新临时数据流
                temp = add
                
                if isLast {
                    print("发送最后几次的累加值(\(add.count))字节: \(add.hexString)")
                    peripheral.core.writeValue(add, for: dmxChannelCharacteristic, type: .withResponse)
                }
            } else {
                temp = data
                if isLast {
                    print("发送单个值(\(data.count))字节: \(data.hexString)")
                    peripheral.core.writeValue(data, for: dmxChannelCharacteristic, type: .withResponse)
                }
            }
        }
    }
    
    public static func disconnect(_ timo: TimoPeripheral, callback: @escaping TimoDisconnectionResultCallback) {
        if timo.core.state == .disconnected {
            callback(.failure("已经断开"))
            return
        }
        shared.disconnectionResult = { result in
            callback(result)
        }
        shared.centralManager.cancelPeripheralConnection(timo.core)
    }
    
    public static func connect(_ timo: TimoPeripheral, callback: @escaping TimoConnectionResultCallback) {
        shared.connectionResult = { result in
            callback(result)
        }
        shared.centralManager.connect(timo.core, options: nil)
    }
    
    public static func scanningPeripherals(_ callback: @escaping PeripheralScanningCallback) {
        DispatchQueue.main.async {
            shared.foundPeripherals.forEach { fp in
                callback(fp)
            }
            shared.scanningPeripheral = { peripheral in
                callback(peripheral)
            }
        }
    }
}

extension TimoTwo {
    // MARK: - 搜索设备
    private func searchPeripherals() {
//        let services = [
//            dmxDataServiceUUID,
//            dmxGenericDataServiceUUID
//        ]
//        centralManager.scanForPeripherals(withServices: services, options: nil)
        centralManager.scanForPeripherals(withServices: nil)
    }
    
}

extension TimoTwo: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            sendDataResult(.failure(error))
        } else {
            sendDataResult(.success(true))
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if service.uuid == dmxDataServiceUUID {
            if let characteristics = service.characteristics {
                characteristics.forEach { char in
                    print("发现DMX 特征值: \(char.uuid.uuidString)")
                }
                dmxChannelCharacteristic = characteristics.first { filter in
                    filter.uuid == dmxChannelCharacteristicUUID
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let services = peripheral.services {
            services.forEach { service in
                print("发现服务:", service.uuid.uuidString)
            }
            /// DMX data service
            let dmxDataService = services.first { filter in
                filter.uuid == dmxDataServiceUUID
            }
            if let dmxDataService {
                let uuids = [dmxChannelCharacteristicUUID]
                peripheral.discoverCharacteristics(uuids, for: dmxDataService)
            }
        }
    }
    
}

extension TimoTwo: CBCentralManagerDelegate {
    
    // MARK: - 数据交互
    
    /// 连接成功
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        /// 发送连接成功通知
        let result = Result<CBPeripheral, Error>.success(peripheral)
        connectionResult(result)
        
        /// 发现服务
        let services = [
            dmxDataServiceUUID
        ]
        print("连接成功")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    /// 连接失败
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let result: Result<CBPeripheral, Error>
        if let error {
            result = .failure(error)
        } else {
            result = .failure(TimoError.unknown)
        }
        connectionResult(result)
    }
    
    /// 断开连接
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let result: Result<CBPeripheral, Error>
        if let error {
            result = .failure(error)
        } else {
            result = .success(peripheral)
        }
        disconnectionResult(result)
    }
    
    
    // MARK: - 扫描 | 状态更新
    /// 扫描发现外围设备
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        /// 确保设备为断开状态
//        guard peripheral.state == .disconnected else { return }
        
        /// 确保名称不为空
        guard let name = peripheral.name, !name.isEmpty else { return }
        
        let names = [
            "TimoTwo",
            "godox fixture"
        ]
        
        /// 确保名称为这个名字
        guard names.contains(name) else { return }
        print(name)
        /// 是否包含在数组内
        let contains = foundPeripherals.contains { element in
            element.identifier == peripheral.identifier
        }
        
        /// 如果包含在数组内则直接跳过
        if contains {
            return
        }
        
        guard let timo = TimoPeripheral(advertisementData, core: peripheral) else { return }
        
        foundPeripherals.append(timo)
        scanningPeripheral(timo)
    }
    
    /// 设备蓝牙状态更新回调
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        currentState = central.state
    }
}
