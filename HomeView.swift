import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var bookingManager: BookingManager
    @State private var searchText = ""
    let user = User.sample

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
        NavigationView {
            ZStack {
                ReserveDesign.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        searchField
                        bookingSection
                        nearbySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ReserveDesign.mutedText)

                Text(user.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.957, green: 0.965, blue: 0.969))
            }

            Spacer()

            Image(ReserveDesign.profileImageAssetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
            .frame(width: 76, height: 76)
            .clipShape(Circle())
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(red: 0.49, green: 0.53, blue: 0.56))

            TextField("Search courts", text: $searchText)
                .foregroundColor(ReserveDesign.mutedText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(ReserveDesign.surface)
        .cornerRadius(14)
    }

    private var bookingSection: some View {
        Group {
            if let nextBooking = bookingManager.getNextBooking() {
                VStack(alignment: .leading, spacing: 10) {
                    Text("NEXT BOOKING")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.49, green: 0.53, blue: 0.56))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(nextBooking.court.name) - \(nextBooking.dateBadge)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.957, green: 0.965, blue: 0.969))

                        Text("\(formattedTime(nextBooking.time)) - \(formattedTime(endTime(from: nextBooking.time)))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ReserveDesign.mutedText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ReserveDesign.bookingGreen)
                    .cornerRadius(18)
                }
            }
        }
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEARBY COURTS")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 0.49, green: 0.53, blue: 0.56))

            ForEach(filteredCourts) { court in
                NavigationLink(destination: CourtDetailView(court: court, bookingManager: bookingManager)) {
                    CourtCard(court: court)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func endTime(from startTime: String) -> String {
        let components = startTime.split(separator: ":")
        if let hour = Int(components[0]) {
            return String(format: "%02d:00", hour + 1)
        }

        return startTime
    }

    private func formattedTime(_ time: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let output = DateFormatter()
        output.dateFormat = "HH:mm"

        guard let date = formatter.date(from: time) else {
            return time
        }

        return output.string(from: date)
    }
}

struct CourtCard: View {
    let court: Court

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(court.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.055, green: 0.067, blue: 0.071))

                HStack(spacing: 8) {
                    Image(systemName: "location.circle")
                        .font(.system(size: 12))
                        .foregroundColor(ReserveDesign.secondaryText)

                    Text(court.location)
                    Text("•")
                    Text("\(String(format: "%.1f", court.distance)) km")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ReserveDesign.secondaryText)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(ReserveDesign.star)
                Text(String(format: "%.1f", court.rating))
                    .foregroundColor(Color(red: 0.055, green: 0.067, blue: 0.071))
            }
            .font(.system(size: 16, weight: .semibold))
        }
        .padding(18)
        .background(ReserveDesign.lightSurface)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(BookingManager())
    }
}
