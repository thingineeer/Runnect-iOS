//
//  SceneDelegate.swift
//  Runnect-iOS
//
//  Created by sejin on 2022/12/29.
//

import UIKit
import KakaoSDKAuth
import KakaoSDKCommon
import FirebaseCore
import FirebaseCoreInternal
import AppTrackingTransparency

// 들어온 링크가 공유된 코스인지, 개인 보관함에 있는 코스인지 나타내기 위한 타입입니다.
enum CourseType {
    case publicCourse, privateCourse
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var hasRequestedATT = false
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(scene, continue: userActivity)
        }
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let nav = UINavigationController(rootViewController: SplashVC())
        window.rootViewController = nav
        self.window = window
        window.makeKeyAndVisible()
        analyze(screenName: GAEvent.View.viewHome)
        incrementAppLaunchCount()
        
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let incomingURL = userActivity.webpageURL,
              let (courseType, courseId) = self.handleUniversalLink(incomingURL) else { return }

        let courseTypeString = courseType == .publicCourse ? "public" : "private"
        GAManager.shared.logEvent(eventType: .share(
            eventName: GAEvent.Share.openShareLink,
            courseType: courseTypeString,
            courseId: courseId
        ))

        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()

        if UserManager.shared.userType != .registered { UserManager.shared.userType = .visitor }

        switch courseType {
        case .publicCourse:
            let courseDetailVC = CourseDetailVC()
            courseDetailVC.getUploadedCourseDetail(courseId: courseId)
            navigationController.pushViewController(courseDetailVC, animated: false)
        case .privateCourse:
            let privateCourseDetailVC = RunningWaitingVC()
            privateCourseDetailVC.setData(courseId: courseId, publicCourseId: nil)
            navigationController.pushViewController(privateCourseDetailVC, animated: false)
        }

        let tabBarController = TabBarController()
        navigationController.navigationBar.isHidden = true
        navigationController.viewControllers = [tabBarController, navigationController.viewControllers.last].compactMap { $0 }

        tabBarController.selectedIndex = 2
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        if let url = URLContexts.first?.url {
            // Kakao SDK가 처리해야 하는지 확인합니다.
            if AuthApi.isKakaoTalkLoginUrl(url) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        requestTrackingAuthorizationIfNeeded()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    func handleUniversalLink(_ url: URL) -> (courseType: CourseType, courseId: Int)? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }

        for item in queryItems {
            if item.name == "courseId", let id = item.value, let idInt = Int(id) {
                return (.publicCourse, idInt)
            } else if item.name == "privateCourseId", let id = item.value, let idInt = Int(id) {
                return (.privateCourse, idInt)
            }
        }
        return nil
    }
}

extension SceneDelegate {
    private func analyze(screenName: String) {
        GAManager.shared.logEvent(eventType: .screen(screenName: screenName))
    }

    private func incrementAppLaunchCount() {
        let current = UserDefaultKeyList.Ad.appLaunchCount ?? 0
        UserDefaultKeyList.Ad.appLaunchCount = current + 1
    }

    private func requestTrackingAuthorizationIfNeeded() {
        guard !hasRequestedATT else { return }
        hasRequestedATT = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("[ATT] 추적 허용")
                case .denied:
                    print("[ATT] 추적 거부")
                case .notDetermined:
                    print("[ATT] 미결정")
                case .restricted:
                    print("[ATT] 제한됨")
                @unknown default:
                    break
                }
            }
        }
    }
}

extension CourseDetailVC {
    func getUploadedCourseDetail(courseId: Int?) {
        guard let publicCourseId = courseId else { return }
        LoadingIndicator.showLoading()
        Providers.publicCourseProvider.request(.getUploadedCourseDetail(publicCourseId: publicCourseId)) { [weak self] response in
            guard let self = self else { return }
            LoadingIndicator.hideLoading()
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    do {
                        let responseDto = try result.map(BaseResponse<UploadedCourseDetailResponseDto>.self)
                        guard let data = responseDto.data else { return }
                        self.setData(model: data)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                if status >= 400 {
                    print("400 error")
                    self.showNetworkFailureToast()
                }
            case .failure(let error):
                print(error.localizedDescription)
                self.showNetworkFailureToast()
            }
        }
    }
}
