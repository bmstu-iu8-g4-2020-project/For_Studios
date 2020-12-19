
import UIKit
import FSCalendar

class StudiosViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var scheduleCollectionView: UICollectionView!
    @IBOutlet weak var timePickingSegmentedControl: UISegmentedControl!
    @IBOutlet weak var bookButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    var blurEffectView = UIVisualEffectView()
    var loaderView = UIActivityIndicatorView()
    
    let betweenBlueColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
    let betweenRedColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
    let edgeRedColor = #colorLiteral(red: 0.7611784935, green: 0, blue: 0.06764990836, alpha: 1)
    let edgeBlueColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
    
    var startTimeCellIndex: Int? {
        didSet {
            colorBetweenDates()
        }
    }
    
    var endTimeCellIndex: Int? {
        didSet {
            colorBetweenDates()
        }
    }
    
    var model = StudiosModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model.setSelectedDay(day: Date())
        configureCollectionView()
        configureNavigationItem()
        configureScreenElements()
        configureCalendar()
        setupBookButton()
        addBlurView()
        addLoaderView()
        prepareData()
    }
    
    private func prepareData() {
        showLoadingScreen()
        model.getSudioSchedule {
            self.hideLoadingScreen()
            DispatchQueue.main.async {
                self.getStudioStatus()
                self.scheduleCollectionView.reloadData()
            }
        }
    }
    
    private func getStudioStatus() {
        guard let isEmpty = model.isStudioEmptyNow() else {
            return
        }
        statusLabel.backgroundColor = isEmpty ? #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1) : #colorLiteral(red: 0.7611784935, green: 0, blue: 0.06764990836, alpha: 1)
        statusLabel.text = isEmpty ? "Время свободно" : "Забронировано"
    }
    
    private func configureCalendar() {
        calendar.locale = Locale(identifier: "ru")
        calendar.dataSource = self
        calendar.delegate = self
    }
    
    private func configureNavigationItem() {
        let bookButton = UIBarButtonItem(title: "Просмотр", style: .plain, target: self, action: #selector(changeModeTapped))
        self.navigationItem.rightBarButtonItem  = bookButton
    }
    
    @objc private func changeModeTapped() {
        let adminMode = model.getAdminMode()
        if adminMode == .read {
            model.setAdminMode(.edit)
            navigationItem.rightBarButtonItem?.title = "Бронирование"
        } else {
            model.setAdminMode(.read)
            navigationItem.rightBarButtonItem?.title = "Просмотр"
            cancelBookingProcess()
        }
        configureScreenElements()
    }
    
    private func configureCollectionView() {
        let nibCell = UINib(nibName: "TimeCollectionViewCell", bundle: nil)
        scheduleCollectionView.register(nibCell, forCellWithReuseIdentifier: "TimeCollectionViewCell")
        scheduleCollectionView.collectionViewLayout = getCellsLayout()
        scheduleCollectionView.delegate = self
        scheduleCollectionView.dataSource = self
    }
    
    @IBAction func statusDetailsTapped(_ sender: UIButton) {
    }
    
    func getCellsLayout() -> UICollectionViewFlowLayout {
        let itemSize = UIScreen.main.bounds.width / 3 - 23
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        layout.itemSize = CGSize(width: itemSize, height: 60)
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        return layout
    }
    
    func configureScreenElements() {
        if model.getAdminMode() == .read {
            timePickingSegmentedControl.isHidden = true
            cancelButton.isHidden = true
        } else {
            timePickingSegmentedControl.isHidden = false
            cancelButton.isHidden = false
        }
    }
    
    func setupBookButton() {
        bookButton.isHidden = !(startTimeCellIndex != nil && endTimeCellIndex != nil)
    }
    
    func cancelBookingProcess() {
        guard startTimeCellIndex != nil || endTimeCellIndex != nil else {
            return
        }
        if let startIndex = startTimeCellIndex {
            eraseCells(from: startIndex, to: endTimeCellIndex ?? startIndex)
        }
        if let endIndex = endTimeCellIndex {
            eraseCells(from: startTimeCellIndex ?? endIndex, to: endIndex)
        }
        startTimeCellIndex = nil
        endTimeCellIndex = nil
        setupBookButton()
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
    
    @IBAction func timeMarkChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            model.setTimeMark(.start)
        } else {
            model.setTimeMark(.end)
        }
    }
    
    @IBAction func bookTapped(_ sender: UIButton) {
        let bookingFormViewController = BookingFormViewController()
        model.transportData(to: bookingFormViewController.model,
                            startTimeIndex: startTimeCellIndex ?? 0,
                            endTimeIndex: endTimeCellIndex ?? 0)
        bookingFormViewController.scheduleUpdater = self
        bookingFormViewController.modalPresentationStyle = .fullScreen
        present(bookingFormViewController, animated: true)
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        cancelBookingProcess()
    }
}

extension StudiosViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.getNumberOfTimes()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeCollectionViewCell", for: indexPath) as! TimeCollectionViewCell
        let timeString = "\(model.getTimeString(for: indexPath.row)):00"
        if let isEdge = model.isTimeEdge(timeString) {
            cell.backgroundColor = isEdge ? edgeRedColor : betweenRedColor
        }
        cell.timeLabel.text = timeString
        return cell
    }
}

extension StudiosViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if model.getAdminMode() == .edit {
            if model.isStudioEmpty(at: indexPath.row) {
                if model.getTimeMark() == .start {
                    if let endIndex = endTimeCellIndex, indexPath.row > endIndex {
                        return
                    }
                    if let endIndex = endTimeCellIndex, !model.isStudioEmptyBetween(indexPath.row, and: endIndex) {
                        return
                    }
                    if let index = startTimeCellIndex, index != endTimeCellIndex {
                        collectionView.cellForItem(at: IndexPath(row: index, section: 0))?.backgroundColor = .white
                    }
                    if let index = startTimeCellIndex, index == endTimeCellIndex {
                        startTimeCellIndex = nil
                        setupBookButton()
                        return
                    }
                    if let startIndex = startTimeCellIndex, startIndex == indexPath.row {
                        startTimeCellIndex = nil
                        if let endIndex = endTimeCellIndex {
                            eraseCells(from: startIndex + 1, to: endIndex + 1)
                        }
                    } else {
                        startTimeCellIndex = indexPath.row
                        collectionView.cellForItem(at: indexPath)?.backgroundColor = edgeBlueColor
                    }
                } else {
                    if let startIndex = startTimeCellIndex, indexPath.row < startIndex {
                        return
                    }
                    if let startIndex = startTimeCellIndex, !model.isStudioEmptyBetween(startIndex, and: indexPath.row) {
                        return
                    }
                    if let index = endTimeCellIndex, index != startTimeCellIndex {
                        collectionView.cellForItem(at: IndexPath(row: index, section: 0))?.backgroundColor = .white
                    }
                    if let index = endTimeCellIndex, index == startTimeCellIndex {
                        endTimeCellIndex = nil
                        setupBookButton()
                        return
                    }
                    if let endIndex = endTimeCellIndex, endIndex == indexPath.row {
                        endTimeCellIndex = nil
                        if let startIndex = startTimeCellIndex {
                            eraseCells(from: startIndex + 1, to: endIndex + 1)
                        }
                    } else {
                        endTimeCellIndex = indexPath.row
                        collectionView.cellForItem(at: indexPath)?.backgroundColor = edgeBlueColor
                    }
                }
                setupBookButton()
            } else {
                
            }
        }
    }
    
    func colorBetweenDates() {
        guard let startIndex = startTimeCellIndex,
              let endIndex = endTimeCellIndex else {
            return
        }
        guard startIndex != endIndex else {
            eraseOddBetweenColors(except: startIndex)
            return
        }
        for cellIndex in 0..<model.getNumberOfTimes() {
            if cellIndex == startIndex || cellIndex == endIndex {
                continue
            }
            if ((startIndex + 1)..<endIndex).contains(cellIndex) {
                scheduleCollectionView.cellForItem(at: IndexPath(row: cellIndex, section: 0))?.backgroundColor = betweenBlueColor
            } else {
                if model.isStudioEmpty(at: cellIndex) {
                    scheduleCollectionView.cellForItem(at: IndexPath(row: cellIndex, section: 0))?.backgroundColor = .white
                }
            }
        }
    }
    
    func eraseOddBetweenColors(except index: Int) {
        for cellIndex in 0..<model.getNumberOfTimes() {
            if scheduleCollectionView.cellForItem(at: IndexPath(row: cellIndex, section: 0))?.backgroundColor == betweenBlueColor {
                scheduleCollectionView.cellForItem(at: IndexPath(row: cellIndex, section: 0))?.backgroundColor = .white
            }
        }
    }
    
    func eraseCells(from startIndex: Int, to endIndex: Int) {
        for cellIndex in 0..<model.getNumberOfTimes() {
            if (startIndex...endIndex).contains(cellIndex) {
                scheduleCollectionView.cellForItem(at: IndexPath(row: cellIndex, section: 0))?.backgroundColor = .white
            }
        }
    }
}

extension StudiosViewController: FSCalendarDataSource {
    
}

extension StudiosViewController: FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        dayChanged(for: date)
    }
    
    func dayChanged(for date: Date) {
        model.setSelectedDay(day: date)
        refreshSchedule()
    }
    
    func refreshSchedule() {
        cancelBookingProcess()
        eraseCells(from: 0, to: model.getNumberOfTimes() - 1)
        prepareData()
    }
}

extension StudiosViewController: ScheduleUpdater {
    func updateSchedule() {
        refreshSchedule()
    }
}
