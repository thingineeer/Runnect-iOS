//
//  NativeAdCVC.swift
//  Runnect-iOS
//
//  Created by 이명진 on 2025/02/09.
//

import UIKit

import SnapKit
import Then
import GoogleMobileAds

final class NativeAdCVC: UICollectionViewCell {

    // MARK: - UI Components

    private let nativeAdView = GADNativeAdView()

    private let mediaView = GADMediaView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 5
    }

    private let headlineLabel = UILabel().then {
        $0.font = .b4
        $0.textColor = .g1
        $0.numberOfLines = 1
    }

    private let adLabel = UILabel().then {
        $0.text = "광고"
        $0.font = .b9
        $0.textColor = .g4
        $0.backgroundColor = .w1
    }

    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headlineLabel.text = nil
        mediaView.mediaContent = nil
        iconImageView.image = nil
    }
}

// MARK: - Methods

extension NativeAdCVC {
    func configure(with nativeAd: GADNativeAd) {
        nativeAdView.nativeAd = nativeAd

        headlineLabel.text = nativeAd.headline
        mediaView.mediaContent = nativeAd.mediaContent
        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon == nil
    }
}

// MARK: - UI & Layout

extension NativeAdCVC {
    private func setUI() {
        contentView.backgroundColor = .w1
        mediaView.layer.borderColor = UIColor(hex: "EAEAEA").cgColor
        mediaView.layer.borderWidth = 1.0
    }

    private func setLayout() {
        contentView.addSubview(nativeAdView)
        nativeAdView.addSubviews(mediaView, adLabel, headlineLabel, iconImageView)

        nativeAdView.mediaView = mediaView
        nativeAdView.headlineView = headlineLabel
        nativeAdView.iconView = iconImageView

        nativeAdView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        mediaView.snp.makeConstraints {
            $0.leading.top.trailing.equalToSuperview()
            $0.height.equalTo(mediaView.snp.width).multipliedBy(124.0 / 174.0)
        }

        adLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(6)
        }

        iconImageView.snp.makeConstraints {
            $0.top.equalTo(mediaView.snp.bottom).offset(4)
            $0.leading.equalToSuperview()
            $0.width.height.equalTo(16)
        }

        headlineLabel.snp.makeConstraints {
            $0.top.equalTo(mediaView.snp.bottom).offset(4)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.trailing.equalToSuperview()
        }
    }
}
