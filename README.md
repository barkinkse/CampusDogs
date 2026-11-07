# Campus Dogs

Campus Dogs is a campus-dog information and management project with two clients backed by Supabase:

- `apps/ios`: anonymous SwiftUI member app for active dog profiles, public care/health information, published announcements, last-known locations, and anonymous observation reports.
- `apps/admin`: authenticated React management panel for dogs, photos, health records, care icons, collars, reports, announcements, and the last-known-location map.
- `supabase`: PostgreSQL migrations, RLS policies, Storage configuration source, development seed data, and Deno Edge Function source.

Bluetooth scanning is currently a development simulation; it is not a real collar/BLE integration. Maps show the last published location, not continuous real-time tracking.

## Technology stack

- iOS: Swift, SwiftUI, MapKit, CoreLocation, `supabase-swift`
- Admin: React, TypeScript, Vite, React Router, `@supabase/supabase-js`
- Backend: Supabase PostgreSQL, Auth, Row Level Security, Storage, Edge Functions
- Web map tiles: OpenStreetMap

## Repository structure

```text
apps/admin/      React/Vite management SPA
apps/ios/        SwiftUI/Xcode member application
supabase/        migrations, functions, config and development seed data
docs/            product, architecture, security, setup and validation documents
```

## Local configuration

No credential-bearing local configuration is committed.

### Admin panel

```sh
cd apps/admin
cp .env.example .env.local
```

Set the following values in the ignored `apps/admin/.env.local` file:

```text
VITE_SUPABASE_URL=YOUR_SUPABASE_URL
VITE_SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

### iOS app

Copy the safe template to the ignored local configuration file:

```sh
cp apps/ios/Config/Supabase.example.xcconfig apps/ios/Config/Supabase.xcconfig
```

Set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` in that local copy. `Default.xcconfig` includes `Supabase.xcconfig` when present.

Use only publishable client credentials in iOS and the web application. Never place a Supabase service-role key, Vercel token, password, or other privileged secret in this repository.

## Run and build

### Admin panel

```sh
cd apps/admin
npm install
npm run dev
npm run build
```

### iOS application

Open `apps/ios/CampusDogs.xcodeproj` in Xcode, select the `CampusDogs` scheme, then choose an iPhone Simulator or development device.

Example Debug Simulator build:

```sh
xcodebuild \
  -project apps/ios/CampusDogs.xcodeproj \
  -scheme CampusDogs \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -derivedDataPath /tmp/CampusDogsDerivedData \
  build
```

## Supabase

- SQL changes are maintained in `supabase/migrations/` and must be applied manually and deliberately to Cloud; do not edit an already-applied migration.
- `supabase/seed.sql` is repeatable development data and is not applied automatically.
- Edge Function source is in `supabase/functions/`. Deployment, function secrets, SMTP, Auth redirects, and Cloud Storage settings require separate authorized setup.

## Documentation

Start with [technical project context](docs/PROJECT_CONTEXT.md). Additional Turkish technical overview, user guide, presentation guide, schema, security, test and setup documents are in `docs/`.
