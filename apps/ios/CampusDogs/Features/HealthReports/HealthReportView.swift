import SwiftUI

struct HealthReportView: View {
    let preselectedDog: Dog?
    @State private var dogs: [Dog] = []
    @State private var selectedDogID: UUID?
    @State private var category = "Topallama"
    @State private var description = ""
    @State private var severity = "medium"
    @State private var isLoadingDogs = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var submitted = false
    @FocusState private var isDescriptionFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(preselectedDog: Dog? = nil) { self.preselectedDog = preselectedDog }

    var body: some View {
        Group {
            if submitted { successView }
            else if isLoadingDogs { CampusLoadingView("Köpekler yükleniyor…") }
            else if let errorMessage, dogs.isEmpty { ContentUnavailableView("Köpekler yüklenemedi", systemImage: "wifi.exclamationmark", description: Text(errorMessage)) }
            else if dogs.isEmpty { ContentUnavailableView("Bildirim gönderilemedi", systemImage: "pawprint", description: Text("Seçilebilecek aktif köpek yok.")) }
            else { form }
        }
        .background(CampusPalette.background.ignoresSafeArea())
        .navigationTitle("Gözlem Bildir")
        .navigationBarTitleDisplayMode(.inline)
        .appHomeToolbar()
        .task { await loadDogs() }
    }

    private var form: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            CampusSurfaceCard { VStack(alignment: .leading, spacing: 8) { Label(selectedDog?.name ?? "Köpek seçin", systemImage: "pawprint.fill").font(.headline).foregroundStyle(CampusPalette.dark); Text("Gözleminizi anonim olarak iletin. Acil durumlarda doğrudan yetkililere haber verin.").font(.subheadline).foregroundStyle(CampusPalette.muted) } }
            CampusSectionTitle("Bildirim ayrıntıları", subtitle: "Yıldızlı alanlar zorunludur.")
            CampusSurfaceCard { VStack(alignment: .leading, spacing: 12) { Text("Köpek *").font(.caption.weight(.bold)); Picker("Köpek", selection: $selectedDogID) { ForEach(dogs) { Text($0.name).tag(Optional($0.id)) } }.pickerStyle(.menu); Divider(); Text("Sorun türü *").font(.caption.weight(.bold)); Picker("Sorun türü", selection: $category) { ForEach(["Topallama", "Yaralanma", "Halsizlik", "Davranış Değişikliği", "Diğer"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu); Divider(); HStack { Text("Açıklama *").font(.caption.weight(.bold)); Spacer(); Text("\(description.count)/4000").font(.caption).foregroundStyle(CampusPalette.muted) }; TextEditor(text: $description).focused($isDescriptionFocused).font(.body).foregroundStyle(CampusPalette.dark).tint(CampusPalette.primary).scrollContentBackground(.hidden).frame(minHeight: 125).padding(8).background(CampusPalette.background, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(CampusPalette.border, lineWidth: 1)).onChange(of: description) { _, value in if value.count > 4000 { description = String(value.prefix(4000)) } }; Text("Önem derecesi").font(.caption.weight(.bold)); severitySelector } }
            CampusSurfaceCard { Label("Adınız, üyeliğiniz veya cihaz konumunuz kaydedilmez. Fotoğraf ekleme bu sürümde desteklenmemektedir.", systemImage: "person.crop.circle.badge.checkmark").font(.footnote).foregroundStyle(CampusPalette.muted) }
            if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.red) }
            CampusPrimaryButton(isSubmitting ? "Gönderiliyor…" : "Bildirimi Gönder", icon: "paperplane.fill", isLoading: isSubmitting) { Task { await submit() } }.disabled(!canSubmit)
        }.padding(20) }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(TapGesture().onEnded { isDescriptionFocused = false })
        .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Bitti") { isDescriptionFocused = false } } }
    }

    private var successView: some View { VStack(spacing: 18) { Image(systemName: "checkmark").font(.system(size: 38, weight: .bold)).foregroundStyle(.white).frame(width: 84, height: 84).background(CampusPalette.primary, in: Circle()); Text("Bildiriminiz iletildi!").font(.title2.bold()).foregroundStyle(CampusPalette.dark); Text("Teşekkür ederiz. Bildiriminiz anonim olarak kaydedildi.").multilineTextAlignment(.center).foregroundStyle(CampusPalette.muted); CampusPrimaryButton("Ana ekrana dön", icon: "house.fill") { dismiss() } }.padding(30).frame(maxWidth: .infinity, maxHeight: .infinity) }
    private var severitySelector: some View { HStack(spacing: 8) { ForEach([(value: "low", title: "Düşük"), (value: "medium", title: "Orta"), (value: "high", title: "Yüksek")], id: \.value) { option in let isSelected = severity == option.value; Button { severity = option.value } label: { Text(option.title).font(.subheadline.weight(.semibold)).foregroundStyle(isSelected ? .white : CampusPalette.dark).frame(maxWidth: .infinity, minHeight: 44).background(isSelected ? CampusPalette.primary : CampusPalette.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(isSelected ? CampusPalette.primary : CampusPalette.border, lineWidth: isSelected ? 2 : 1)) }.buttonStyle(.plain).accessibilityAddTraits(isSelected ? .isSelected : []) } } }
    private var selectedDog: Dog? { dogs.first { $0.id == selectedDogID } }
    private var canSubmit: Bool { !isSubmitting && selectedDogID != nil && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private func loadDogs() async { isLoadingDogs = true; errorMessage = nil; defer { isLoadingDogs = false }; guard let client = SupabaseConfiguration.client else { errorMessage = "Sunucu bağlantısı yapılandırılmadı."; return }; do { dogs = try await SupabaseDogRepository(client: client).activeDogs(); selectedDogID = dogs.contains { $0.id == preselectedDog?.id } ? preselectedDog?.id : dogs.first?.id } catch { errorMessage = "Köpekler alınamadı. Lütfen tekrar deneyin." } }
    private func submit() async { guard let selectedDogID, let client = SupabaseConfiguration.client, canSubmit else { return }; isSubmitting = true; errorMessage = nil; defer { isSubmitting = false }; do { try await SupabaseMemberReportRepository(client: client).submit(MemberReportInsert(dogId: selectedDogID, category: category, description: description.trimmingCharacters(in: .whitespacesAndNewlines), severity: severity, imagePath: nil)); submitted = true } catch { errorMessage = "Bildirim gönderilemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin." } }
}
