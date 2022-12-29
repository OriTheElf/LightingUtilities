//
//  SearchingArtNetNodesViewController.swift
//  TimoTwoDemo
//
//  Created by Choi on 2022/11/23.
//

import UIKit
import Combine
import LightingUtilities
import ArtNet
import Network

extension String {
    
    static var tagMAC: String {
        
        func GetMACAddressFromIPv6(ip: String) -> String{
            let IPStruct = IPv6Address(ip)
            if(IPStruct == nil){
                return ""
            }
            let extractedMAC = [
                (IPStruct?.rawValue[8])! ^ 0b00000010,
                IPStruct?.rawValue[9],
                IPStruct?.rawValue[10],
                IPStruct?.rawValue[13],
                IPStruct?.rawValue[14],
                IPStruct?.rawValue[15]
            ]
            let str = String(format: "%02X:%02X:%02X:%02X:%02X:%02X", extractedMAC[0] ?? 00,
                extractedMAC[1] ?? 00,
                extractedMAC[2] ?? 00,
                extractedMAC[3] ?? 00,
                extractedMAC[4] ?? 00,
                extractedMAC[5] ?? 00)
            return str
        }
        
        func getAddress() -> String? {
            var address: String?

            // Get list of all interfaces on the local machine:
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifaddr) == 0 else { return nil }
            guard let firstAddr = ifaddr else { return nil }

            // For each interface ...
            for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
                let interface = ifptr.pointee
                
                // Check IPv6 interface:
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET6) {
                    // Check interface name:
                    let name = String(cString: interface.ifa_name)
                    if name.contains("ipsec") {
                        print("接口名字:", name)
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        let ipv6addr = IPv6Address(address ?? "::")
                        if(ipv6addr?.isLinkLocal ?? false){
                            return address
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)

            return address
        }
        
        let address = getAddress()
        let macAddress = GetMACAddressFromIPv6(ip: address ?? "")
        return macAddress
    }
}

extension Publisher {
    
    func flatMapLatest<T: Publisher>(_ transform: @escaping (Output) -> T) -> Publishers.SwitchToLatest<T, Publishers.Map<Self, T>> where T.Failure == Failure {
        map(transform).switchToLatest()
    }
}

extension Data {
    
    static var artPollData: Data {
        
        /// 参考: https://art-net.org.uk/how-it-works/discovery-packets/artpoll/
        let opCode: UInt16 = 0x2000
        let protVer: UInt16 = 0x000E
        let flags: UInt8 = 0x06
        let priority: UInt8 = 0x00
        
        let data = [
            priority.data,
            flags.data,
            protVer.byteFlippedData,
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

extension IPv4Address {
    
    static var broadcast: IPv4Address? {
        let ip = UIDevice.current.broadcastIP
        guard let ipv4 = IPv4Address(ip) else {
            return nil
        }
        return ipv4
    }
}

final class Ethernet {
    static let shared = Ethernet()
    var didReceiveData: ((Data) -> Void)?
    
    private lazy var nwQueue = DispatchQueue(label: "com.nw.connection.queue")
    private var nwSendConnection: NWConnection?
    private var listener: NWListener?
    
    private init() {
        
        if let ipv4Address = IPv4Address.broadcast {
            let host = NWEndpoint.Host.ipv4(ipv4Address)
            let port: NWEndpoint.Port = 6454
            let connection = NWConnection(host: host, port: port, using: .udp)
            nwSendConnection = connection
            connection.start(queue: nwQueue)
            
            /// 监听端口
            do {
                /// 定义参数
                let params = NWParameters.udp
                params.allowFastOpen = true
                
                /// 创建
                let listener = try NWListener(using: params, on: port)
                listener.newConnectionHandler = {
                    [weak self, shadowListener = listener] connection in
                    if let self {
                        self.prepareConnection(connection)
                    } else {
                        connection.cancel()
                        shadowListener.cancel()
                    }
                }
                listener.start(queue: nwQueue)
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        
        
    }
    
    func send(_ data: Data) {
        print("send:", data.hexString)
        if let nwSendConnection {
            nwSendConnection.send(content: data, completion: .idempotent)
        }
    }
    
    private func didReceiveData(_ data: Data) {
        if let didReceiveData {
            print("receive:", data.hexString)
            didReceiveData(data)
        }
    }
    
    private weak var nwReceiveConnection: NWConnection!
    func prepareConnection(_ connection: NWConnection) {
        nwReceiveConnection = connection
        nwReceiveConnection.receiveMessage {
            [unowned self] content, context, isComplete, error in
            if let error {
                print(error)
                return
            }
            if let content {
                didReceiveData(content)
                if isComplete {
                    nwReceiveConnection.cancel()
                }
            }
        }
        
        nwReceiveConnection.start(queue: nwQueue)
    }
}

class SearchingArtNetNodesViewController: UITableViewController {
    
    private var nodes: [ArtPollReply] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Ethernet.shared.didReceiveData = {
            [weak self] data in
            guard let self else { return }
            if let reply = data.artPollReply {
                self.nodes.replace(with: reply) { old, new in
                    old.macAddress == new.macAddress
                }
            }
        }
    }
    
    @IBAction func sendUDP() {
        let data = ArtPoll.standard.data
        Ethernet.shared.send(data)
    }
    
    @IBAction func test(_ sender: Any) {
        let interfaces: [UIDevice.NetworkInterface] = [
            .wifi,
            .wiredEthernet(0),
            .wiredEthernet(1),
            .wiredEthernet(2),
            .wiredEthernet(3),
            .wiredEthernet(4),
            .wiredEthernet(5),
            .wiredEthernet(6),
            .wiredEthernet(7),
            .wiredEthernet(8),
            .wiredEthernet(9),
            .wiredEthernet(10)
        ]
        let results = interfaces.map(UIDevice.current.getAddress)
        
        var resultString = results
            .enumerated()
            .map { index, item in
                "\(interfaces[index].rawValue):" + "\(item.ip.orEmpty) - \(item.netmask.orEmpty)"
            }
            .joined(separator: "\n")
        
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            resultString += "\nUUID:\(uuid)"
        }
        
        let address = GetMACAddress()
        resultString += "\nMac Address:\(address)"
        
        performSegue(withIdentifier: "result", sender: resultString)
    }
    
    func GetMACAddress() -> String {
        let address = getAddress()
        let ipv6Address = GetMACAddressFromIPv6(ip: address ?? "")
        print("ipv6:", address.orEmpty)
        return ipv6Address
    }
    
    func GetMACAddressFromIPv6(ip: String) -> String{
        let IPStruct = IPv6Address(ip)
        if(IPStruct == nil){
            return ""
        }
        let extractedMAC = [
            (IPStruct?.rawValue[8])! ^ 0b00000010,
            IPStruct?.rawValue[9],
            IPStruct?.rawValue[10],
            IPStruct?.rawValue[13],
            IPStruct?.rawValue[14],
            IPStruct?.rawValue[15]
        ]
        let str = String(format: "%02X:%02X:%02X:%02X:%02X:%02X", extractedMAC[0] ?? 00,
            extractedMAC[1] ?? 00,
            extractedMAC[2] ?? 00,
            extractedMAC[3] ?? 00,
            extractedMAC[4] ?? 00,
            extractedMAC[5] ?? 00)
        return str
    }
    
    func getAddress() -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET6) {
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name.contains("ipsec") {
                    print("接口名字:", name)
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    let ipv6addr = IPv6Address(address ?? "::")
                    if(ipv6addr?.isLinkLocal ?? false){
                        return address
                    }
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: ArtNetNodeCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ArtNetNodeCell
        cell.node = nodes[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = nodes[indexPath.row]
        performSegue(withIdentifier: "detail", sender: node)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let result = segue.destination as? ResultViewController {
            result.result = sender as? String
        }
        else if let detail = segue.destination as? ArtNetNodeDetailController {
            detail.artnetNode = sender as? ArtPollReply
        }
    }
}

struct IPInfo {
    let type: NWInterface
    let ipv4: IPv4Address?
    let ipv6: IPv6Address?
    let netmaskv4: IPv4Address?
    let netmaskv6: IPv6Address?
}

extension UIDevice {
    
    enum NetworkInterface {
        case wifi
        case wiredEthernet(Int)
        case cellular(Int)
        
        var rawValue: String {
            /// 这里的en后面的序号是网卡的优先级?
            /// 移动设备用wifi网卡作为优先
            /* mac ip addresses en0 is the rj45 interface
             en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
                 options=46b<RXCSUM,TXCSUM,VLAN_HWTAGGING,TSO4,TSO6,CHANNEL_IO>
                 ether 2c:f0:5d:95:47:68
                 inet6 fe80::cf7:7202:a807:c610%en0 prefixlen 64 secured scopeid 0x5
                 inet 192.168.2.5 netmask 0xffffff00 broadcast 192.168.2.255
                 inet6 240e:3b2:325c:1c80::5 prefixlen 64 dynamic
                 nd6 options=201<PERFORMNUD,DAD>
                 media: autoselect (1000baseT <full-duplex>)
                 status: active
             en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
                 options=400<CHANNEL_IO>
                 ether b8:09:8a:51:41:2b
                 inet6 fe80::42:8911:8eb8:9dd5%en1 prefixlen 64 secured scopeid 0x6
                 inet 192.168.2.6 netmask 0xffffff00 broadcast 192.168.2.255
                 inet6 240e:3b2:325c:1c80::6 prefixlen 64 dynamic
                 nd6 options=201<PERFORMNUD,DAD>
                 media: autoselect
                 status: active
             */
            /// 移动设备不能设置网卡优先级, 默认wifi网卡为en0, en1 ... enX都可能获取到ip地址
            /// iphoneXR 外接网卡是en5, 公司ipad 外接网卡是en3
            
            /// mac平台 en0...enX都可能获取到ip地址
            /// mac mini iphone14模拟器: en0有线网卡; en1:无线网卡; en11:usb-c网卡
            /// 黑苹果 en1:无线网卡; en6:usb-c网卡
            switch self {
            case .wifi:
                return "en0"
            case .wiredEthernet(let num):
                switch num {
                case 0:
                    return "en1"
                case 1:
                    return "en2"
                case 2:
                    return "en3"
                case 3:
                    return "en4"
                case 4:
                    return "en5"
                case 5:
                    return "en6"
                case 6:
                    return "en7"
                case 7:
                    return "en8"
                case 8:
                    return "en9"
                case 9:
                    return "en10"
                case 10:
                    return "en11"
                case 12:
                    return "lo0" /// 本机地址:127.0.0.1 - 255.0.0.0
                case 13:
                    return "utun5" /// 保留地址:198.18.0.1 - 255.255.255.0
                default:
                    return "en2"
                }
            case .cellular(let num):
                switch num {
                case 0:
                    return "pdp_ip0"
                case 1:
                    return "pdp_ip1"
                case 2:
                    return "pdp_ip2"
                default:
                    return "pdp_ip3"
                }
            }
        }
    }
    
    public static func testAll() {
        let interface: [NetworkInterface] = [
            .wifi,
            .cellular(0)
        ]
        
        let values = interface.map { interface in
            UIDevice.current.getAddress(for: interface)
        }
        print(values)
    }
    
    public var broadcastIP: String {
        let result = getAddress(for: .wifi)
        guard let ip = result.ip, let netmask = result.netmask else { return "" }
        return calculateBroadcastAddress(ipAddress: ip, subnetMask: netmask)
    }
    
    func getAddress(for network: NetworkInterface) -> (ip: String?, netmask: String?) {
        var address: String?
        var netmask: String?
        
        /// Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (nil, nil)
        }
        
        /// For each interface ...
        for ifptr in sequence(first: firstAddr, next: \.pointee.ifa_next) {
            let interface = ifptr.pointee
            
            /// Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            /// if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
            if addrFamily == UInt8(AF_INET) {
                
                /// Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == network.rawValue {
                    
                    
                    /// Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST)
                    address = String(cString: hostname)
                    
                    /// 子网掩码转换
                    var netmaskArr = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_netmask,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &netmaskArr,
                        socklen_t(netmaskArr.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST)
                    netmask = String(cString: netmaskArr)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return (address, netmask)
    }
    
    /// 通过IP地址和子网掩码计算广播地址
    /// - Parameters:
    ///   - ipAddress: IP地址
    ///   - subnetMask: 子网掩码
    /// - Returns: 广播地址
    private func calculateBroadcastAddress(ipAddress: String, subnetMask: String) -> String {
        let ipAdressArray = ipAddress.split(separator: ".")
        let subnetMaskArray = subnetMask.split(separator: ".")
        guard ipAdressArray.count == 4 && subnetMaskArray.count == 4 else {
            return "255.255.255.255"
        }
        var broadcastAddressArray = [String]()
        for i in 0..<4 {
            let ipAddressByte = UInt8(ipAdressArray[i]) ?? 0
            let subnetMaskbyte = UInt8(subnetMaskArray[i]) ?? 0
            let broadcastAddressByte = ipAddressByte | ~subnetMaskbyte
            broadcastAddressArray.append(String(broadcastAddressByte))
        }
        return broadcastAddressArray.joined(separator: ".")
    }
}
