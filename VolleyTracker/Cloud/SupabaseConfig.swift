import Foundation
import Supabase

enum SupabaseConfig {
    static let projectURL = URL(string: "https://aftsmqwgewthlpveccty.supabase.co")!
    static let publishableKey = "sb_publishable_AWPljuq5diBgSw-vKwf7lw_uiWYxMVY"
    static let callbackURL = URL(string: "volleytracker://auth-callback")!

    static let client = SupabaseClient(
        supabaseURL: projectURL,
        supabaseKey: publishableKey,
        options: SupabaseClientOptions(
            auth: .init(redirectToURL: callbackURL)
        )
    )
}
