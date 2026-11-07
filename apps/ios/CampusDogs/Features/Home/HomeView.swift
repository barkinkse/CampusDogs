import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)], spacing: 13) {
                    NavigationLink { DogsView() } label: { HomeTile(title: "Köpekler", icon: "pawprint.fill", tint: CampusPalette.primary) }
                    NavigationLink { CampusMapView() } label: { HomeTile(title: "Harita", icon: "map.fill", tint: CampusPalette.warning) }
                    NavigationLink { BluetoothScanView() } label: { HomeTile(title: "Bluetooth", icon: "dot.radiowaves.left.and.right", tint: .blue) }
                    NavigationLink { AnnouncementsView() } label: { HomeTile(title: "Duyurular", icon: "megaphone.fill", tint: CampusPalette.primary) }
                }
            }.padding(20)
        }
        .background(CampusPalette.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .appHomeToolbar()
    }

    private var hero: some View {
        VStack(spacing: 9) {
            Image(systemName: "pawprint.fill").font(.system(size: 42, weight: .bold)).foregroundStyle(CampusPalette.primary).frame(width: 86, height: 86).background(CampusPalette.light, in: Circle())
            Text("Kampüs\nKöpekleri").font(.system(size: 30, weight: .bold, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(CampusPalette.dark)
            Text("Onları tanı, ihtiyaçlarını öğren.").font(.subheadline).foregroundStyle(CampusPalette.muted)
        }.frame(maxWidth: .infinity).padding(.top, 18)
    }

}

private struct HomeTile: View {
    let title: String; let icon: String; let tint: Color
    var body: some View { VStack(alignment: .leading, spacing: 20) { Image(systemName: icon).font(.title2.weight(.bold)).foregroundStyle(tint).frame(width: 48, height: 48).background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 15)); Text(title).font(.headline).foregroundStyle(CampusPalette.dark) }.frame(maxWidth: .infinity, minHeight: 132, alignment: .leading).padding(16).background(CampusPalette.cream, in: RoundedRectangle(cornerRadius: 21, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).stroke(CampusPalette.border, lineWidth: 1)) }
}
