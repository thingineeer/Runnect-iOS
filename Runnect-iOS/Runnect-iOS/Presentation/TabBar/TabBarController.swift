//
//  TabBarController.swift
//  Runnect-iOS
//
//  Created by sejin on 2022/12/29.
//

import UIKit

final class TabBarController: UITabBarController {

    // MARK: - Properties

    private var previousSelectedIndex = 0

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setUI()
        setTabBarControllers()
    }
}

// MARK: - Methods

extension TabBarController {
    private func setUI() {
        if #available(iOS 26.0, *) {
            // iOS 26+: Liquid Glass 활용
            tabBar.tintColor = .m1
            tabBar.unselectedItemTintColor = .g3
            // Liquid Glass 활성화: 시스템 기본 반투명 외관 설정
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            // iOS 25 이하: 기존 커스텀 스타일 유지
            tabBar.backgroundColor = .white
            tabBar.unselectedItemTintColor = .g3
            tabBar.tintColor = .m1
            tabBar.layer.cornerRadius = 20
            tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            tabBar.layer.applyShadow(alpha: 0.03, y: -4, blur: 5)
        }
    }
    
    private func setTabBarControllers() {
        let courseDrawingNVC = templateNavigationController(title: "코스 그리기",
                                                            unselectedImage: ImageLiterals.icCourseDraw,
                                                            selectedImage: ImageLiterals.icCourseDrawFill,
                                                            rootViewController: CourseDrawingHomeVC())
        let courseStorageNVC = templateNavigationController(title: "보관함",
                                                            unselectedImage: ImageLiterals.icStorage,
                                                            selectedImage: ImageLiterals.icStorageFill,
                                                            rootViewController: CourseStorageVC())
        let courseDiscoveryNVC = templateNavigationController(title: "코스 발견",
                                                              unselectedImage: ImageLiterals.icCourseDiscover,
                                                              selectedImage: ImageLiterals.icCourseDiscoverFill,
                                                              rootViewController: CourseDiscoveryVC())
        let myPageNVC = templateNavigationController(title: "마이페이지",
                                                     unselectedImage: ImageLiterals.icMypage,
                                                     selectedImage: ImageLiterals.icMypageFill,
                                                     rootViewController: MyPageVC())
        
        viewControllers = [courseDrawingNVC, courseStorageNVC, courseDiscoveryNVC, myPageNVC]
    }
    
    private func templateNavigationController(title: String, unselectedImage: UIImage?, selectedImage: UIImage?, rootViewController: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: rootViewController)
        nav.title = title
        nav.tabBarItem.image = unselectedImage
        nav.tabBarItem.selectedImage = selectedImage
        nav.navigationBar.isHidden = true
        return nav
    }
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let title = viewController.title else { return }

        let currentIndex = tabBarController.selectedIndex

        // 이미 선택된 탭을 다시 탭했을 때 스크롤 투 탑 (API 호출 없음)
        if currentIndex == previousSelectedIndex {
            if let nav = viewController as? UINavigationController,
               let courseDiscoveryVC = nav.visibleViewController as? CourseDiscoveryVC {
                courseDiscoveryVC.scrollToTop()
            }
        }

        previousSelectedIndex = currentIndex

        switch title {
        case "코스 그리기":
            analyze(buttonName: GAEvent.Button.clickCourseDrawingTabBar)
        case "보관함":
            analyze(buttonName: GAEvent.Button.clickStorageTabBar)
        case "코스 발견":
            analyze(buttonName: GAEvent.Button.clickCourseDiscoveryTabBar)
        case "마이페이지":
            analyze(buttonName: GAEvent.Button.clickMyPageTabBar)
        default:
            break
        }
    }
}
