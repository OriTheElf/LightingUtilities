//
//  ArtNetNodeCell.swift
//  LightingUtilitiesDemo
//
//  Created by Choi on 2022/12/2.
//

import UIKit
import ArtNet

class ArtNetNodeCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var macAddressLabel: UILabel!
    
    var node: ArtPollReply? {
        willSet {
            guard let newValue else { return }
            nameLabel.text = newValue.longName
            macAddressLabel.text = newValue.macAddress.description
        }
    }
}
