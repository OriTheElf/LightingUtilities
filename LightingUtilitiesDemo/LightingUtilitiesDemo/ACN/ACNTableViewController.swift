//
//  ACNTableViewController.swift
//  LightingUtilitiesDemo
//
//  Created by Choi on 2023/2/7.
//

import UIKit

class ACNTableViewController: UITableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "searchACNDevices", sender: nil)
        default:
            break
        }
    }
}
