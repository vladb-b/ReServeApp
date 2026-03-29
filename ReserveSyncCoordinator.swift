import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

protocol ReserveSyncCoordinating {
    func start(initialSnapshot: ReserveSnapshot, onSnapshotReceived: @escaping (ReserveSnapshot) -> Void)
    func broadcast(snapshot: ReserveSnapshot)
    func refresh()
    func availability() -> ReserveSyncAvailability
}

enum ReserveSyncAvailability: Equatable {
    case available
    case unavailable(String)

    var isAvailable: Bool {
        switch self {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }

    var message: String? {
        switch self {
        case .available:
            return nil
        case .unavailable(let message):
            return message
        }
    }
}

final class ReserveSyncCoordinator: NSObject, ReserveSyncCoordinating {
    private var currentSnapshot: ReserveSnapshot?
    private var pendingOutgoingSnapshot: ReserveSnapshot?
    private var onSnapshotReceived: ((ReserveSnapshot) -> Void)?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    #if canImport(WatchConnectivity)
    private var activationRequested = false
    #endif

    override init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        super.init()
    }

    func start(initialSnapshot: ReserveSnapshot, onSnapshotReceived: @escaping (ReserveSnapshot) -> Void) {
        currentSnapshot = initialSnapshot
        pendingOutgoingSnapshot = initialSnapshot
        self.onSnapshotReceived = onSnapshotReceived

        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        session.delegate = self

        ensureSessionActivationIfNeeded(for: session)

        if session.activationState == .activated {
            requestLatestSnapshotIfPossible(from: session)
            flushPendingSnapshotIfPossible(from: session)
        }
        #endif
    }

    func broadcast(snapshot: ReserveSnapshot) {
        currentSnapshot = snapshot
        pendingOutgoingSnapshot = snapshot

        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        ensureSessionActivationIfNeeded(for: session)
        flushPendingSnapshotIfPossible(from: session)
        #endif
    }

    func refresh() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default

        if session.activationState != .activated {
            ensureSessionActivationIfNeeded(for: session)
        }

        guard session.activationState == .activated else {
            return
        }

        #if os(iOS)
        if currentSnapshot != nil {
            pendingOutgoingSnapshot = currentSnapshot
        }
        #endif

        requestLatestSnapshotIfPossible(from: session)
        flushPendingSnapshotIfPossible(from: session)
        #endif
    }

    func availability() -> ReserveSyncAvailability {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else {
            return .unavailable("Watch sync is unavailable on this device.")
        }

        let session = WCSession.default

        #if os(iOS)
        if !session.isPaired {
            return .unavailable("Pair a watch to sync bookings.")
        }

        if !session.isWatchAppInstalled {
            return .unavailable("Install the watch app to sync bookings.")
        }
        #elseif os(watchOS)
        if !session.isCompanionAppInstalled {
            return .unavailable("Run the paired iPhone app to sync this watch.")
        }
        #endif

        return .available
        #else
        return .unavailable("Watch sync is unavailable on this device.")
        #endif
    }

    private func encodedPayload(for snapshot: ReserveSnapshot) -> [String: Any]? {
        guard let data = try? encoder.encode(snapshot) else {
            return nil
        }

        return ["snapshot": data]
    }

    private func decodeSnapshot(from payload: [String: Any]) -> ReserveSnapshot? {
        guard let data = payload["snapshot"] as? Data else {
            return nil
        }

        return try? decoder.decode(ReserveSnapshot.self, from: data)
    }

    private func shouldAccept(_ snapshot: ReserveSnapshot) -> Bool {
        guard let currentSnapshot else {
            return true
        }

        return snapshot.updatedAt > currentSnapshot.updatedAt
    }

    private func stageIncomingSnapshot(_ snapshot: ReserveSnapshot) -> Bool {
        guard shouldAccept(snapshot) else {
            return false
        }

        currentSnapshot = snapshot

        if let pendingOutgoingSnapshot, pendingOutgoingSnapshot.updatedAt <= snapshot.updatedAt {
            self.pendingOutgoingSnapshot = nil
        }

        return true
    }

    #if canImport(WatchConnectivity)
    private func ensureSessionActivationIfNeeded(for session: WCSession) {
        guard WCSession.isSupported() else {
            return
        }

        switch session.activationState {
        case .activated:
            activationRequested = true
        case .notActivated:
            guard !activationRequested else {
                return
            }

            activationRequested = true
            session.activate()
        case .inactive:
            session.activate()
        @unknown default:
            break
        }
    }

    private func canExchangeData(using session: WCSession) -> Bool {
        #if os(iOS)
        return session.isPaired && session.isWatchAppInstalled
        #elseif os(watchOS)
        return session.isCompanionAppInstalled
        #else
        return false
        #endif
    }

    private func flushPendingSnapshotIfPossible(from session: WCSession) {
        guard canExchangeData(using: session),
              session.activationState == .activated,
              let snapshot = pendingOutgoingSnapshot,
              let payload = encodedPayload(for: snapshot) else {
            return
        }

        var queuedDelivery = false

        do {
            try session.updateApplicationContext(payload)
            queuedDelivery = true
        } catch {
            #if DEBUG
            print("Reserve sync updateApplicationContext failed: \(error)")
            #endif
        }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            queuedDelivery = true
        } else {
            session.transferUserInfo(payload)
            queuedDelivery = true
        }

        if queuedDelivery {
            pendingOutgoingSnapshot = nil
        }
    }
    #endif
}

#if canImport(WatchConnectivity)
extension ReserveSyncCoordinator: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        activationRequested = activationState != .notActivated

        guard error == nil else {
            return
        }

        if !session.receivedApplicationContext.isEmpty {
            forwardSnapshot(from: session.receivedApplicationContext)
        }

        #if os(iOS)
        if currentSnapshot != nil {
            pendingOutgoingSnapshot = currentSnapshot
        }
        #endif

        requestLatestSnapshotIfPossible(from: session)
        flushPendingSnapshotIfPossible(from: session)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        forwardSnapshot(from: applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["requestSnapshot"] as? Bool == true, let snapshot = currentSnapshot, let payload = encodedPayload(for: snapshot) {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            return
        }

        forwardSnapshot(from: message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["requestSnapshot"] as? Bool == true, let snapshot = currentSnapshot, let payload = encodedPayload(for: snapshot) {
            replyHandler(payload)
            return
        }

        forwardSnapshot(from: message)
        replyHandler([:])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        forwardSnapshot(from: userInfo)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        #if os(iOS)
        if currentSnapshot != nil {
            pendingOutgoingSnapshot = currentSnapshot
        }
        #endif

        if session.isReachable {
            requestLatestSnapshotIfPossible(from: session)
        }

        flushPendingSnapshotIfPossible(from: session)
    }

    private func forwardSnapshot(from payload: [String: Any]) {
        guard let snapshot = decodeSnapshot(from: payload) else {
            return
        }

        guard stageIncomingSnapshot(snapshot) else {
            return
        }

        onSnapshotReceived?(snapshot)
    }

    private func requestLatestSnapshotIfPossible(from session: WCSession) {
        guard canExchangeData(using: session), session.isReachable else {
            return
        }

        session.sendMessage(["requestSnapshot": true], replyHandler: { [weak self] payload in
            self?.forwardSnapshot(from: payload)
        }, errorHandler: nil)
    }
}
#endif
