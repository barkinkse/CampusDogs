# Campus Dogs Member iOS Application Status Report

**Audit date:** 4 November 2026
**Scope:** `apps/ios` source, Xcode project, Swift Package lockfile, current Supabase schema/migrations and the related admin implementation.
**Method:** source and configuration inspection plus a Debug simulator build. No Swift source, project configuration, migration, Cloud data, policy, or deployment was changed. No Supabase write was made.

## 1. Executive summary

The Member app is a small, coherent SwiftUI application with a sound anonymous-read/anonymous-report product boundary. It builds successfully and its five primary tab screens are wired to live Supabase repositories rather than the local example data. The core browse flow—active dogs, public care information, published announcements, and last-known locations—is implemented in source.

It is not ready to be described as end-to-end verified. The largest member-facing gaps are the absence of public health-history rendering, no live validation of anonymous report submission or Storage image retrieval, and limited production polish around images, refresh/navigation shortcuts, accessibility, and presentation assets. The map is a last-known-location display only; it does not acquire a device location or establish real-time collar tracking. Bluetooth remains deliberately deferred and must stay isolated from this next phase.

The recent admin changes remain compatible: removing announcement image creation does not affect the iOS announcement reader; unchanged care-icon keys map to the expected SF Symbols; removing the web admin-creation page and visible note author changes do not affect this app. Revised seed content will be visible only after an authorized person applies it to the relevant database; this audit did not assume it is present in Cloud.

## 2. Technology and architecture

| Area | Current implementation | Evidence |
| --- | --- | --- |
| UI | SwiftUI with `NavigationStack`, `TabView`, `List`, `Form`, `Map`, and `ContentUnavailableView` | `CampusDogsApp.swift`, feature views |
| Minimum OS | iOS 17.0, iPhone-only target | `CampusDogs.xcodeproj/project.pbxproj` |
| Language/toolchain | Swift 5.0 setting; build completed with Xcode 27.2 | project build settings; audit build |
| Backend SDK | `supabase-swift` 2.55.6 (locked) | `Package.resolved` |
| Maps | Apple MapKit | `Features/Map/CampusMapView.swift` |
| Backend boundary | Publishable Supabase client read from Info.plist build settings; no service-role key in source | `Core/Network/SupabaseConfiguration.swift` |
| Data access | Three small repositories: dogs, announcements, member reports | `Services/SupabaseRepositories.swift` |
| State | Per-view `@State`; no shared store/cache | all primary feature views |

`SupabaseConfiguration.client` is a computed static property. Every access can construct a new `SupabaseClient`; that is functionally acceptable for the current small app but does not provide shared caching, request coordination, or a single app-wide client lifecycle.

The live dog repository reads `dogs`, `dog_care_icons`, `care_icons`, and `dog_locations`, then joins them in memory. The configured backend RLS is therefore the privacy boundary: the app only asks for public/member-readable records and does not request `admin_notes`, `admin_users`, or private-health data.

## 3. Screen inventory

| Screen | Purpose | Source | Current behavior |
| --- | --- | --- | --- |
| Configuration state | Explains missing local Supabase configuration | `App/CampusDogsApp.swift` | Replaces the app root when the publishable configuration is absent. |
| Root tabs | Primary navigation | `App/CampusDogsApp.swift` | Five tabs: Home, Dogs, Map, Health Report, Announcements. |
| Home | Brief live dog overview and report prompt | `Features/Home/HomeView.swift` | Fetches active dogs and renders the first two alphabetically. |
| Dog list | Browse active dog profiles | `Features/Dogs/DogsViews.swift` (`DogsView`) | Lists live active dogs and links to detail. |
| Dog detail | Public profile, current status, care, care icons, last-location timestamp | `Features/Dogs/DogsViews.swift` (`DogDetailView`) | Uses data already loaded for the dog list; care icon detail opens in a sheet. |
| Announcements | Read published announcements | `Features/Announcements/AnnouncementsView.swift` | Fetches published rows newest-first; supports pull-to-refresh. |
| Health report | Anonymous text report submission | `Features/HealthReports/HealthReportView.swift` | Loads active dogs and inserts an anonymous report after local non-empty validation. |
| Map | Displays available last-known dog locations | `Features/Map/CampusMapView.swift` | Annotates active dogs that have public location rows; links to profile. |
| Bluetooth simulation | Deferred mock scan/location experiment, not in primary tabs | `Features/Bluetooth/BluetoothView.swift` | Preserved placeholder; not a live hardware path. |

No reusable component library, test target, or asset catalog is present. Shared UI is limited to `DogCard`, `DogPhotoView`, `HealthStatusView`, and the care-icon mapping in `DogsViews.swift`.

## 4. Feature status matrix

Status definitions: **DONE** means implemented and directly verified in this audit; **IMPLEMENTED** means source exists without full end-to-end proof; **PARTIAL** means a material expected part is absent; **MISSING** means no implementation was found; **UNKNOWN** means source cannot prove it; **DEFERRED** is explicitly outside this phase.

| Feature | Status | Evidence and qualification |
| --- | --- | --- |
| App builds for iOS Simulator | DONE | `xcodebuild` Debug build for iPhone 16 / iOS 18.6 reported `BUILD SUCCEEDED`. |
| Anonymous/no-login app structure | IMPLEMENTED | No member auth UI; the configured client uses a publishable key. Live anonymous policy behavior was not exercised. |
| Active dog retrieval | IMPLEMENTED | `SupabaseDogRepository.activeDogs()` filters `is_active = true` and orders by name. |
| Dog list, loading/error/empty states | IMPLEMENTED | `DogsView` contains all states and pull-to-refresh; live calls unverified. |
| Dog search/filter UI | MISSING | No search, filter, or user-selectable sort in `DogsView`. |
| Dog detail public profile | IMPLEMENTED | Uses name, gender, birth-date text, description, current public status, care text and assigned icons. |
| Public health-history display | MISSING | No `health_records` DTO/query/view is present. |
| Dog photo display | IMPLEMENTED | Public URL construction and `AsyncImage` fallback exist; real image access and error modes are unverified. |
| Care-icon compatibility | IMPLEMENTED | Explicit mappings for `recovery`, `limit_running`, `special_diet`, and `regular_checkup`, with fallback. |
| Published announcements | IMPLEMENTED | Filters `is_published`, orders `published_at` descending, includes load/error/empty/refresh UI. |
| Announcement images | PARTIAL | DTO retains `image_path` for schema compatibility, but UI does not render it. This is compatible with the current admin flow, which no longer creates announcement images. |
| Anonymous text reports | IMPLEMENTED | Selects dog, validates non-empty description, submits `member_reports` with category/severity; no live write was performed. |
| Duplicate-report prevention | MISSING | No client cooldown, duplicate detection, or confirmation guard beyond disabling during an active request. |
| Last-known map locations | IMPLEMENTED | Reads public `dog_locations`, provides missing/error/empty states and profile links. |
| Device current location | MISSING | `CampusMapView` does not request device location. |
| Real collar/BLE location updates | DEFERRED | `CoreBluetoothScanner` is intentionally inactive; mock simulation is isolated. |
| Unit/UI tests | MISSING | No test target or XCTest source was found. |

## 5. Supabase integration and data consistency

### Configuration and anonymous boundary

`SupabaseConfiguration.swift` reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from the generated app Info.plist and returns `nil` when either is absent or unresolved. The source explicitly cautions against service-role use. This is the correct client-key boundary in source. Cloud configuration and key rotation were not audited.

### Model-to-schema mapping

| Backend data | iOS mapping | Assessment |
| --- | --- | --- |
| `dogs` | `DatabaseDog` → `Dog` | Expected snake_case mappings and nullable fields are handled. `estimated_birth_date` is decoded as a `String`, avoiding locale/time-zone transformation. |
| `dog_care_icons` + `care_icons` | `DatabaseDogCareIcon`, `DatabaseCareIcon` → `[CareIcon]` | Correct in-memory relation by dog and icon UUID. The repository relies on RLS to return only valid public assignments. |
| `dog_locations` | `DatabaseLocation` → `CLLocationCoordinate2D` | Correct display mapping; no update path. |
| `announcements` | `DatabaseAnnouncement` | Reads title/body/published date and keeps nullable `image_path` without depending on it. |
| `member_reports` | `MemberReportInsert` | Sends `dog_id`, category, description, severity, and `image_path: nil`; status/default timestamps remain database-owned. |
| `health_records` | None | The missing DTO/repository/query is the reason public health history cannot be shown. |
| private/admin data | None | No source query targets `admin_notes` or `admin_users`; protection still depends on Cloud RLS. |

### Repository observations

`SupabaseDogRepository.activeDogs()` makes four sequential requests. A failure in optional data such as location or icon retrieval fails the entire dog load, including Home and Reports' dog picker. For a small dataset this is acceptable in volume, but it weakens resilience. It also performs the same aggregate reads independently in Home, Dogs, Map, and Report screens.

Photo URLs are correctly treated as either an existing HTTP URL or a public `dog-images` Storage object path. `AsyncImage` displays the same paw fallback while loading and on failure, so the user cannot distinguish a slow image from a missing/broken one. No Cloud Storage retrieval was performed in this audit.

The current admin-side changes are compatible:

- Removing the announcement image input does not affect `publishedAnnouncements()` or the announcement UI.
- The four current care-icon keys match `careIconSymbol(_:)` exactly.
- The removed admin-creation UI and hidden admin-note author are admin-only and have no Member-app dependency.
- Revised development seed/update content affects Member views only after a manual, authorized database update; no such application was assumed.

## 6. UI/UX assessment

### Strengths

- The information architecture is simple and appropriate for a small anonymous campus app: the five tabs expose core tasks without account friction.
- Native `List`, `Form`, `NavigationStack`, `ContentUnavailableView`, standard alerts, and pull-to-refresh give the app baseline iOS behavior, Dynamic Type support, and accessible controls.
- Loading, error, and empty states are present on every primary network screen.
- The map has explicit empty-state wording and a bottom safe-area summary, rather than presenting an empty map with no explanation.
- Care icons have a readable label and a sheet with explanation, rather than relying on color or iconography alone.

### Product-quality issues

1. **Home has no navigation shortcuts.** It renders two `DogCard`s as static rows rather than `NavigationLink`s and provides no “all dogs” action. The report prompt is also static. This makes the Home screen more of a status page than a useful dashboard. (`Features/Home/HomeView.swift:18-19`)
2. **The dog detail is incomplete for its stated purpose.** Current status and care are clear, but the public health-history section expected by the product is absent. (`Features/Dogs/DogsViews.swift`; no health repository)
3. **Image presentation is basic.** `AsyncImage` has no loading indicator, retry affordance, full-image presentation, cache policy, or content-specific accessibility label. (`DogsViews.swift:9-22`)
4. **Care-icon chips have fixed 90×72 geometry and a two-line label limit.** Long Turkish labels or larger Dynamic Type settings can truncate meaning. (`DogsViews.swift:51`)
5. **Visual language is only partly productized.** Native lists/forms are consistent, but `Color.green`, `GroupBox`, and text hierarchy are used ad hoc; there is no small design system for semantic status colors, spacing, cards, or photo treatments.
6. **No explicit dark-mode review exists.** Most native components adapt, but custom green opacity treatments and map annotation labels have not been checked in dark mode or high-contrast settings.
7. **No asset catalog was found** despite the project configuring `AppIcon`. The build succeeds, but the absence of reviewed icon/brand assets is a presentation-release risk.

The project is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), which is reasonable for scope. The native layouts are likely to adapt across normal iPhone sizes, but no launched UI review was performed on compact/large iPhones, Dynamic Type, VoiceOver, dark mode, or a physical device.

## 7. Functional problems and missing features

| Priority | Finding | Evidence | Recommended direction |
| --- | --- | --- | --- |
| P0 | Public health history is not implemented | No `health_records` model/query/view anywhere in `apps/ios` | Add a public-only health-record repository and a detail section after RLS behavior is verified. |
| P0 | Anonymous report flow has no Cloud write verification | `HealthReportView.submit()` and `SupabaseMemberReportRepository.submit(_:)` exist, but this audit intentionally made no write | Use a controlled test report and confirm database row, RLS boundary, admin visibility, error state, and cleanup plan. |
| P1 | Dog aggregate load fails if a secondary query fails | `SupabaseRepositories.swift:16-19` | Separate critical dog-profile data from optional locations/icons, or handle partial availability in a future focused change. |
| P1 | Home cards cannot open a profile | `HomeView.swift:18` | Convert to a navigation shortcut and provide a clear all-dogs action. |
| P1 | No retry/cooldown/deduplication after report success | `HealthReportView.swift:95-106` | Decide a lightweight UX policy appropriate for anonymous reporting; do not infer identity. |
| P1 | Report description has no upper-bound client validation | Local validation only checks non-empty; backend limits descriptions to 4,000 characters | Add a visible character limit and actionable local validation in a future UI pass. |
| P2 | Announcement dates have no explicit nil-date fallback UI | `AnnouncementsView.swift:5` only shows the date if it exists | Present a deliberate “Yayın tarihi belirtilmedi” state if that data quality case matters. |
| P2 | No search/filter in dog browsing | `DogsView.swift` | Add only if tester feedback shows the active-dog list is large enough to need it. |
| P2 | Photo loading/failure states are indistinguishable | `DogPhotoView` | Add a progress treatment and retry/failure differentiation. |
| P2 | Release identity/assets are unfinished | Placeholder bundle identifier `com.example.CampusDogs`; no `.xcassets` found | Set a real bundle identifier and add reviewed app icons before external distribution. |

## 8. Code quality and technical debt

The code is compact and understandable for an academic project: feature views own screen-local state, repository protocols are present, network code uses `async`/`await`, and source does not expose a service-role key. The main debt is not architectural complexity but compression and repetition.

- Many files place complete views and control flow on a single line (for example `AnnouncementsView.swift` and `DogsViews.swift`). This compiles, but harms reviewability, line-level diagnosis, and safe future modifications.
- Loading/error state patterns are repeated across every network screen instead of using a small reusable `LoadState` or view model pattern. A major architecture rewrite is not warranted now; extraction can follow when health history and richer states are added.
- A `Dog.examples` static dataset and `Announcement` model remain for Bluetooth mock/legacy use, while primary views use live data. This is acceptable only while the mock is explicitly isolated; it must not leak into the member browse flows.
- `CareIcon.symbol` actually stores a database icon key, not a rendered SF Symbol. The mapping works, but the property name is misleading.
- The repository does not expose typed HTTP/database errors to views; user messages are friendly but generic, limiting support diagnostics.
- There are no tests. The current compilation result is valuable but does not verify decoding, RLS, navigation, or report insertion.

No obvious retain cycle was found in the Bluetooth mock: its callback uses `[weak self]`, its task is cancelled on stop, and the feature is not part of the primary tab flow.

## 9. Verification results

| Check | Result | Evidence / limitation |
| --- | --- | --- |
| Xcode project and scheme discovery | DONE | One `CampusDogs` application target and one scheme; Debug and Release configurations. |
| Dependency resolution | DONE | `xcodebuild -list` resolved the locked Swift package graph, including Supabase 2.55.6. |
| Simulator availability | DONE | iOS 18.6 iPhone 16 destination was available. |
| Debug simulator build | DONE | `xcodebuild -project apps/ios/CampusDogs.xcodeproj -scheme CampusDogs -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build` completed successfully. |
| Unit/UI tests | MISSING | No test target or test source was found; no test suite could run. |
| App launch and interactive simulator review | NOT TESTED | Build-only audit; no simulator session was launched. |
| Supabase public reads | IMPLEMENTED, NOT VERIFIED IN THIS AUDIT | Repository code is present; no live read request was made. |
| Supabase anonymous report insert | IMPLEMENTED, NOT VERIFIED IN THIS AUDIT | No Cloud write was permitted. |
| Public Storage photo access | IMPLEMENTED, NOT VERIFIED IN THIS AUDIT | No real object retrieval was performed. |
| Map annotation interaction | IMPLEMENTED, NOT VERIFIED IN THIS AUDIT | Requires live location rows and a launched simulator/device. |
| Bluetooth/collar behavior | DEFERRED | Requires the separately managed hardware protocol and a physical device. |

## 10. Prioritized development roadmap

### P0 — functional completeness and integration proof

1. Implement a member-safe public health-history section using only `is_public = true` records, then run an anonymous read/RLS verification.
2. Run a controlled anonymous health-report test: valid insert, invalid/empty input, network failure, admin review visibility, and record cleanup. Do not collect a member identity.
3. Verify the actual Cloud dataset and Storage photo paths on a simulator; confirm missing images, missing location rows, draft announcements, and private health records behave as expected.
4. Establish production-distribution basics: real bundle identifier, reviewed app icon assets, and a configuration check for release builds.

### P1 — core member experience

1. Make Home dog cards navigable and add a clear “Tüm köpekleri gör” path.
2. Make dog loading resilient when optional locations/icons are unavailable, and avoid repeating four aggregate requests per tab where practical.
3. Improve report form constraints and feedback: character limit, clearer post-submit state, and an agreed anonymous duplicate-submission policy.
4. Improve image states: loading indicator, failure distinction, meaningful accessibility label, and optional retry.

### P2 — UI/UX polish

1. Review on small and large iPhones, Dynamic Type, VoiceOver, dark mode, and high contrast.
2. Introduce lightweight semantic styling for health states, cards, spacing, and image treatment while preserving native controls.
3. Rework fixed-size care-icon chips so labels remain readable at larger text sizes.
4. Add explicit announcement date fallback and refine empty/error messaging from tester feedback.

### P3 — optional enhancements

1. Add search/filter only if the real active-dog population justifies it.
2. Add unit tests for DTO decoding, icon mapping, date/nullable fields, and report validation; add a small UI smoke suite for the anonymous flows.
3. Consider a small shared client/store after functional work demonstrates duplicated fetches are affecting responsiveness.

## 11. Bluetooth integration boundaries

The following files are owned integration points and should be preserved for the Bluetooth developer:

- `Core/Bluetooth/BluetoothScanner.swift`: `BluetoothScanner` protocol, `DetectedCollar`, mock scanner, and deliberately empty `CoreBluetoothScanner`.
- `Core/Location/LocationService.swift`: protocol and mock location provider.
- `Features/Bluetooth/BluetoothView.swift`: isolated simulation UI and `BluetoothViewModel`; it is not included in `RootTabView`.
- `Models/Dog.swift`: `Dog.examples` supports the mock scanner only.
- `Features/Map/CampusMapView.swift`: display-only consumer of public `dog_locations`; it must not be treated as a location-acquisition or synchronization mechanism.

The simulation currently changes only local `selectedDog`/message state. It does not call `submit_dog_location`, write location data, obtain a real GPS coordinate, discover physical BLE devices, or synchronize a collar. A future hardware phase should agree an advertisement identifier and trust/validation model before connecting any scanner output to the backend.
