//
//  AppOpenAdManager.swift
//  Runnect-iOS
//

import GoogleMobileAds
import UIKit

final class AppOpenAdManager: NSObject {
    static let shared = AppOpenAdManager()

    private var appOpenAd: GADAppOpenAd?
    private var isShowingAd = false
    private var lastShowTime: Date?
    private let minInterval: TimeInterval = 180 // 3분 간격 제한
    private var loadTime: Date?
    private let adExpiration: TimeInterval = 14400 // 4시간 만료

    private var shouldShowAds: Bool {
        guard UserManager.shared.userType != .visitor else { return false }
        let launchCount = UserDefaultKeyList.Ad.appLaunchCount ?? 0
        return launchCount > 1
    }

    private override init() {
        super.init()
    }

    func preloadAd() {
        guard shouldShowAds else { return }
        guard appOpenAd == nil else { return }

        GADAppOpenAd.load(
            withAdUnitID: Config.adMobAppOpenAdUnitId,
            request: GADRequest()
        ) { [weak self] ad, error in
            if let error = error {
                print("[AdMob] 앱 오픈 광고 프리로드 실패: \(error.localizedDescription)")
                return
            }
            self?.appOpenAd = ad
            self?.appOpenAd?.fullScreenContentDelegate = self
            self?.loadTime = Date()
        }
    }

    func showAdIfAvailable() {
        guard shouldShowAds, !isShowingAd else { return }

        // 3분 간격 제한
        if let lastShow = lastShowTime, Date().timeIntervalSince(lastShow) < minInterval {
            return
        }

        // 4시간 만료 체크
        if let loadTime = loadTime, Date().timeIntervalSince(loadTime) > adExpiration {
            appOpenAd = nil
            preloadAd()
            return
        }

        guard let ad = appOpenAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            preloadAd()
            return
        }

        // 러닝 중에는 광고 안 보임
        if isRunTrackingActive(from: rootVC) { return }

        isShowingAd = true
        ad.present(fromRootViewController: rootVC)
        lastShowTime = Date()
    }

    private func isRunTrackingActive(from vc: UIViewController) -> Bool {
        if vc is RunTrackingVC || vc is CountDownVC { return true }
        if let nav = vc as? UINavigationController {
            return nav.viewControllers.contains { $0 is RunTrackingVC || $0 is CountDownVC }
        }
        if let presented = vc.presentedViewController {
            return isRunTrackingActive(from: presented)
        }
        return false
    }
}

extension AppOpenAdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isShowingAd = false
        appOpenAd = nil
        preloadAd()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isShowingAd = false
        appOpenAd = nil
        preloadAd()
    }
}
