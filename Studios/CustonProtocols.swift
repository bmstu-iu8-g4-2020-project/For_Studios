
import Foundation

protocol PriceUpdater {
    func updatePrice(count: Int, for indexPath: IndexPath)
}

protocol ScheduleUpdater {
    func updateSchedule()
}
