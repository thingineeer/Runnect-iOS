//
//  Toast.swift
//  Runnect-iOS
//
//  Created by 이명진 on 2024/03/25.
//

import UIKit

import SnapKit
import Then

public extension UIViewController {
    func showToast(message: String, heightOffset: CGFloat = 0) {
        Toast.show(
            message: message,
            view: self.view,
            safeAreaBottomInset: self.safeAreaBottomInset(),
            heightOffset: heightOffset
        )
    }
    
    func showNetworkFailureToast() {
        showToast(message: "네트워크 통신 실패")
    }
}

public class Toast {
    public static func show(
        message: String,
        view: UIView,
        safeAreaBottomInset: CGFloat = 0,
        heightOffset: CGFloat = 0
    ) {
        let toastContainer = UIView().then {
            $0.backgroundColor = UIColor.g2.withAlphaComponent(0.7)
            $0.alpha = 1.0
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.isUserInteractionEnabled = false
        }
        
        let toastLabel = UILabel().then {
            $0.textColor = .m4
            $0.font = .b4
            $0.textAlignment = .center
            $0.text = message
            $0.clipsToBounds = true
            $0.numberOfLines = 0
            $0.sizeToFit()
        }
        
        toastContainer.addSubview(toastLabel)
        view.addSubview(toastContainer)
        
        let toastContainerWidth = toastLabel.intrinsicContentSize.width + 40.0
        
        toastContainer.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(safeAreaBottomInset + 160 + heightOffset)
            $0.width.equalTo(toastContainerWidth)
            $0.height.equalTo(31)
        }
        
        toastLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseIn, animations: {
            toastContainer.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 1.0, delay: 2.0, options: .curveEaseOut, animations: {
                toastContainer.alpha = 0.0
            }, completion: {_ in
                toastContainer.removeFromSuperview()
            })
        })
    }
}
