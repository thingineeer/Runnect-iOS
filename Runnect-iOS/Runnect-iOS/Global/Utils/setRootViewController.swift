//
//  setRootViewController.swift
//  Runnect-iOS
//
//  Created by sejin on 2022/12/29.
//

import UIKit

/**

  - Description:
 
          RootViewController를 만들어주는 유틸입니다. SnapShot을 찍어서 전환합니다.
          
*/
enum ViewControllerUtils {
    private static var isTransitioning = false

    static func setRootViewController(window: UIWindow, viewController: UIViewController, withAnimation: Bool) {
        guard !isTransitioning else { return }
        isTransitioning = true

        if !withAnimation {
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            isTransitioning = false
            return
        }

        if let snapshot = window.snapshotView(afterScreenUpdates: true) {
            viewController.view.addSubview(snapshot)
            window.rootViewController = viewController
            window.makeKeyAndVisible()

            UIView.animate(withDuration: 0.4, animations: {
                snapshot.layer.opacity = 0
            }, completion: { _ in
                snapshot.removeFromSuperview()
                isTransitioning = false
            })
        } else {
            isTransitioning = false
        }
    }
}
