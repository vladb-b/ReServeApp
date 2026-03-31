import SwiftUI

struct CourtDetailView: View {
    let court: Court
    @ObservedObject var bookingManager: BookingManager
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedDate: Date
    @State private var selectedTime: String?
    @State private var confirmedBooking: Booking?

    init(court: Court, bookingManager: BookingManager) {
        self.court = court
        self.bookingManager = bookingManager
        _selectedDate = State(initialValue: court.suggestedBookingDate())
    }

    var body: some View {
        ZStack {
            ReserveDesign.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage

                    VStack(alignment: .leading, spacing: 20) {
                        titleRow
                        Text(court.location)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ReserveDesign.mutedText)

                        HStack(spacing: 8) {
                            DetailChip(text: court.sport, fill: ReserveDesign.chipGreen, foreground: .white)
                            DetailChip(text: court.type, fill: ReserveDesign.chipMuted, foreground: ReserveDesign.mutedText)
                        }

                        Text("€\(Int(court.pricePerHour))\(Text("/hour").fontWeight(.medium))")
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.957, green: 0.965, blue: 0.969))

                        daySection
                        timeSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 110)
                }
            }

            VStack {
                Spacer()

                Button(action: bookSelectedSlot) {
                    Text("Book Now")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedTime == nil ? Color.gray.opacity(0.4) : ReserveDesign.action)
                        .cornerRadius(24)
                }
                .disabled(selectedTime == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $confirmedBooking) { booking in
            BookingConfirmationView(booking: booking) {
                confirmedBooking = nil
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private var heroImage: some View {
        ZStack(alignment: .topLeading) {
            Image(ReserveDesign.courtHeroAssetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
            .frame(height: 160)
            .clipped()

            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Circle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            .padding(.leading, 16)
            .padding(.top, 24)
        }
    }

    private var titleRow: some View {
        HStack(alignment: .top) {
            Text(court.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 0.957, green: 0.965, blue: 0.969))

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(ReserveDesign.star)
                Text(String(format: "%.1f", court.rating))
                    .foregroundColor(Color(red: 0.957, green: 0.965, blue: 0.969))
            }
            .font(.system(size: 16, weight: .semibold))
            .padding(.top, 8)
        }
    }

    private var daySection: some View {
        HStack(alignment: .center) {
            Text("SELECT DAY")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ReserveDesign.mutedText)

            Spacer()

            HStack(spacing: 8) {
                Text(formattedDate(selectedDate))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.957, green: 0.965, blue: 0.969))

                Text(dayBadgeText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.18, green: 0.325, blue: 0.224))
                    .cornerRadius(4)

                Menu {
                    Button("Today") {
                        selectedDate = Calendar.current.startOfDay(for: Date())
                        selectedTime = nil
                    }

                    Button("Tomorrow") {
                        selectedDate = Calendar.current.startOfDay(
                            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        )
                        selectedTime = nil
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .foregroundColor(ReserveDesign.mutedText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ReserveDesign.surface)
            .cornerRadius(14)
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SELECT TIME")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ReserveDesign.mutedText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(displayedTimes, id: \.time) { item in
                    TimeSlotButton(
                        time: item.time,
                        isSelected: selectedTime == item.time,
                        isAvailable: item.isAvailable
                    ) {
                        selectedTime = item.time
                    }
                }
            }
        }
    }

    private var displayedTimes: [(time: String, isAvailable: Bool)] {
        let valid = Set(availableTimes)
        return court.availableTimes.map { ($0, valid.contains($0)) }
    }

    private var availableTimes: [String] {
        court.availableTimes(on: selectedDate)
    }

    private var dayBadgeText: String {
        Calendar.current.isDateInToday(selectedDate) ? "TODAY" : "TOMORROW"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func bookSelectedSlot() {
        guard let selectedTime else {
            return
        }

        confirmedBooking = bookingManager.addBooking(court: court, date: selectedDate, time: selectedTime)
    }
}

struct DetailChip: View {
    let text: String
    let fill: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(fill)
            .cornerRadius(999)
    }
}

struct TimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let isAvailable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isAvailable {
                action()
            }
        }) {
            Text(time)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(14)
        }
        .disabled(!isAvailable)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(red: 0.18, green: 0.325, blue: 0.224)
        }

        return ReserveDesign.surface.opacity(isAvailable ? 1 : 0.5)
    }

    private var textColor: Color {
        isAvailable ? Color(red: 0.957, green: 0.965, blue: 0.969) : Color(red: 0.49, green: 0.53, blue: 0.56)
    }
}

struct CourtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CourtDetailView(court: Court.sampleCourts[0], bookingManager: BookingManager())
    }
}
