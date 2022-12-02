//
//  PeripheralCell.swift
//  TimoTwoDemo
//
//  Created by Choi on 2022/11/16.
//

import UIKit
import CoreBluetooth
import LightingUtilities

final class PeripheralCell: UITableViewCell {
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var peripheral: TimoPeripheral? {
        willSet {
            if let newValue {
                nameLabel.text = newValue.name
            }
        }
    }
}
