# Development roadmap

1. **Supabase setup:** the configured project has development dogs, public health records, care icons, announcements, and a publicly retrievable dog image. Anonymous read-boundary checks passed in Phase 2.4.1 clarified that anonymous bucket-metadata access returns a false-negative `NoSuchBucket`; Dashboard verification of the `dog-images` MIME/size settings and migrations 005–006 policies is still required before release.
2. **Client integration:** React and SwiftUI clients compile against their Supabase SDKs. The member home, dogs, map, announcements, and anonymous-report screens use live repositories; dog photos need the missing bucket before end-to-end verification. Admin CRUD requires controlled admin-role tests.
3. **Field hardware:** deferred to the Bluetooth contributor. Do not re-enable Bluetooth navigation or implement CoreBluetooth work in this project phase.
4. **Hardening/release:** Phase 2.4 builds pass and anonymous RLS reads were verified. Before deployment, complete the documented master-admin, regular-admin, Storage, CRUD, and iOS interactive test matrix; then perform the accessibility, device, and deployment review.
# Product refinement

The member health-report flow is intentionally text-only and has no history or internal-status display. Health & Treatment Records distinguish current public dog status from historical public/private medical records. Admin Notes remain a separate, always-private communication channel. Care icons are managed as shared records and assigned through `dog_care_icons`.
