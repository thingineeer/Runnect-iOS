//
//  setImage.swift
//  Runnect-iOS
//
//  Created by sejin on 2022/12/29.
//

import UIKit
import Kingfisher

public extension UIImageView {
    func setImage(with urlString: String, placeholder: String? = nil, completion: ((UIImage?) -> Void)? = nil) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            self.image = UIImage()
            return
        }

        let resource = Kingfisher.KF.ImageResource(downloadURL: url, cacheKey: urlString)
        let placeholderImage = UIImage(named: placeholder ?? "img_placeholder")

        self.kf.setImage(
            with: resource,
            placeholder: placeholderImage,
            options: [
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.3)),
                .cacheMemoryOnly
            ],
            completionHandler: { result in
                result.success { imageResult in
                    completion?(imageResult.image)
                }
            }
        )
    }
}
