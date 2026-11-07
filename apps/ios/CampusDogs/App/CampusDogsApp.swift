import SwiftUI
import UIKit

@MainActor
final class AppHomeNavigator: ObservableObject {
    @Published private(set) var resetID = UUID()
    func returnHome() { resetID = UUID() }
}

private struct HomeToolbarModifier: ViewModifier {
    @EnvironmentObject private var navigator: AppHomeNavigator
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { navigator.returnHome() } label: { Image(systemName: "house.fill") }
                    .accessibilityLabel("Ana sayfaya dön")
            }
        }
    }
}

extension View {
    func appHomeToolbar() -> some View { modifier(HomeToolbarModifier()) }
}

@main struct CampusDogsApp: App {
    init() {
        let backButton = UIBarButtonItemAppearance(style: .plain)
        backButton.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButton.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButton.normal.titlePositionAdjustment = UIOffset(horizontal: -1_000, vertical: 0)
        let navigationBar = UINavigationBarAppearance()
        navigationBar.configureWithDefaultBackground()
        navigationBar.backButtonAppearance = backButton
        UINavigationBar.appearance().standardAppearance = navigationBar
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBar
        UINavigationBar.appearance().compactAppearance = navigationBar
    }
    var body: some Scene { WindowGroup { if SupabaseConfiguration.client == nil { MemberConfigurationView() } else { RootNavigationView() } } }
}

struct MemberConfigurationView: View {
    var body: some View { ContentUnavailableView("Yapılandırma gerekli", systemImage: "exclamationmark.triangle", description: Text("Kampüs verilerine bağlanmak için yerel Supabase yapılandırması eklenmelidir.")) }
}

struct RootNavigationView: View {
    @StateObject private var navigator = AppHomeNavigator()
    var body: some View {
        NavigationStack {
            HomeView()
        }
        .id(navigator.resetID)
        .environmentObject(navigator)
        .tint(CampusPalette.primary)
    }
}
