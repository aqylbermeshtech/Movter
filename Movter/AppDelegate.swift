//
//  AppDelegate.swift
//  Movter
//
//  Created by Nurtore on 13.03.2026.
//

import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

enum MovterPushNotificationRuntime {
    /// Observe from features that call your API (e.g. after login): `userInfo["fcmToken"] as? String`
    static let fcmTokenDidUpdateNotification = Notification.Name("com.mentorapp.mentor.kz.push.fcmTokenUpdated")

    private static let fcmTokenUserDefaultsKey = "mentor.push.fcmToken"

    static var lastFCMToken: String? {
        UserDefaults.standard.string(forKey: fcmTokenUserDefaultsKey)
    }

    static func persistAndNotifyFCMToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: fcmTokenUserDefaultsKey)
        NotificationCenter.default.post(
            name: fcmTokenDidUpdateNotification,
            object: nil,
            userInfo: ["fcmToken": token]
        )
        #if DEBUG
        print("[Push] FCM token (\(token.count) chars): \(token)")
        #endif
    }
}

