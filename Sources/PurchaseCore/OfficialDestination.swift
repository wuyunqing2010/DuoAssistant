import Foundation

public enum OfficialDestination {
    // Deliberately a general landing page. No unverified product or checkout endpoint.
    public static let iPhone = URL(string: "https://www.apple.com.cn/iphone/")!
    public static let store = URL(string: "https://www.apple.com.cn/store")!

    public static func isAllowedInitialURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "www.apple.com.cn",
              url.user == nil, url.password == nil,
              url.port == nil, url.query == nil, url.fragment == nil else { return false }
        // URL.path can drop a trailing slash on Darwin. Keep the encoded path
        // intact so only these exact landing-page forms pass the allowlist.
        return ["/iphone", "/iphone/", "/store", "/store/"].contains(components.percentEncodedPath)
    }
}
