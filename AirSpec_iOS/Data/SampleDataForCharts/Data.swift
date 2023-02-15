//
// Copyright © 2022 Swift Charts Examples.
// Open Source - MIT License

import Foundation

func date(year: Int, month: Int, day: Int = 1, hour: Int = 0, minutes: Int = 0, seconds: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minutes, second: seconds)) ?? Date()
}

enum Constants {
    static let previewChartHeight: CGFloat = 50
    static let detailChartHeight: CGFloat = 150
}

/// Data for the sales by location and weekday charts.
enum comfortData {
    /// A data series for the lines.
    struct Series: Identifiable {
        /// The name of the city.
        let comfortType: String

        /// Average daily sales for each weekday.
        /// The `weekday` property is a `Date` that represents a weekday.
        let value: [(minutes: Date, value: Int)]

        /// The identifier for the series.
        var id: String { comfortType }
    }

    /// Sales by location and weekday for the last 30 days.
    static let today: [Series] = [
        .init(comfortType: "comfy", value: [
            (minutes: date(year: 2022, month: 5, day: 8, hour: 13, minutes: 10), value: 0),
            (minutes: date(year: 2022, month: 5, day: 8, hour: 14, minutes: 10), value: 0),
            (minutes: date(year: 2022, month: 5, day: 8, hour: 15, minutes: 10), value: 0),
            (minutes: date(year: 2022, month: 5, day: 8, hour: 16, minutes: 10), value: 0),
            (minutes: date(year: 2022, month: 5, day: 8, hour: 17, minutes: 10), value: 0),
        ]),
        .init(comfortType: "not comfy", value: [
            (minutes: date(year: 2022, month: 5, day: 8, hour: 13, minutes: 30), value: 0),
            (minutes: date(year: 2022, month: 5, day: 8, hour: 14, minutes: 30), value: 0),
            (minutes: date(year: 2022, month: 5, day: 8, hour: 15, minutes: 30), value: 0),
            (minutes: date(year: 2022, month: 5, day: 8, hour: 16, minutes: 30), value: 0),
            (minutes: date(year: 2022, month: 5, day: 8, hour: 17, minutes: 30), value: 0),
        ]),
    ]
}

struct temp {
    let minutes: Date
    var values: Int
}


extension Date {
	static var startOfDay: Date {
		Calendar.current.startOfDay(for: .now)
	}
}

extension Date {
	func nearestHour() -> Date? {
		var components = NSCalendar.current.dateComponents([.minute, .second, .nanosecond], from: self)
		let minute = components.minute ?? 0
		let second = components.second ?? 0
		let nanosecond = components.nanosecond ?? 0
		components.minute = minute >= 30 ? 60 - minute : -minute
		components.second = -second
		components.nanosecond = -nanosecond
		return Calendar.current.date(byAdding: components, to: self)
	}
}

extension Array {
	func appending(contentsOf: [Element]) -> Array {
		var a = Array(self)
		a.append(contentsOf: contentsOf)
		return a
	}
}
