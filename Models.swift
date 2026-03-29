import Foundation

struct Court: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let location: String
    let distance: Double // in km
    let rating: Double
    let imageURL: String
    let pricePerHour: Double
    let sport: String
    let type: String // Indoor/Outdoor
    let availableTimes: [String]
    
    static let sampleCourts = [
        Court(
            id: "1",
            name: "Court 1",
            location: "Vondelpark",
            distance: 0.4,
            rating: 4.9,
            imageURL: "tennis_court_1",
            pricePerHour: 15.00,
            sport: "Tennis",
            type: "Outdoor",
            availableTimes: ["09:00", "10:00", "11:00", "12:00", "14:00", "15:00", "16:00"]
        ),
        Court(
            id: "2",
            name: "Court 2",
            location: "Vondelpark",
            distance: 0.5,
            rating: 4.4,
            imageURL: "tennis_court_2",
            pricePerHour: 15.00,
            sport: "Tennis",
            type: "Outdoor",
            availableTimes: ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00", "17:00"]
        ),
        Court(
            id: "3",
            name: "Court 3",
            location: "Amsterdamse Bos",
            distance: 1.2,
            rating: 4.7,
            imageURL: "tennis_court_3",
            pricePerHour: 18.00,
            sport: "Tennis",
            type: "Indoor",
            availableTimes: ["08:00", "09:00", "10:00", "11:00", "12:00", "13:00"]
        )
    ]

    func availableTimes(on date: Date, now: Date = Date()) -> [String] {
        let blockedTimes = ["10:00", "11:00"]

        return availableTimes.filter { time in
            guard !blockedTimes.contains(time) else {
                return false
            }

            if !Calendar.current.isDate(date, inSameDayAs: now) {
                return true
            }

            return scheduledDate(for: time, on: date) > now
        }
    }

    func suggestedBookingDate(now: Date = Date()) -> Date {
        let today = Calendar.current.startOfDay(for: now)

        if !availableTimes(on: today, now: now).isEmpty {
            return today
        }

        return Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        )
    }

    func scheduledDate(for time: String, on date: Date) -> Date {
        let parts = time.split(separator: ":")
        let hour = Int(parts.first ?? "") ?? 0
        let minute = Int(parts.dropFirst().first ?? "") ?? 0

        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: date
        ) ?? date
    }
}

struct Booking: Identifiable, Codable, Hashable {
    let id: String
    let court: Court
    let date: Date
    let time: String
    let total: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    var scheduledDate: Date {
        let day = Calendar.current.startOfDay(for: date)
        return Calendar.current.date(
            bySettingHour: startHour,
            minute: startMinute,
            second: 0,
            of: day
        ) ?? date
    }

    var dateBadge: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }

        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var startHour: Int {
        let parts = time.split(separator: ":")
        return Int(parts.first ?? "") ?? 0
    }

    private var startMinute: Int {
        let parts = time.split(separator: ":")
        return Int(parts.dropFirst().first ?? "") ?? 0
    }
}

struct ReserveSnapshot: Codable {
    let courts: [Court]
    let bookings: [Booking]
    let featuredBookingID: String?
    let updatedAt: Date
}

struct User {
    let name: String
    let profileImage: String
    
    static let sample = User(name: "Alex", profileImage: "profile_photo")
}
