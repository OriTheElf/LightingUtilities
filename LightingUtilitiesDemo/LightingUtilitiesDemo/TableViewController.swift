//
//  TableViewController.swift
//  TimoTwoDemo
//
//  Created by Choi on 2022/11/23.
//

import UIKit

class TableViewController: UITableViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "ble", sender: nil)
        case 1:
            performSegue(withIdentifier: "artNet", sender: nil)
        default:
            break
        }
    }
}
