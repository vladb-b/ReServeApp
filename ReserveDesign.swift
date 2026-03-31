import SwiftUI

enum ReserveDesign {
    static let background = Color(red: 0.043, green: 0.055, blue: 0.051)
    static let surface = Color(red: 0.078, green: 0.102, blue: 0.09)
    static let mutedText = Color(red: 0.725, green: 0.753, blue: 0.773)
    static let secondaryText = Color(red: 0.294, green: 0.325, blue: 0.341)
    static let lightSurface = Color(red: 0.949, green: 0.953, blue: 0.957)
    static let bookingGreen = Color(red: 0.086, green: 0.2, blue: 0.149)
    static let chipGreen = Color(red: 0.122, green: 0.227, blue: 0.169)
    static let chipMuted = Color(red: 0.102, green: 0.141, blue: 0.125)
    static let action = Color(red: 0.757, green: 0.267, blue: 0.18)
    static let success = Color(red: 0.18, green: 0.49, blue: 0.341)
    static let total = Color(red: 0.557, green: 0.231, blue: 0.2)
    static let star = Color(red: 0.969, green: 0.769, blue: 0.247)

    static let profileImageAssetName = "ProfilePhoto"
    static let courtHeroAssetName = "CourtHero"
}

struct ReserveRemoteImage<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    let placeholder: Placeholder

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            default:
                placeholder
            }
        }
    }
}

extension ReserveDesign {
    enum Watch {
        static let screenPadding: CGFloat = 10
        static let sectionSpacing: CGFloat = 12
        static let itemSpacing: CGFloat = 8
        static let compactSpacing: CGFloat = 4
        static let fieldRadius: CGFloat = 14
        static let cardRadius: CGFloat = 18
        static let largeCardRadius: CGFloat = 20
        static let heroRadius: CGFloat = 22
        static let buttonRadius: CGFloat = 16
        static let borderColor = Color.black.opacity(0.08)
        static let shadowColor = Color.black.opacity(0.18)
        static let successText = Color(red: 0.47, green: 0.86, blue: 0.63)

        static var backgroundGradient: LinearGradient {
            LinearGradient(
                colors: [Color.black, ReserveDesign.background],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var detailHeroGradient: LinearGradient {
            LinearGradient(
                colors: [Color.orange, Color(red: 0.46, green: 0.24, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
