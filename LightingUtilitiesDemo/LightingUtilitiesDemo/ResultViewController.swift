//
//  ResultViewController.swift
//  LightingUtilitiesDemo
//
//  Created by Choi on 2022/12/7.
//

import UIKit

class ResultViewController: UIViewController {

    @IBOutlet weak var resultTextView: UITextView!
    
    var result: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        resultTextView.text = result
    }
}
