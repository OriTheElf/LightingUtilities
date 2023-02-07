//
//  InputCell.swift
//  TimoTwoDemo
//
//  Created by Choi on 2022/11/17.
//

import UIKit

class InputCell: UICollectionViewCell {

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var valueLabel: UILabel!
    
    var inputChanged: (UInt8) -> Void = { _ in }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    var value: UInt8? {
        willSet {
            guard let newValue else {
                slider.value = 0
                valueLabel.text = "N/A"
                return
            }
            slider.value = Float(newValue)
            valueLabel.text = String(newValue)
        }
    }
    
    @IBAction func minus() {
        slider.value -= 1
        slider.sendActions(for: .valueChanged)
    }
    
    @IBAction func plus() {
        slider.value += 1
        slider.sendActions(for: .valueChanged)
    }
    
    @IBAction func valueChanged(_ sender: UISlider) {
        let value = UInt8(sender.value)
        valueLabel.text = String(value)
        inputChanged(value)
    }
}
