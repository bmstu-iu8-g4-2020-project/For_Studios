//
//  TableViewCell.swift
//  Studios
//
//  Created by Farid Babayev on 04.12.2020.
//

import UIKit

class PriceTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var finalPriceLabel: UILabel!

    var priceUpdater: PriceUpdater?
    var indexPath = IndexPath()

    override func awakeFromNib() {
        super.awakeFromNib()
        quantityTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func editingIsFinished(_ sender: UITextField) {
        priceUpdater?.updatePrice(count: Int(sender.text ?? "0") ?? 0, for: indexPath)
    }
}

extension PriceTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
