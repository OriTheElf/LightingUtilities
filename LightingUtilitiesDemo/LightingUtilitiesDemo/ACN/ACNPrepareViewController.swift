//
//  ACNPrepareViewController.swift
//  LightingUtilitiesDemo
//
//  Created by Choi on 2023/2/11.
//

import UIKit

class ACNPrepareViewController: UIViewController {

    @IBAction func go(_ sender: UIButton) {
        var param: [String: String] = [:]
        param["universe"] = inputTF.text
        param["ip_address"] = ipTF.text
        performSegue(withIdentifier: "detail", sender: param)
    }
    
    @IBOutlet weak var inputTF: UITextField!
    @IBOutlet weak var ipTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DetailController {
            if let param = sender as? [String: String] {
                destination.param = param
            }
        }
    }
}
