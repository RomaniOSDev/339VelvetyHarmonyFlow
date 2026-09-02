import UIKit
import StoreKit

enum AppLinks {
    static let privacy = "https://velvety339harmonyflow.site/privacy/443"
    static let terms = "https://velvety339harmonyflow.site/terms/443"

    static func openPrivacy() {
        guard let url = URL(string: privacy) else { return }
        UIApplication.shared.open(url)
    }

    static func openTerms() {
        guard let url = URL(string: terms) else { return }
        UIApplication.shared.open(url)
    }

    static func requestReview() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { scene in
            scene as? UIWindowScene
        }
        let active = scenes.first { scene in
            scene.activationState == .foregroundActive
        }
        guard let windowScene = active ?? scenes.first else { return }
        SKStoreReviewController.requestReview(in: windowScene)
    }
}
