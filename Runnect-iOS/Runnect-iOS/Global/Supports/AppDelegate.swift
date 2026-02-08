//
//  AppDelegate.swift
//  Runnect-iOS
//
//  Created by sejin on 2022/12/29.
//

import UIKit

import NMapsMap
import KakaoSDKAuth
import KakaoSDKCommon
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
            
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // 세로방향 고정
        return UIInterfaceOrientationMask.portrait
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()

        NMFAuthManager.shared().ncpKeyId = Config.naverMapClientId
        #if DEBUG
        NMFAuthManager.shared().delegate = self
        #endif
        KakaoSDK.initSDK(appKey: Config.kakaoNativeAppKey)

        GADMobileAds.sharedInstance().start(completionHandler: nil)

        // WatchConnectivity 세션 시작
        WatchSessionService.shared.startSession()

        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// MARK: - NMFAuthManagerDelegate

#if DEBUG
extension AppDelegate: NMFAuthManagerDelegate {
    func authorized(_ state: NMFAuthState, error: Error?) {
        if let error = error {
            print("[NMFAuth] 인증 실패 (DEBUG): \(error.localizedDescription)")
            return
        }
        switch state {
        case .authorized:
            print("[NMFAuth] 인증 성공")
        case .authorizing:
            print("[NMFAuth] 인증 진행 중")
        case .pending:
            print("[NMFAuth] 인증 대기 중")
        case .unauthorized:
            print("[NMFAuth] 미인증 상태")
        @unknown default:
            break
        }
    }
}
#endif
