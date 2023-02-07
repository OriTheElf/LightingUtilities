//
//  ViewController.swift
//  TimoTwoDemo
//
//  Created by Choi on 2022/11/16.
//

import UIKit
import CoreBluetooth
import LightingUtilities

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var peripherals: [TimoPeripheral] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PeripheralCell.self, forCellReuseIdentifier: String(describing: PeripheralCell.self))
        
        TimoTwo.scanningPeripherals {
            [weak self] peripheral in
            guard let self else { return }
            if !self.peripherals.contains(peripheral) {
                self.peripherals.append(peripheral)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detail = segue.destination as! DetailController
        detail.peripheral = sender as? TimoPeripheral
    }
    
    @IBAction func skip() {
        performSegue(withIdentifier: "detail", sender: nil)
    }
}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timo = peripherals[indexPath.row]
        performSegue(withIdentifier: "detail", sender: timo)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = String(describing: PeripheralCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! PeripheralCell
        cell.peripheral = peripherals[indexPath.row]
        return cell
    }
    
}
