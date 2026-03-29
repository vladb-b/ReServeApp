import SwiftUI

struct BookingConfirmationView: View {
    let booking: Booking
    let onDone: () -> Void

    var body: some View {
        ZStack {
            ReserveDesign.lightSurface.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Circle()
                    .fill(ReserveDesign.success)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundColor(.white)
                    )

                VStack(spacing: 8) {
                    Text("Booking Confirmed!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.055, green: 0.067, blue: 0.071))

                    Text("Your court is reserved")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ReserveDesign.secondaryText)
                }
                .padding(.top, 24)

                VStack(spacing: 16) {
                    BookingDetailRow(label: "Court", value: booking.court.name, emphasize: false)
                    BookingDetailRow(label: "Date", value: booking.formattedDate, emphasize: false)
                    BookingDetailRow(label: "Time", value: formattedTime(booking.time), emphasize: false)

                    Divider()

                    BookingDetailRow(
                        label: "Total",
                        value: "€\(String(format: "%.2f", booking.total))",
                        emphasize: true
                    )
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
                .padding(.top, 40)
                .padding(.horizontal, 20)

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ReserveDesign.action)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)

                Spacer()
            }
            .padding(.vertical, 40)
        }
    }

    private func formattedTime(_ time: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let output = DateFormatter()
        output.dateFormat = "h:mm a"

        guard let date = formatter.date(from: time) else {
            return time
        }

        return output.string(from: date)
    }
}

struct BookingDetailRow: View {
    let label: String
    let value: String
    let emphasize: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: emphasize ? .semibold : .medium))
                .foregroundColor(emphasize ? Color(red: 0.055, green: 0.067, blue: 0.071) : ReserveDesign.secondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(emphasize ? ReserveDesign.total : Color(red: 0.055, green: 0.067, blue: 0.071))
        }
    }
}

struct BookingConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        BookingConfirmationView(
            booking: Booking(
                id: "1",
                court: Court.sampleCourts[0],
                date: Date(),
                time: "11:00",
                total: 15.00
            ),
            onDone: {}
        )
    }
}
