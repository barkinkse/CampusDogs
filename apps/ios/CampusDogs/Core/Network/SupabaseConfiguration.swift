import Foundation
import Supabase

enum SupabaseConfiguration {
    static var client: SupabaseClient? {
        guard let rawURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
              !rawURL.isEmpty, !key.isEmpty, !rawURL.contains("$("), !key.contains("$("),
              let url = URL(string: rawURL) else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
// Values are supplied by an untracked local build configuration. Never use a service-role key in this app.
