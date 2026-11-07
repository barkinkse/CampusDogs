import SwiftUI

enum CampusPalette {
    static let primary = Color(hex: 0x607E35)
    static let dark = Color(hex: 0x243019)
    static let light = Color(hex: 0xE8F2D2)
    static let cream = Color(hex: 0xFFFDF8)
    static let background = Color(hex: 0xF0F5E9)
    static let border = Color(hex: 0xDCE2CF)
    static let muted = Color(hex: 0x70776B)
    static let warning = Color(hex: 0xBA692E)
}

extension Color {
    init(hex: UInt) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

struct CampusSurfaceCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CampusPalette.cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(CampusPalette.border, lineWidth: 1))
    }
}

struct CampusLoadingView: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        ZStack {
            CampusPalette.background.ignoresSafeArea()
            ProgressView(title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CampusPrimaryButton: View {
    let title: String
    let icon: String?
    var isLoading = false
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.isLoading = isLoading; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading { ProgressView().tint(.white) }
                else if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(CampusPalette.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityHint("Devam etmek için dokunun")
    }
}

struct CampusActionLabel: View {
    let title: String
    let icon: String
    var body: some View {
        Label(title, systemImage: icon)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(.white)
            .background(CampusPalette.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct CampusSectionTitle: View {
    let title: String
    let subtitle: String?
    init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.bold()).foregroundStyle(CampusPalette.dark)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(CampusPalette.muted) }
        }
    }
}

struct CampusHealthBadge: View {
    let status: DogHealthStatus
    var body: some View {
        Label(status.title, systemImage: healthStatusSymbol(status))
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10).padding(.vertical, 7)
            .foregroundStyle(healthStatusColor(status))
            .background(healthStatusColor(status).opacity(0.13), in: Capsule())
    }
}

func careIconAsset(_ key: String) -> String {
    switch key {
    case "recovery": "CareIcon-recovery"
    case "limit_running": "CareIcon-limit-running"
    case "special_diet": "CareIcon-special-diet"
    case "vision_sensitivity": "CareIcon-vision-sensitivity"
    case "hearing_sensitivity": "CareIcon-hearing-sensitivity"
    case "regular_checkup": "CareIcon-regular-checkup"
    case "other": "CareIcon-other"
    default: "CareIcon-other"
    }
}

func healthStatusSymbol(_ status: DogHealthStatus) -> String {
    switch status {
    case .normal: "checkmark.circle.fill"
    case .underObservation: "eye.circle.fill"
    case .underTreatment: "cross.case.fill"
    case .recovering: "heart.circle.fill"
    }
}

func healthStatusColor(_ status: DogHealthStatus) -> Color {
    switch status {
    case .normal: CampusPalette.primary
    case .underObservation: CampusPalette.warning
    case .underTreatment: .red
    case .recovering: .blue
    }
}

func turkishDate(_ date: Date, includeTime: Bool = false) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.dateFormat = includeTime ? "d MMMM yyyy, HH:mm" : "d MMMM yyyy"
    return formatter.string(from: date)
}
