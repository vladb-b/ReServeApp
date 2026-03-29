import SwiftUI

struct ContentView: View {
    @State private var path: [WatchRoute] = []

    var body: some View {
        WatchDashboardView(path: $path)
    }
}

private struct WatchDashboardView: View {
    @EnvironmentObject private var bookingManager: BookingManager
    @Binding var path: [WatchRoute]

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                let compact = proxy.size.width < 180
                let syncUnavailableMessage = watchSyncUnavailableMessage
                let displayBooking = nextVisibleBooking

                ScrollView {
                    VStack(alignment: .leading, spacing: compact ? 10 : ReserveDesign.Watch.sectionSpacing) {
                        header(compact: compact)

                        if let syncUnavailableMessage {
                            WatchUnavailableCard(message: syncUnavailableMessage, compact: compact)
                        } else if let booking = displayBooking {
                            WatchHeroCard(booking: booking, compact: compact)
                        } else {
                            WatchEmptyCard(compact: compact)
                        }

                        NavigationLink(value: WatchRoute.search) {
                            WatchSearchPromptCard(compact: compact)
                        }
                        .buttonStyle(.plain)

                        WatchSectionTitle(title: "Nearby Courts")

                        ForEach(bookingManager.courts) { court in
                            NavigationLink(value: WatchRoute.court(court)) {
                                WatchCourtCard(court: court, compact: compact)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, compact ? 8 : ReserveDesign.Watch.screenPadding)
                    .padding(.vertical, compact ? 6 : ReserveDesign.Watch.itemSpacing)
                }
                .focusable(true)
            }
            .watchNavigationBackground()
            .navigationDestination(for: WatchRoute.self) { route in
                switch route {
                case .search:
                    WatchCourtSearchView()
                case .court(let court):
                    WatchCourtDetailView(court: court, path: $path)
                }
            }
        }
    }

    private var watchSyncUnavailableMessage: String? {
        if case .unavailable(let message) = bookingManager.syncStatus {
            return message
        }

        return nil
    }

    private var nextVisibleBooking: Booking? {
        if let nextBooking = bookingManager.getNextBooking() {
            return nextBooking
        }

        let startOfToday = Calendar.current.startOfDay(for: Date())

        return bookingManager.bookings
            .filter { Calendar.current.startOfDay(for: $0.date) >= startOfToday }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: ReserveDesign.Watch.compactSpacing) {
                Text("Welcome back")
                    .font(.system(size: compact ? 12 : 13, weight: .medium))
                    .foregroundStyle(ReserveDesign.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(User.sample.name)
                    .font(.system(size: compact ? 22 : 24, weight: .bold, design: .rounded))
                    .foregroundStyle(ReserveDesign.lightSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .layoutPriority(1)

            Spacer()

            ReserveRemoteImage(url: ReserveDesign.profileImageURL) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ReserveDesign.bookingGreen, ReserveDesign.surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    )
            }
            .frame(width: compact ? 36 : 42, height: compact ? 36 : 42)
            .clipShape(Circle())
        }
    }
}

private struct WatchCourtSearchView: View {
    @EnvironmentObject private var bookingManager: BookingManager
    @State private var searchText = ""

    private var filteredCourts: [Court] {
        if searchText.isEmpty {
            return bookingManager.courts
        }

        return bookingManager.courts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 180

            ScrollView {
                VStack(alignment: .leading, spacing: compact ? 6 : ReserveDesign.Watch.itemSpacing) {
                    ForEach(filteredCourts) { court in
                        NavigationLink(value: WatchRoute.court(court)) {
                            WatchCourtCard(court: court, compact: compact)
                        }
                        .buttonStyle(.plain)
                    }

                    if filteredCourts.isEmpty {
                        WatchDarkCard(cornerRadius: ReserveDesign.Watch.fieldRadius) {
                            Text("No courts match that search.")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(ReserveDesign.mutedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, compact ? 8 : ReserveDesign.Watch.screenPadding)
                .padding(.vertical, compact ? 6 : ReserveDesign.Watch.itemSpacing)
            }
            .focusable(true)
        }
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Search courts")
        .watchNavigationBackground()
    }
}

private struct WatchSearchPromptCard: View {
    var compact = false

    var body: some View {
        WatchDarkCard(
            cornerRadius: ReserveDesign.Watch.fieldRadius,
            padding: EdgeInsets(top: compact ? 10 : 10, leading: compact ? 10 : 12, bottom: compact ? 10 : 10, trailing: compact ? 10 : 12)
        ) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: compact ? 11 : 12, weight: .medium))
                    .foregroundStyle(ReserveDesign.secondaryText)

                Text("Search courts")
                    .font(.system(size: compact ? 13 : 14))
                    .foregroundStyle(ReserveDesign.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: compact ? 10 : 11, weight: .semibold))
                    .foregroundStyle(ReserveDesign.mutedText)
            }
        }
    }
}

private struct WatchHeroCard: View {
    let booking: Booking
    var compact = false

    var body: some View {
        WatchBookingCard {
            VStack(alignment: .leading, spacing: compact ? 7 : 6) {
                WatchSectionTitle(title: "Next Booking")

                Text(booking.court.name)
                    .font(.system(size: compact ? 15 : 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ReserveDesign.lightSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                HStack(spacing: 6) {
                    WatchDayBadge(
                        text: watchCompactDayBadge(for: booking.date),
                        active: true
                    )

                    Text("\(watchFormattedTime(booking.time)) - \(watchFormattedTime(watchEndTime(from: booking.time)))")
                        .font(.system(size: compact ? 11 : 12, weight: .medium))
                        .foregroundStyle(ReserveDesign.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}

private struct WatchEmptyCard: View {
    var compact = false

    var body: some View {
        WatchBookingCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Nothing booked")
                    .font(.system(size: compact ? 15 : 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ReserveDesign.lightSurface)

                Text("Open Courts and lock in your next session.")
                    .font(.system(size: compact ? 12 : 13))
                    .foregroundStyle(ReserveDesign.mutedText)
                    .lineLimit(2)
            }
        }
    }
}

private struct WatchUnavailableCard: View {
    let message: String
    var compact = false

    var body: some View {
        WatchDarkCard(
            cornerRadius: ReserveDesign.Watch.heroRadius,
            padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        ) {
            VStack(alignment: .leading, spacing: 6) {
                WatchSectionTitle(title: "Watch Mirror")

                Text("Pair to Sync")
                    .font(.system(size: compact ? 15 : 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ReserveDesign.lightSurface)

                Text(message)
                    .font(.system(size: compact ? 11 : 12, weight: .medium))
                    .foregroundStyle(ReserveDesign.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct WatchCourtCard: View {
    let court: Court
    var compact = false

    var body: some View {
        WatchLightCard {
            VStack(alignment: .leading, spacing: compact ? 6 : 8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(court.name)
                            .font(.system(size: compact ? 13 : 14, weight: .bold))
                            .foregroundStyle(ReserveDesign.background)
                            .lineLimit(1)

                        Text("\(court.location) • \(court.distance.formatted(.number.precision(.fractionLength(1)))) km")
                            .font(.system(size: compact ? 10 : 11, weight: .medium))
                            .foregroundStyle(ReserveDesign.secondaryText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 8)

                    WatchRatingView(rating: court.rating, compact: compact)
                }

                HStack(alignment: .center, spacing: 6) {
                    WatchTag(
                        text: court.sport,
                        fill: ReserveDesign.chipGreen,
                        foreground: ReserveDesign.lightSurface,
                        compact: compact
                    )

                    Spacer(minLength: 6)

                    Text(compact ? "€\(Int(court.pricePerHour))/h" : "€\(Int(court.pricePerHour))/hr")
                        .font(.system(size: compact ? 10 : 11, weight: .semibold))
                        .foregroundStyle(ReserveDesign.secondaryText)
                        .lineLimit(1)
                }
            }
        }
    }
}

private struct WatchCourtDetailView: View {
    @EnvironmentObject private var bookingManager: BookingManager
    @Binding var path: [WatchRoute]

    let court: Court
    @State private var selectedDate: Date
    @State private var selectedTime: String?
    @State private var confirmedBooking: Booking?

    init(court: Court, path: Binding<[WatchRoute]>) {
        self.court = court
        _path = path
        _selectedDate = State(initialValue: court.suggestedBookingDate())
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 180
            let timeSlotColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: compact ? 2 : 3)
            let bookingEnabled = bookingManager.canBookFromCurrentDevice

            ScrollView {
                VStack(alignment: .leading, spacing: compact ? 10 : ReserveDesign.Watch.sectionSpacing) {
                    heroImage(compact: compact)
                    titleBlock(compact: compact)

                    HStack(spacing: 6) {
                        WatchTag(
                            text: court.sport,
                            fill: ReserveDesign.chipGreen,
                            foreground: ReserveDesign.lightSurface,
                            compact: compact
                        )
                        WatchTag(
                            text: court.type,
                            fill: ReserveDesign.chipMuted,
                            foreground: ReserveDesign.mutedText,
                            compact: compact
                        )
                    }

                    HStack(spacing: 0) {
                        Text("€\(Int(court.pricePerHour))")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(ReserveDesign.lightSurface)
                        Text("/hour")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(ReserveDesign.mutedText)
                    }

                    VStack(alignment: .leading, spacing: compact ? 6 : ReserveDesign.Watch.itemSpacing) {
                        WatchSectionTitle(title: "Select Day")

                        ViewThatFits {
                            HStack(spacing: 8) {
                                dayChoiceButtons(compact: compact)
                            }

                            VStack(spacing: 8) {
                                dayChoiceButtons(compact: compact)
                            }
                        }

                        Text(watchPickerDate(selectedDate))
                            .font(.system(size: compact ? 12 : 13, weight: .medium))
                            .foregroundStyle(ReserveDesign.mutedText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    VStack(alignment: .leading, spacing: compact ? 6 : ReserveDesign.Watch.itemSpacing) {
                        WatchSectionTitle(title: "Select Time")

                        LazyVGrid(columns: timeSlotColumns, spacing: 8) {
                            ForEach(displayedTimes, id: \.time) { item in
                                WatchTimeSlotButton(
                                    time: item.time,
                                    isSelected: selectedTime == item.time,
                                    isAvailable: item.isAvailable,
                                    compact: compact
                                ) {
                                    selectedTime = item.time
                                }
                            }
                        }
                    }

                    if let selectedTime {
                        WatchDarkCard(
                            cornerRadius: ReserveDesign.Watch.fieldRadius,
                            padding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                WatchSectionTitle(title: "Selected Slot")

                                Text("\(watchDateSummary(selectedDate)) • \(watchFormattedTime(selectedTime))")
                                    .font(.system(size: compact ? 12 : 13, weight: .semibold))
                                    .foregroundStyle(ReserveDesign.lightSurface)
                                    .lineLimit(2)
                            }
                        }
                    }

                    WatchPrimaryButton(
                        title: bookingEnabled ? (selectedTime == nil ? "Choose a Time" : "Book Now") : "Open on iPhone",
                        isEnabled: bookingEnabled && selectedTime != nil,
                        compact: compact,
                        action: bookSelectedSlot
                    )
                }
                .padding(.horizontal, compact ? 8 : ReserveDesign.Watch.screenPadding)
                .padding(.vertical, compact ? 6 : ReserveDesign.Watch.itemSpacing)
            }
            .focusable(true)
        }
        .navigationTitle(court.name)
        .navigationBarTitleDisplayMode(.inline)
        .watchNavigationBackground()
        .fullScreenCover(item: $confirmedBooking) { booking in
            WatchBookingConfirmationView(booking: booking) {
                confirmedBooking = nil
                DispatchQueue.main.async {
                    path.removeAll()
                }
            }
        }
    }

    @ViewBuilder
    private func dayChoiceButtons(compact: Bool) -> some View {
        WatchDayChoiceButton(
            title: "Today",
            isSelected: Calendar.current.isDateInToday(selectedDate),
            compact: compact
        ) {
            selectDate(Calendar.current.startOfDay(for: Date()))
        }

        WatchDayChoiceButton(
            title: "Tomorrow",
            isSelected: Calendar.current.isDateInTomorrow(selectedDate),
            compact: compact
        ) {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            selectDate(Calendar.current.startOfDay(for: tomorrow))
        }
    }

    private func titleBlock(compact: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(court.name)
                    .font(.system(size: compact ? 18 : 20, weight: .bold, design: .rounded))
                    .foregroundStyle(ReserveDesign.lightSurface)
                    .lineLimit(2)

                Text(court.location)
                    .font(.system(size: compact ? 11 : 12))
                    .foregroundStyle(ReserveDesign.mutedText)
                    .lineLimit(2)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            WatchRatingView(
                rating: court.rating,
                compact: compact,
                valueColor: ReserveDesign.lightSurface
            )
        }
    }

    private func heroImage(compact: Bool) -> some View {
        ReserveRemoteImage(url: ReserveDesign.courtHeroURL) {
            Rectangle()
                .fill(ReserveDesign.Watch.detailHeroGradient)
        }
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 80 : 92)
        .clipShape(
            RoundedRectangle(cornerRadius: ReserveDesign.Watch.heroRadius, style: .continuous)
        )
    }

    private var displayedTimes: [(time: String, isAvailable: Bool)] {
        let valid = Set(court.availableTimes(on: selectedDate))
        return court.availableTimes.map { ($0, valid.contains($0)) }
    }

    private func selectDate(_ date: Date) {
        selectedDate = date
        selectedTime = nil
    }

    private func bookSelectedSlot() {
        guard bookingManager.canBookFromCurrentDevice, let selectedTime else {
            return
        }

        confirmedBooking = bookingManager.addBooking(court: court, date: selectedDate, time: selectedTime)
    }
}

private enum WatchRoute: Hashable {
    case search
    case court(Court)
}

private struct WatchBookingConfirmationView: View {
    let booking: Booking
    let done: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 180

            ZStack {
                ReserveDesign.lightSurface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: compact ? 10 : ReserveDesign.Watch.sectionSpacing) {
                        Circle()
                            .fill(ReserveDesign.success)
                            .frame(width: compact ? 48 : 56, height: compact ? 48 : 56)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: compact ? 21 : 24, weight: .bold))
                                    .foregroundStyle(.white)
                            )

                        VStack(spacing: 4) {
                            Text("Booking Confirmed!")
                                .font(.system(size: compact ? 16 : 18, weight: .bold, design: .rounded))
                                .foregroundStyle(ReserveDesign.background)
                                .multilineTextAlignment(.center)

                            Text("Your court is reserved")
                                .font(.system(size: compact ? 11 : 12, weight: .medium))
                                .foregroundStyle(ReserveDesign.secondaryText)
                        }

                        WatchConfirmationSummary(booking: booking)

                        WatchPrimaryButton(title: "Done", compact: compact, action: done)
                    }
                    .padding(compact ? 12 : 16)
                    .frame(maxWidth: .infinity)
                }
                .focusable(true)
            }
        }
    }
}

private struct WatchConfirmationSummary: View {
    let booking: Booking

    var body: some View {
        WatchWhiteCard(
            cornerRadius: ReserveDesign.Watch.cardRadius,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        ) {
            VStack(spacing: 12) {
                WatchConfirmationRow(label: "Court", value: booking.court.name)
                WatchConfirmationRow(label: "Date", value: booking.formattedDate)
                WatchConfirmationRow(label: "Time", value: watchFormattedTime(booking.time))

                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 1)

                WatchConfirmationRow(
                    label: "Total",
                    value: "€\(String(format: "%.2f", booking.total))",
                    emphasize: true
                )
            }
        }
    }
}

private struct WatchConfirmationRow: View {
    let label: String
    let value: String
    var emphasize = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption.weight(emphasize ? .semibold : .medium))
                .foregroundStyle(emphasize ? ReserveDesign.background : ReserveDesign.secondaryText)

            Spacer(minLength: 8)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(emphasize ? ReserveDesign.total : ReserveDesign.background)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
}

private struct WatchSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(ReserveDesign.secondaryText)
            .textCase(.uppercase)
    }
}

private struct WatchTag: View {
    let text: String
    let fill: Color
    let foreground: Color
    var compact = false

    var body: some View {
        Text(text)
            .font(.system(size: compact ? 10 : 11, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 5 : 6)
            .background(fill)
            .clipShape(Capsule())
    }
}

private struct WatchDayBadge: View {
    let text: String
    var active = false

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(active ? Color.white : ReserveDesign.mutedText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(active ? ReserveDesign.chipGreen : ReserveDesign.chipMuted)
            .clipShape(Capsule())
            .lineLimit(1)
    }
}

private struct WatchRatingView: View {
    let rating: Double
    var compact = false
    var valueColor: Color = ReserveDesign.background

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: compact ? 10 : 11, weight: .bold))
                .foregroundStyle(ReserveDesign.star)

            Text(String(format: "%.1f", rating))
                .font(.system(size: compact ? 11 : 12, weight: .bold))
                .foregroundStyle(valueColor)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct WatchPrimaryButton: View {
    let title: String
    var isEnabled = true
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: compact ? 13 : 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 9 : 10)
                .background(isEnabled ? ReserveDesign.action : Color.gray.opacity(0.35))
                .clipShape(
                    RoundedRectangle(cornerRadius: ReserveDesign.Watch.buttonRadius, style: .continuous)
                )
                .contentShape(
                    RoundedRectangle(cornerRadius: ReserveDesign.Watch.buttonRadius, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct WatchDayChoiceButton: View {
    let title: String
    let isSelected: Bool
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer(minLength: 0)
                WatchDayBadge(
                    text: title.uppercased(),
                    active: isSelected
                )
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 3 : 4)
        }
        .buttonStyle(.plain)
    }
}

private struct WatchTimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let isAvailable: Bool
    var compact = false
    let action: () -> Void

    var body: some View {
        Button {
            guard isAvailable else {
                return
            }

            action()
        } label: {
            Text(time)
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 9 : 10)
                .background(backgroundColor)
                .clipShape(
                    RoundedRectangle(cornerRadius: ReserveDesign.Watch.fieldRadius, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(red: 0.18, green: 0.325, blue: 0.224)
        }

        return ReserveDesign.surface.opacity(isAvailable ? 1 : 0.5)
    }

    private var textColor: Color {
        if isAvailable {
            return ReserveDesign.lightSurface
        }

        return ReserveDesign.secondaryText
    }
}

private struct WatchBookingCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: ReserveDesign.Watch.heroRadius, style: .continuous)
                    .fill(ReserveDesign.bookingGreen)
            )
    }
}

private struct WatchDarkCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let content: Content

    init(
        cornerRadius: CGFloat,
        padding: EdgeInsets = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(ReserveDesign.surface)
            )
    }
}

private struct WatchLightCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: ReserveDesign.Watch.largeCardRadius, style: .continuous)
                    .fill(ReserveDesign.lightSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ReserveDesign.Watch.largeCardRadius, style: .continuous)
                    .stroke(ReserveDesign.Watch.borderColor, lineWidth: 1)
            )
            .shadow(color: ReserveDesign.Watch.shadowColor, radius: 8, x: 0, y: 4)
            .contentShape(
                RoundedRectangle(cornerRadius: ReserveDesign.Watch.largeCardRadius, style: .continuous)
            )
    }
}

private struct WatchWhiteCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let content: Content

    init(
        cornerRadius: CGFloat,
        padding: EdgeInsets,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

private extension View {
    func watchNavigationBackground() -> some View {
        containerBackground(ReserveDesign.Watch.backgroundGradient, for: .navigation)
    }
}

private func watchFormattedTime(_ time: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"

    let output = DateFormatter()
    output.dateFormat = "h:mm a"

    guard let date = formatter.date(from: time) else {
        return time
    }

    return output.string(from: date)
}

private func watchEndTime(from startTime: String) -> String {
    let parts = startTime.split(separator: ":")

    guard let hour = Int(parts.first ?? "") else {
        return startTime
    }

    return String(format: "%02d:00", hour + 1)
}

private func watchPickerDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, MMM d"
    return formatter.string(from: date)
}

private func watchDateSummary(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
        return "Today"
    }

    if Calendar.current.isDateInTomorrow(date) {
        return "Tomorrow"
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "EEE d MMM"
    return formatter.string(from: date)
}

private func watchCompactDayBadge(for date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
        return "TODAY"
    }

    if Calendar.current.isDateInTomorrow(date) {
        return "TOMORROW"
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "EEE d"
    return formatter.string(from: date).uppercased()
}

struct WatchContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BookingManager())
    }
}
