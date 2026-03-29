import Foundation
import Combine

enum ReserveSyncStatus: Equatable {
    case ready
    case syncing
    case synced(String)
    case unavailable(String)

    var label: String {
        switch self {
        case .ready:
            return "Companion ready"
        case .syncing:
            return "Syncing now"
        case .synced(let message):
            return message
        case .unavailable(let message):
            return message
        }
    }
}

@MainActor
final class BookingManager: ObservableObject {
    @Published private(set) var bookings: [Booking]
    @Published private(set) var courts: [Court]
    @Published private(set) var syncStatus: ReserveSyncStatus = .ready

    private let storage: ReserveSnapshotStore
    private let syncCoordinator: ReserveSyncCoordinating
    private var latestSnapshotDate: Date
    private var featuredBookingID: String?
    private var isApplyingRemoteSnapshot = false

    convenience init() {
        self.init(
            storage: ReserveSnapshotStore(),
            syncCoordinator: ReserveSyncCoordinator()
        )
    }

    init(
        storage: ReserveSnapshotStore,
        syncCoordinator: ReserveSyncCoordinating
    ) {
        self.storage = storage
        self.syncCoordinator = syncCoordinator

        if let snapshot = storage.load() {
            let normalizedSnapshot = Self.normalized(snapshot)
            bookings = normalizedSnapshot.bookings
            courts = normalizedSnapshot.courts
            featuredBookingID = normalizedSnapshot.featuredBookingID
            latestSnapshotDate = normalizedSnapshot.updatedAt
            storage.save(normalizedSnapshot)
        } else {
            bookings = []
            courts = Court.sampleCourts
            featuredBookingID = nil
            latestSnapshotDate = .distantPast
        }

        self.syncCoordinator.start(initialSnapshot: snapshot()) { [weak self] incomingSnapshot in
            Task { @MainActor [weak self] in
                self?.applyRemoteSnapshotIfNeeded(incomingSnapshot)
            }
        }

        updateSyncAvailability()
    }

    @discardableResult
    func addBooking(court: Court, date: Date, time: String) -> Booking {
        let booking = Booking(
            id: UUID().uuidString,
            court: court,
            date: Self.normalizedCalendarDate(date),
            time: time,
            total: court.pricePerHour
        )

        bookings.append(booking)
        bookings.sort { $0.scheduledDate < $1.scheduledDate }
        featuredBookingID = booking.id
        syncStatus = .syncing
        persistAndSync()
        syncStatus = .synced("Saved and sharing")
        return booking
    }

    func getNextBooking() -> Booking? {
        #if os(watchOS)
        if case .unavailable = syncStatus {
            return nil
        }
        #endif

        if let featuredBooking = featuredBookingCandidate {
            return featuredBooking
        }

        return nextUpcomingBooking
    }

    func refreshSync() {
        updateSyncAvailability()

        if case .unavailable = syncStatus {
            return
        }

        syncStatus = .syncing
        syncCoordinator.refresh()
    }

    var canBookFromCurrentDevice: Bool {
        #if os(watchOS)
        syncCoordinator.availability().isAvailable
        #else
        true
        #endif
    }

    private func snapshot() -> ReserveSnapshot {
        ReserveSnapshot(
            courts: courts,
            bookings: bookings,
            featuredBookingID: featuredBookingID,
            updatedAt: latestSnapshotDate
        )
    }

    private func persistAndSync() {
        latestSnapshotDate = .now
        let currentSnapshot = snapshot()
        storage.save(currentSnapshot)

        if !isApplyingRemoteSnapshot {
            syncCoordinator.broadcast(snapshot: currentSnapshot)
        }
    }

    private func applyRemoteSnapshotIfNeeded(_ incomingSnapshot: ReserveSnapshot) {
        guard incomingSnapshot.updatedAt > latestSnapshotDate else {
            syncStatus = .synced("Already up to date")
            return
        }

        let normalizedSnapshot = Self.normalized(incomingSnapshot)

        isApplyingRemoteSnapshot = true
        bookings = normalizedSnapshot.bookings.sorted { $0.scheduledDate < $1.scheduledDate }
        courts = normalizedSnapshot.courts
        featuredBookingID = Self.normalizedFeaturedBookingID(from: normalizedSnapshot)
        latestSnapshotDate = normalizedSnapshot.updatedAt
        storage.save(normalizedSnapshot)
        isApplyingRemoteSnapshot = false
        syncStatus = .synced("Updated from companion")
    }

    private func updateSyncAvailability() {
        switch syncCoordinator.availability() {
        case .available:
            if case .unavailable = syncStatus {
                syncStatus = .ready
            }
        case .unavailable(let message):
            syncStatus = .unavailable(message)
        }
    }

    private static func normalized(_ snapshot: ReserveSnapshot) -> ReserveSnapshot {
        ReserveSnapshot(
            courts: snapshot.courts,
            bookings: snapshot.bookings.map(Self.normalized),
            featuredBookingID: snapshot.featuredBookingID,
            updatedAt: snapshot.updatedAt
        )
    }

    private var featuredBookingCandidate: Booking? {
        guard let featuredBookingID,
              let booking = bookings.first(where: { $0.id == featuredBookingID }) else {
            return nil
        }

        let startOfToday = Calendar.current.startOfDay(for: Date())
        guard Calendar.current.startOfDay(for: booking.date) >= startOfToday else {
            return nil
        }

        return booking
    }

    private var nextUpcomingBooking: Booking? {
        let now = Date()
        return bookings
            .filter { $0.scheduledDate >= now }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }

    private static func normalizedFeaturedBookingID(from snapshot: ReserveSnapshot) -> String? {
        if let featuredBookingID = snapshot.featuredBookingID,
           snapshot.bookings.contains(where: { $0.id == featuredBookingID }) {
            return featuredBookingID
        }

        return snapshot.bookings
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first?.id
    }

    private static func normalized(_ booking: Booking) -> Booking {
        Booking(
            id: booking.id,
            court: booking.court,
            date: Self.normalizedCalendarDate(booking.date),
            time: booking.time,
            total: booking.total
        )
    }

    private static func normalizedCalendarDate(_ date: Date) -> Date {
        Calendar.current.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: date
        ) ?? date
    }
}

struct ReserveSnapshotStore {
    private let defaults: UserDefaults
    private let storageKey = "reserve.snapshot.v2"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ snapshot: ReserveSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }

    func load() -> ReserveSnapshot? {
        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }

        return try? decoder.decode(ReserveSnapshot.self, from: data)
    }
}
