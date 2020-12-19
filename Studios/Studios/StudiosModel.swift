
import Foundation
import FirebaseFirestore

class StudiosModel {
    
    private let bookingsReference = Firestore.firestore().collection("bookings")
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    private var selectedDay = String()
    private var mode = AdminMode.read
    private let studioOpenTime = 8
    private var timeMark = TimeMark.start
    private let numberOfTimes = 15
    private var bookings = [Booking]()
    private var betweenTimes = [String]()
    private var edgeTimes = [String]()
    
    func getSudioSchedule(completion: @escaping () -> Void) {
        bookingsReference.whereField("bookDate", isEqualTo: selectedDay).getDocuments { (snapshot, error) in
            guard error == nil, let documents = snapshot?.documents else {
                completion()
                return
            }
            self.bookings = []
            self.edgeTimes = []
            self.betweenTimes = []
            for document in documents {
                var booking = Booking()
                booking.bookDate = document.data()["bookDate"] as? String ?? ""
                booking.clientName = document.data()["clientName"] as? String ?? ""
                booking.clientPhoneNumber = document.data()["clientPhoneNumber"] as? String ?? ""
                booking.clientSurname = document.data()["clientSurname"] as? String ?? ""
                booking.creationDate = document.data()["creationDate"] as? String ?? ""
                booking.elementsQuantity = document.data()["elementsQuantity"] as? [String:Int] ?? [:]
                booking.fullPrice = document.data()["fullPrice"] as? Int ?? 0
                booking.timeArray = document.data()["timeArray"] as? [String] ?? []
                self.parseTimeTypes(booking.timeArray)
                self.bookings.append(booking)
            }
            completion()
        }
    }
    
    func parseTimeTypes(_ times: [String]) {
        var newTimes = times
        if newTimes.count > 0 {
            edgeTimes.append(newTimes.remove(at: 0))
        }
        if newTimes.count > 0 {
            edgeTimes.append(newTimes.remove(at: newTimes.count - 1))
        }
        betweenTimes += newTimes
    }
    
    func isTimeEdge(_ time: String) -> Bool? {
        if edgeTimes.contains(time) {
            return true
        }
        if betweenTimes.contains(time) {
            return false
        }
        return nil
    }
    
    func isStudioEmptyNow() -> Bool? {
        guard selectedDay == dateFormatter.string(from: Date()) else {
            return nil
        }
        let hourNumber = Calendar.current.component(.hour, from: Date())
        return isStudioEmpty(at: hourNumber - studioOpenTime)
    }
    
    func isStudioEmpty(at cellIndex: Int) -> Bool {
        let bookingTime = edgeTimes + betweenTimes
        let currentHour = getTimeString(for: cellIndex)
        let bookingTimeString = "\(currentHour):00"
        return !bookingTime.contains(bookingTimeString)
    }
    
    func isStudioEmptyBetween(_ startIndex: Int, and endIndex: Int) -> Bool {
        var possibleTimeArray = [String]()
        let bookingTime = edgeTimes + betweenTimes
        for hour in (startIndex + studioOpenTime)..<(endIndex + studioOpenTime) {
            possibleTimeArray.append("\(hour):00")
        }
        for possibleTime in possibleTimeArray {
            if bookingTime.contains(possibleTime) {
                return false
            }
        }
        return true
    }
    
    func setSelectedDay(day: Date) {
        selectedDay = dateFormatter.string(from: day)
    }
    
    func getAdminMode() -> AdminMode {
        return mode
    }
    
    func setAdminMode(_ newMode: AdminMode) {
        mode = newMode
    }
    
    func getTimeMark() -> TimeMark {
        return timeMark
    }
    
    func setTimeMark(_ newTimeMark: TimeMark) {
        timeMark = newTimeMark
    }
    
    func getTimeString(for index: Int) -> Int {
        return index + studioOpenTime
    }
    
    func getNumberOfTimes() -> Int {
        return numberOfTimes
    }
    
    func transportData(to model: BookingFormModel, startTimeIndex: Int, endTimeIndex: Int) {
        model.selectedDate = selectedDay
        model.startTime = startTimeIndex + studioOpenTime
        model.endTime = endTimeIndex + studioOpenTime + 1
    }
}
