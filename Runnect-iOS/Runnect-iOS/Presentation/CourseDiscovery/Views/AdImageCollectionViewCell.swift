//
//  AdImageCollectionViewCell.swift
//  Runnect-iOS
//
//  Created by 이명진 on 2023/11/18.
//

import UIKit

import SnapKit
import Then
import GoogleMobileAds

protocol AdImageCollectionViewCellDelegate: AnyObject {
    func adBannerDidReceiveAd()
    func adBannerDidFailToReceiveAd()
}

final class AdImageCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties

    weak var delegate: AdImageCollectionViewCellDelegate?
    private var isAdLoaded = false
    private var isFirstLoad = true
    private var shimmerTimeoutWork: DispatchWorkItem?
    private var imgBanners: [UIImage] = [ImageLiterals.imgBanner1, ImageLiterals.imgBanner2, ImageLiterals.imgBanner3]
    private var currentPage: Int = 0
    private var timer: Timer?

    // MARK: - UI Components (Container)

    private let shadowView = UIView().then {
        $0.backgroundColor = .clear
        $0.layer.shadowColor = UIColor(hex: "#171717").cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 6
    }

    private let containerView = UIView().then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 16
    }

    // MARK: - UI Components (AdMob)

    private var bannerView: GADBannerView = {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = Config.adMobBannerAdUnitId
        banner.alpha = 0
        return banner
    }()

    // MARK: - UI Components (Fallback Banner)

    private lazy var bannerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    // MARK: - UI Components (AD Label - Glass Pill)

    private let adLabelContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark)).then {
        $0.layer.cornerRadius = 11
        $0.clipsToBounds = true
        $0.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        $0.layer.borderWidth = 0.5
        $0.alpha = 0
    }

    private let adLabel = UILabel().then {
        $0.text = "AD"
        $0.font = .b9
        $0.textColor = UIColor.white.withAlphaComponent(0.9)
    }

    // MARK: - UI Components (Custom Page Control)

    private let pageControlStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .center
    }

    // MARK: - UI Components (Gradient Overlay)

    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()

    // MARK: - UI Components (Shimmer Loading)

    private let shimmerView = UIView().then {
        $0.backgroundColor = .m3
    }

    private let shimmerGradientLayer = CAGradientLayer()

    // MARK: - Life cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
        setFallbackBanner()
        setupShimmer()
        setupPageDots()
        updateAccessibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.layer.shadowPath = UIBezierPath(
            roundedRect: containerView.frame,
            cornerRadius: 16
        ).cgPath
        gradientLayer.frame = gradientView.bounds
        shimmerGradientLayer.frame = shimmerView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if !isAdLoaded {
            loadAdMobBanner()
        }
    }

    deinit {
        timer?.invalidate()
        shimmerTimeoutWork?.cancel()
    }
}

// MARK: - AdMob Banner

extension AdImageCollectionViewCell {

    func setRootViewController(_ viewController: UIViewController) {
        bannerView.rootViewController = viewController
        loadAdMobBanner()
    }

    private func loadAdMobBanner() {
        bannerView.delegate = self
        bannerView.load(GADRequest())
        showShimmer()
        startShimmerTimeout()
    }

    /// 시나리오 1: 첫 로딩 성공 - crossDissolve로 광고 표시
    private func showAdMobBanner() {
        isAdLoaded = true
        cancelShimmerTimeout()

        bannerView.isHidden = false
        bannerCollectionView.isHidden = true
        pageControlStack.isHidden = true
        gradientView.isHidden = true

        let duration: TimeInterval = UIAccessibility.isReduceMotionEnabled ? 0 : 0.3

        UIView.animate(withDuration: duration, animations: {
            self.shimmerView.alpha = 0
            self.bannerView.alpha = 1
            self.adLabelContainer.alpha = 1
        }, completion: { _ in
            self.shimmerView.isHidden = true
            self.shimmerView.alpha = 1
            self.shimmerGradientLayer.removeAnimation(forKey: "shimmer")
        })

        stopAutoScroll()
        isFirstLoad = false
    }

    /// 시나리오 3: 부분 로딩 실패 - AD pill fade out 0.2초 → crossDissolve 0.4초로 폴백
    private func transitionToFallback() {
        isAdLoaded = false
        cancelShimmerTimeout()

        let reduceMotion = UIAccessibility.isReduceMotionEnabled

        if adLabelContainer.alpha > 0 {
            // AD pill이 보이는 상태에서 실패: pill fade out 먼저 → 배너 교체
            let pillDuration: TimeInterval = reduceMotion ? 0 : 0.2
            let crossDuration: TimeInterval = reduceMotion ? 0 : 0.4

            UIView.animate(withDuration: pillDuration, animations: {
                self.adLabelContainer.alpha = 0
            }, completion: { _ in
                self.prepareFallbackViews()
                UIView.animate(withDuration: crossDuration, animations: {
                    self.bannerView.alpha = 0
                    self.bannerCollectionView.alpha = 1
                    self.gradientView.alpha = 1
                    self.pageControlStack.alpha = 1
                }, completion: { _ in
                    self.bannerView.isHidden = true
                    self.startAutoScroll()
                    self.updatePageDots()
                })
            })
        } else {
            // 첫 로딩 실패: shimmer → crossDissolve로 폴백
            let crossDuration: TimeInterval = reduceMotion ? 0 : 0.3

            prepareFallbackViews()
            bannerCollectionView.alpha = 0
            gradientView.alpha = 0
            pageControlStack.alpha = 0

            UIView.animate(withDuration: crossDuration, animations: {
                self.shimmerView.alpha = 0
                self.bannerCollectionView.alpha = 1
                self.gradientView.alpha = 1
                self.pageControlStack.alpha = 1
            }, completion: { _ in
                self.shimmerView.isHidden = true
                self.shimmerView.alpha = 1
                self.shimmerGradientLayer.removeAnimation(forKey: "shimmer")
                self.bannerView.isHidden = true
                self.startAutoScroll()
                self.updatePageDots()
            })
        }

        isFirstLoad = false
    }

    private func prepareFallbackViews() {
        bannerCollectionView.isHidden = false
        gradientView.isHidden = false
        pageControlStack.isHidden = false
    }
}

// MARK: - GADBannerViewDelegate

extension AdImageCollectionViewCell: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        showAdMobBanner()
        delegate?.adBannerDidReceiveAd()
        analyze(buttonName: GAEvent.Button.clickTryBanner)
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("[AdMob] 배너 광고 로드 실패: \(error.localizedDescription)")
        transitionToFallback()
        delegate?.adBannerDidFailToReceiveAd()
    }
}

// MARK: - Shimmer Loading

extension AdImageCollectionViewCell {

    private func setupShimmer() {
        shimmerGradientLayer.colors = [
            UIColor.m3.cgColor,
            UIColor.white.withAlphaComponent(0.2).cgColor,
            UIColor.m3.cgColor
        ]
        shimmerGradientLayer.locations = [0, 0.5, 1]
        shimmerGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerView.layer.addSublayer(shimmerGradientLayer)
    }

    private func showShimmer() {
        shimmerView.isHidden = false
        shimmerView.alpha = 1
        bannerCollectionView.isHidden = true
        bannerView.isHidden = false
        bannerView.alpha = 0
        adLabelContainer.alpha = 0
        pageControlStack.isHidden = true
        gradientView.isHidden = true

        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-0.2, -0.1, 0.0]
        animation.toValue = [1.0, 1.1, 1.2]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        shimmerGradientLayer.add(animation, forKey: "shimmer")
    }

    /// 시나리오 1: Shimmer 3초 타임아웃 → 자동으로 폴백 배너 전환
    private func startShimmerTimeout() {
        cancelShimmerTimeout()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isAdLoaded else { return }
            self.transitionToFallback()
        }
        shimmerTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
    }

    private func cancelShimmerTimeout() {
        shimmerTimeoutWork?.cancel()
        shimmerTimeoutWork = nil
    }
}

// MARK: - Custom Page Control

extension AdImageCollectionViewCell {

    private func setupPageDots() {
        pageControlStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for _ in 0..<imgBanners.count {
            let dot = UIView()
            dot.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            dot.layer.cornerRadius = 2
            dot.snp.makeConstraints {
                $0.width.height.equalTo(4)
            }
            pageControlStack.addArrangedSubview(dot)
        }
        updatePageDots()
    }

    private func updatePageDots() {
        let activeIndex = currentPage % imgBanners.count
        for (index, dot) in pageControlStack.arrangedSubviews.enumerated() {
            let isActive = index == activeIndex
            dot.backgroundColor = isActive ? .white : UIColor.white.withAlphaComponent(0.5)
            dot.layer.cornerRadius = 2
            dot.snp.remakeConstraints {
                $0.width.equalTo(isActive ? 16 : 4)
                $0.height.equalTo(4)
            }
        }
        UIView.animate(withDuration: 0.2) {
            self.pageControlStack.layoutIfNeeded()
        }
        updateAccessibility()
    }
}

// MARK: - Auto Scroll

extension AdImageCollectionViewCell {

    private func startAutoScroll() {
        stopAutoScroll()

        guard !UIAccessibility.isReduceMotionEnabled else { return }

        currentPage = imgBanners.count
        bannerCollectionView.scrollToItem(
            at: IndexPath(item: currentPage, section: 0),
            at: .centeredHorizontally,
            animated: false
        )

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
    }

    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }

    private func scrollToNextPage() {
        currentPage += 1
        if currentPage >= imgBanners.count * 2 {
            currentPage = imgBanners.count
            bannerCollectionView.scrollToItem(
                at: IndexPath(item: currentPage, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
        }

        let indexPath = IndexPath(item: currentPage, section: 0)
        let animated = !UIAccessibility.isReduceMotionEnabled
        bannerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        updatePageDots()
    }
}

// MARK: - Accessibility

extension AdImageCollectionViewCell {

    private func updateAccessibility() {
        let activeIndex = (currentPage % imgBanners.count) + 1
        isAccessibilityElement = true
        accessibilityLabel = "프로모션 배너, \(activeIndex)/\(imgBanners.count)"
    }
}

// MARK: - UIScrollViewDelegate

extension AdImageCollectionViewCell: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === bannerCollectionView, scrollView.frame.width > 0 else { return }
        currentPage = Int(scrollView.contentOffset.x / scrollView.frame.width)
        updatePageDots()
    }
}

// MARK: - Fallback Banner Setup

extension AdImageCollectionViewCell {

    private func setFallbackBanner() {
        bannerCollectionView.delegate = self
        bannerCollectionView.dataSource = self
        bannerCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "BannerCell")
    }
}

// MARK: - Layout

extension AdImageCollectionViewCell {

    private func setLayout() {
        contentView.backgroundColor = .clear
        contentView.addSubview(shadowView)
        shadowView.addSubview(containerView)
        containerView.addSubviews(bannerView, bannerCollectionView, shimmerView, gradientView, adLabelContainer, pageControlStack)
        adLabelContainer.contentView.addSubview(adLabel)

        shadowView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(8)
        }

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        bannerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        bannerCollectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        shimmerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        gradientView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(48)
        }
        setupGradient()

        adLabelContainer.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
            $0.height.equalTo(22)
        }

        adLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(8)
        }

        pageControlStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(12)
        }

        // 초기 상태: 모든 콘텐츠 숨기고 shimmer만 표시
        bannerView.isHidden = false
        bannerView.alpha = 0
        bannerCollectionView.isHidden = true
        adLabelContainer.alpha = 0
        gradientView.isHidden = true
        pageControlStack.isHidden = true
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientView.layer.addSublayer(gradientLayer)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension AdImageCollectionViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgBanners.count * 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BannerCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let imageIndex = indexPath.item % imgBanners.count
        let imageView = UIImageView().then {
            $0.image = imgBanners[imageIndex]
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }
        cell.contentView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension AdImageCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return containerView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
