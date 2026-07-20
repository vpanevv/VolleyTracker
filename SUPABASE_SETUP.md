# VolleyTracker Supabase setup

The app is connected to the `VolleyTracker` Supabase project:

- Project reference: `aftsmqwgewthlpveccty`
- Project URL: `https://aftsmqwgewthlpveccty.supabase.co`
- iOS bundle identifier: `com.vpanev.volleytracker`
- App callback URL: `volleytracker://auth-callback`
- Supabase OAuth callback: `https://aftsmqwgewthlpveccty.supabase.co/auth/v1/callback`

## Cloud data

The database contains `coach_profiles`, `team_groups`, `players`,
`training_sessions`, `attendance_records`, and `fee_records`. Row-level security
restricts every row to its authenticated coach. Profile and player photos are
stored privately in the `avatars` bucket.

## Authentication credentials still required

The iOS flows and callback handling are implemented, but Supabase cannot enable
the providers without credentials issued to the app owner.

### Apple

In Apple Developer, enable Sign in with Apple for `com.vpanev.volleytracker`. Then
open Supabase Authentication > Sign In / Providers > Apple, enable it, and add
`com.vpanev.volleytracker` as a Client ID. A secret key is only needed if the web
OAuth flow will also be used; Apple OAuth secrets expire every six months.

### Google

Create an OAuth client in Google Cloud, register
`https://aftsmqwgewthlpveccty.supabase.co/auth/v1/callback` as an authorized
redirect URI, then add the issued Client ID and Client Secret under Supabase
Authentication > Sign In / Providers > Google and enable the provider.

Never place Apple private keys or Google client secrets in the iOS project.
