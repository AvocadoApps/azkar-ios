import Foundation

public enum AzkarSecretKey {
    public static let AZKAR_SUPABASE_API_URL = "AZKAR_SUPABASE_API_URL"
    public static let AZKAR_SUPABASE_API_KEY = "AZKAR_SUPABASE_API_KEY"
    public static let REVENUE_CAT_API_KEY = "REVENUE_CAT_API_KEY"
    public static let MIXPANEL_TOKEN = "MIXPANEL_TOKEN"
}

public func readSecret(_ key: String) -> String? {
    guard
        let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
        let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else
    {
        return nil
    }
    let value = dict[key] as? String
    return value?.textOrNil
}
