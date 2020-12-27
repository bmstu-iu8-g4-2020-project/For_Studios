
import UIKit

class BookingFormViewController: UIViewController {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var surnameTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var instrumentsTableView: UITableView!
    @IBOutlet weak var fullPriceLabel: UILabel!
    var loaderView = UIActivityIndicatorView()
    var blurEffectView = UIVisualEffectView()
    
    var model = BookingFormModel()
    var scheduleUpdater: ScheduleUpdater?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fillDateLabel()
        configureTableView()
        setupTextFields()
        prepareData()
        addBlurView()
        addLoaderView()
    }
    
    func fillDateLabel() {
        dateLabel.text = model.getDateString()
    }
    
    func setupTextFields() {
        surnameTextField.delegate = self
        nameTextField.delegate = self
        phoneNumberTextField.delegate = self
    }
    
    func configureTableView() {
        instrumentsTableView.dataSource = self
        instrumentsTableView.delegate = self
        let nibCell = UINib(nibName: "PriceTableViewCell", bundle: nil)
        instrumentsTableView.register(nibCell, forCellReuseIdentifier: "PriceTableViewCell")
    }
    
    func prepareData() {
        showLoadingScreen()
        model.getPriceList {
            self.hideLoadingScreen()
            DispatchQueue.main.async {
                self.instrumentsTableView.reloadData()
            }
        }
    }
    
    private func presentNonActionAlert(message: String) {
        let testAlertController = UIAlertController(title: "Ошибка бронирования", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        testAlertController.addAction(ok)
        self.present(testAlertController, animated: true)
    }
    
    //MARK: - Loading Screen
    
    private func showLoadingScreen() {
        view.bringSubviewToFront(blurEffectView)
        view.bringSubviewToFront(loaderView)
        loaderView.startAnimating()
    }
    
    private func hideLoadingScreen() {
        view.sendSubviewToBack(blurEffectView)
        view.sendSubviewToBack(loaderView)
        loaderView.stopAnimating()
    }
    
    private func addBlurView() {
        let blurEffect = UIBlurEffect(style: .light)
        blurEffectView.effect = blurEffect
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        //view.sendSubviewToBack(blurEffectView)
    }
    
    private func addLoaderView() {
        //loaderView.hidesWhenStopped = true
        loaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loaderView)
        loaderView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.main.bounds.height / 2).isActive = true
        loaderView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //view.sendSubviewToBack(loaderView)
    }
    
    @IBAction func bookTapped(_ sender: UIButton) {
        showLoadingScreen()
        model.bookTime(surname: surnameTextField.text,
                       name: nameTextField.text,
                       phoneNumber: phoneNumberTextField.text) { (error) in
            if let error = error {
                self.hideLoadingScreen()
                self.presentNonActionAlert(message: error)
            } else {
                self.hideLoadingScreen()
                self.scheduleUpdater?.updateSchedule()
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension BookingFormViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return model.getNumberOfInstruments()
        case 1: return model.getNumberOfExtrServices()
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PriceTableViewCell", for: indexPath) as! PriceTableViewCell
        var name = String()
        var price = String()
        let quantity = model.getQuantityOfElements(for: indexPath)
        switch indexPath.section {
        case 0:
            name = model.getInstrumentName(for: indexPath.row)
            price = model.getInstrumentPrice(for: indexPath.row)
        default:
            name = model.getExtraServiceName(for: indexPath.row)
            price = model.getExtraServicePrice(for: indexPath.row)
        }
        cell.nameLabel.text = name
        cell.finalPriceLabel.text = price
        cell.quantityTextField.text = quantity
        cell.priceUpdater = self
        cell.indexPath = indexPath
        return cell
    }
}

extension BookingFormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Инструменты"
        case 1: return "Дополнительно"
        default: return ""
        }
    }
}

extension BookingFormViewController: PriceUpdater {
    func updatePrice(count: Int, for indexPath: IndexPath) {
        model.updateElementsQuantity(indexPath: indexPath, value: count)
        fullPriceLabel.text = model.getFullPriceString()
        instrumentsTableView.reloadData()
    }
}

extension BookingFormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
