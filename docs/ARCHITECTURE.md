# Architecture

`apps/ios` is a SwiftUI iPhone app organized by feature and core services. Views depend on small protocols (`BluetoothScanner`, `LocationService`) so mocks can be exchanged for device implementations. The Bluetooth screen owns an observable view model, which owns scanner lifecycle and cancels/clears its callback when the view disappears. `apps/admin` is Vite/React/TypeScript with shared visual components, routed administrative views, and a Supabase client factory. Vercel serves its built static output.

Supabase is the only backend: PostgreSQL stores application data, Auth authenticates admins, Storage will store photos, and RLS is the authorization boundary. The admin route guard requires both an Auth session and a successful `is_admin()` result; RLS remains authoritative. When client configuration is absent, administrative routes render a configuration state rather than mock access. Clients use only publishable keys.

Phase 2 adds typed admin repository operations for dogs, health records, care icons and assignments, notes, anonymous reports, announcements, collars, and collar assignments. The protected React routes call these operations with the user session and rely on RLS and `is_admin()` for authorization. The admin app has no service-role capability and does not create `admin_users` from the browser.

iOS has Codable database DTOs and repositories. The member app uses `SupabaseDogRepository` for active dogs and current locations, `SupabaseAnnouncementRepository` for published announcements, and `SupabaseMemberReportRepository` for anonymous text-only inserts. Report-image Storage fields and buckets remain in the schema for a future audited feature, but no member or admin MVP UI performs image upload/viewing.

The member map renders only rows returned by `dog_locations`; it has no default campus coordinate. The Bluetooth feature remains a local mock behind its scanner abstraction and does not write location data.
