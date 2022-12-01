//
//  ViewController.swift
//  LightingUtilitiesDemo
//
//  Created by Choi on 2022/12/1.
//

import UIKit
import LightingUtilities
import ArtNet

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let input = BLEChannelInput(range: 0...3, inputs: []) else { return }
    }
}

