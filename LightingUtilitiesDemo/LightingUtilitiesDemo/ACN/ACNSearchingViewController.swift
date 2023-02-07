//
//  sACNViewController.swift
//  LightingUtilitiesDemo
//
//  Created by Choi on 2022/12/22.
//

import UIKit
import Network
import sACN

final class sACNSearchCell: UITableViewCell {
    @IBOutlet weak var ipLabel: UILabel!
    
    var ipv4: IPv4Address? {
        willSet {
            guard let newValue else { return }
            ipLabel.text = newValue.debugDescription
        }
    }
}

class ACNSearchingViewController: UITableViewController {

    private weak var timer: Timer?
    private var ipAddresses: [IPv4Address] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [unowned self] _ in search()
        }
        RunLoop.main.add(timer.unsafelyUnwrapped, forMode: .common)
    }
    
    private func search() {
        print("搜...")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ipAddresses.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ip = ipAddresses[indexPath.row]
        let id = String(describing: sACNSearchCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! sACNSearchCell
        cell.ipv4 = ip
        return cell
    }
    
    deinit {
        print("计时器销毁...")
        timer?.invalidate()
    }
}
