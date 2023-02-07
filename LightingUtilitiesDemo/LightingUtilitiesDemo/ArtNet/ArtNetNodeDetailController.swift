//
//  ArtNetNodeDetailController.swift
//  LightingUtilitiesDemo
//
//  Created by Choi on 2022/12/3.
//

import UIKit
import ArtNet


extension Optional where Wrapped == String {
    
    var intValue: Int {
        Int(orEmpty) ?? 0
    }
    
    var orEmpty: String {
        self ?? ""
    }
}

class ArtNetNodeDetailController: UIViewController {

    var artnetNode: ArtPollReply?
    
    @IBOutlet weak var netTF: UITextField!
    @IBOutlet weak var subnetTF: UITextField!
    @IBOutlet weak var dmx1TF: UITextField!
    @IBOutlet weak var dmx2TF: UITextField!
    @IBOutlet weak var dmx3TF: UITextField!
    @IBOutlet weak var dmx4TF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let artnetNode {
            netTF.text = artnetNode.netSwitch.description
            subnetTF.text = artnetNode.subSwitch.description
            dmx1TF.text = artnetNode.outputAddresses[0]?.rawValue.description
            dmx2TF.text = artnetNode.outputAddresses[1]?.rawValue.description
            dmx3TF.text = artnetNode.outputAddresses[2]?.rawValue.description
            dmx4TF.text = artnetNode.outputAddresses[3]?.rawValue.description
        }
    }
    
    @IBAction func sendData(_ sender: UIButton) {
        guard let universe = PortAddress.Universe(rawValue: dmx1TF.text.intValue.uInt8) else {
            print("Universe 非法")
            return
        }
        guard let subnet = PortAddress.SubNet(rawValue: subnetTF.text.intValue.uInt8) else {
            print("SubNet 非法")
            return
        }
        guard let net = PortAddress.Net(rawValue: netTF.text.intValue.uInt8) else {
            print("Net 非法")
            return
        }
        let portAddress = PortAddress(universe: universe, subnet: subnet, net: net)
        
        let samples: [UInt8] = [0, 255]
        let values = (1...512).map { _ in
            samples.randomElement() ?? 0
        }
        let data = Data(values)
        let dmx = ArtDmx(sequence: 0xFF, physical: 0xFF, portAddress: portAddress, lightingData: data)
        Ethernet.shared.send(dmx.data)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
