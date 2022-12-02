//
//  DetailController.swift
//  TimoTwoDemo
//
//  Created by Choi on 2022/11/16.
//

import UIKit
import LightingUtilities

final class DetailController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var peripheral: TimoPeripheral?
    
    var inputs: [IndexPath: UInt8] = [:]
    
    var channelRange: ClosedRange<UInt16> = 0...0 {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var upperbound: UInt16 = 0
    var lowerbound: UInt16 = 0
    
    @IBOutlet weak var channelStart: UITextField!
    @IBOutlet weak var channelEnd: UITextField!
    @IBOutlet weak var defaultTf: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connet()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        disconnect()
    }
    
    @IBAction func connet() {
        if let peripheral {
            TimoTwo.connect(peripheral) { result in
                print("连接成功", result)
            }
        }
    }
    
    @IBAction func disconnect() {
        if let peripheral {
            TimoTwo.disconnect(peripheral) { result in
                print("断开连接", result)
            }
        }
    }
    
    @IBAction func sendAll() {
        if let peripheral {
            let ranges: [ClosedRange<UInt16>] = [
                1...127,
                128...254,
                255...381,
                382...508,
                509...512
            ]
            let inputs = ranges.compactMap { range in
                let inputs: [UInt8] = range.map { _ in 0 }
                return BLEChannelInput(range: range, inputs: inputs)
            }
            TimoTwo.sendChannelInputs(inputs, to: peripheral) { result in
                print(result)
            }
        }
    }
    
    @IBAction func send() {
        if let peripheral {
            let sortedInputs = inputs.sorted { kv1, kv2 in
                kv1.key.row < kv2.key.row
            }
            let finalInputs = sortedInputs.map(\.value)
            guard let input = BLEChannelInput(range: channelRange, inputs: finalInputs) else { return }
            TimoTwo.sendChannelInputs(input, to: peripheral) { result in
                print(result)
            }
        }
    }
    
    @IBAction func setDefaults() {
        let df = defaultTf.text ?? ""
        if let value = UInt8(df) {
            channelRange.enumerated().forEach { index, _ in
                let idx = IndexPath(row: index, section: 0)
                inputs[idx] = value
            }
            collectionView.reloadData()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

extension DetailController: UITextFieldDelegate {
    
    static let legalChannelRange: ClosedRange<UInt16> = 1...512
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Get latest text of the textfield.
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let final = currentText.replacingCharacters(in: stringRange, with: string)
        let value = UInt16(final)
        if !string.isEmpty {
            guard let value, Self.legalChannelRange ~= value else {
                return false
            }
            if textField.isEqual(channelStart) {
                lowerbound = value
                inputs.removeAll()
                if lowerbound <= upperbound {
                    channelRange = lowerbound...upperbound
                }
                return true
            } else if textField.isEqual(channelEnd) {
                upperbound = value
                inputs.removeAll()
                if lowerbound <= upperbound {
                    channelRange = lowerbound...upperbound
                }
                return true
            } else {
                return true
            }
        }
        return true
    }
}

extension DetailController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let itemHeight = 45.0
        let sectionInset = layout.sectionInsetsAt(indexPath).left + layout.sectionInsetsAt(indexPath).right
        let itemsWidth = collectionView.bounds.width - sectionInset
        let itemWidth = itemsWidth
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let id = String(describing: InputCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! InputCell

        cell.value = inputs[indexPath]
        cell.inputChanged = {
            [unowned self] input in inputs[indexPath] = input
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        channelRange.count
    }
}


extension UICollectionViewFlowLayout {
    
    // MARK: - 先从代理方法里获取各项参数 | 再使用默认属性
    func sectionInsetsAt(_ indexPath: IndexPath) -> UIEdgeInsets {
        guard let collectionView else { return sectionInset }
        guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return sectionInset }
        return delegate.collectionView?(collectionView, layout: self, insetForSectionAt: indexPath.section) ?? sectionInset
    }
    
    func minimumInteritemSpacingForSectionAt(_ indexPath: IndexPath) -> CGFloat {
        guard let collectionView else { return minimumInteritemSpacing }
        guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return minimumInteritemSpacing }
        return delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: indexPath.section) ?? minimumInteritemSpacing
    }
    
    func minimumLineSpacingForSectionAt(_ indexPath: IndexPath) -> CGFloat {
        guard let collectionView else { return minimumLineSpacing }
        guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return minimumLineSpacing }
        return delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: indexPath.section) ?? minimumLineSpacing
    }
}
