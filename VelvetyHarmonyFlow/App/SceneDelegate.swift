import UIKit
import SwiftUI
import CoreSpotlight

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {return}
        window = UIWindow(windowScene: windowScene)
        let host = UIHostingController(rootView: ContentView())
        host.view.backgroundColor = .clear
        window?.backgroundColor = .clear
        window?.rootViewController = host
        window?.makeKeyAndVisible()
        if let activity = connectionOptions.userActivities.first {
            Self.route(activity)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        Self.route(userActivity)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }

    private static func route(_ activity: NSUserActivity) {
        guard activity.activityType == CSSearchableItemActionType,
              let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let id = UUID(uuidString: identifier) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NotificationCenter.default.post(name: Notification.Name("openNote"), object: id)
        }
    }
}
