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

    // MARK: - Types

    private enum PageType {
        case image(UIImage)
        case nativeAd(GADNativeAd)
    }

    // MARK: - Constants

    private static let adPageInterval: TimeInterval = 5.0
    private static let imagePageInterval: TimeInterval = 4.0
    private static let adFreeAppLaunchThreshold = 1
    private static let nativeAdCellReuseId = "NativeAdCarouselCell"

    // MARK: - Properties

    weak var delegate: AdImageCollectionViewCellDelegate?
    private var nativeAd1: GADNativeAd?
    private var nativeAd2: GADNativeAd?
    private var adsResponseCount = 0
    private var carouselShown = false
    private var shimmerTimeoutWork: DispatchWorkItem?
    private var autoScrollWork: DispatchWorkItem?
    private let imgBanners: [UIImage] = [ImageLiterals.imgBanner1, ImageLiterals.imgBanner2, ImageLiterals.imgBanner3]
    private var pages: [PageType] = []
    private var currentPage: Int = 0
    private var lastLayoutSize: CGSize = .zero
    private weak var cachedParentScrollView: UIScrollView?

    private var adLoader1: GADAdLoader?
    private var adLoader2: GADAdLoader?
    private weak var rootViewController: UIViewController?

    private var shouldShowAds: Bool {
        guard UserManager.shared.userType != .visitor else { return false }
        let launchCount = UserDefaultKeyList.Ad.appLaunchCount ?? 0
        return launchCount > Self.adFreeAppLaunchThreshold
    }

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

    // MARK: - UI Components (Carousel)

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
        pages = imgBanners.map { .image($0) }
        setLayout()
        setCarousel()
        setupShimmer()
        setupPageDots()
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

        // containerView bounds가 변경된 경우에만 carousel cell 크기를 갱신 (1회성)
        let currentSize = containerView.bounds.size
        if currentSize != .zero && currentSize != lastLayoutSize {
            lastLayoutSize = currentSize
            bannerCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAutoScroll()
        cachedParentScrollView = nil
    }

    deinit {
        autoScrollWork?.cancel()
        shimmerTimeoutWork?.cancel()
    }
}

// MARK: - AdMob

extension AdImageCollectionViewCell {

    func setRootViewController(_ viewController: UIViewController, skipReload: Bool = false) {
        rootViewController = viewController

        guard shouldShowAds else {
            if skipReload && carouselShown { return }
            skipAdsAndShowCarousel()
            return
        }

        if skipReload && carouselShown {
            return
        }
        loadNativeAds()
    }

    private func skipAdsAndShowCarousel() {
        pages = imgBanners.map { .image($0) }
        carouselShown = true
        showCarousel()
        delegate?.adBannerDidFailToReceiveAd()
    }

    private func loadNativeAds() {
        adsResponseCount = 0
        nativeAd1 = nil
        nativeAd2 = nil

        adLoader1 = GADAdLoader(
            adUnitID: AdConfig.carouselNativeAdUnitId,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: nil
        )
        adLoader1?.delegate = self

        adLoader2 = GADAdLoader(
            adUnitID: AdConfig.carouselNativeAdUnitId,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: nil
        )
        adLoader2?.delegate = self

        adLoader1?.load(GADRequest())
        adLoader2?.load(GADRequest())

        showShimmer()
        startShimmerTimeout()
    }

    private func handleAdResponse() {
        adsResponseCount += 1
        if adsResponseCount >= 2 {
            buildPagesAndShowCarousel()
        }
    }

    private func buildPagesAndShowCarousel() {
        guard !carouselShown else { return }
        carouselShown = true

        buildPages()
        showCarousel()

        if nativeAd1 != nil || nativeAd2 != nil {
            delegate?.adBannerDidReceiveAd()
            analyze(buttonName: GAEvent.Button.clickTryBanner)
        } else {
            delegate?.adBannerDidFailToReceiveAd()
        }
    }

    /// 광고 로드 상태에 따라 페이지 배열 구성: [배너1, 광고1?, 배너2, 광고2?, 배너3]
    private func buildPages() {
        var result: [PageType] = []
        result.append(.image(imgBanners[0]))
        if let ad1 = nativeAd1 {
            result.append(.nativeAd(ad1))
        }
        result.append(.image(imgBanners[1]))
        if let ad2 = nativeAd2 {
            result.append(.nativeAd(ad2))
        }
        result.append(.image(imgBanners[2]))
        pages = result
    }

    private func showCarousel() {
        cancelShimmerTimeout()

        bannerCollectionView.reloadData()
        setupPageDots()

        bannerCollectionView.isHidden = false
        gradientView.isHidden = false
        pageControlStack.isHidden = false

        bannerCollectionView.alpha = 0
        gradientView.alpha = 0
        pageControlStack.alpha = 0

        let duration: TimeInterval = UIAccessibility.isReduceMotionEnabled ? 0 : 0.3

        UIView.animate(withDuration: duration, animations: {
            self.shimmerView.alpha = 0
            self.bannerCollectionView.alpha = 1
            self.gradientView.alpha = 1
            self.pageControlStack.alpha = 1
        }, completion: { _ in
            self.shimmerView.isHidden = true
            self.shimmerView.alpha = 1
            self.shimmerGradientLayer.removeAnimation(forKey: "shimmer")
            self.startAutoScroll()
            self.updateAdPillVisibility()
        })
    }
}

// MARK: - GADAdLoaderDelegate, GADNativeAdLoaderDelegate

extension AdImageCollectionViewCell: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        if adLoader === adLoader1 {
            nativeAd1 = nativeAd
        } else if adLoader === adLoader2 {
            nativeAd2 = nativeAd
        }
        handleAdResponse()
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("[AdMob] 네이티브 광고 로드 실패: \(error.localizedDescription)")
        if adLoader === adLoader1 {
            nativeAd1 = nil
        } else if adLoader === adLoader2 {
            nativeAd2 = nil
        }
        handleAdResponse()
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

    /// 3초 타임아웃: 응답 안 온 광고는 포기하고 캐러셀 표시
    private func startShimmerTimeout() {
        cancelShimmerTimeout()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.buildPagesAndShowCarousel()
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
        for _ in 0..<pages.count {
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
        guard !pages.isEmpty else { return }
        let activeIndex = currentPage % pages.count

        let isAdPage: Bool
        if case .nativeAd = pages[activeIndex] {
            isAdPage = true
        } else {
            isAdPage = false
        }

        let activeColor: UIColor = isAdPage ? .m1 : .white
        let inactiveColor: UIColor = isAdPage ? UIColor.m1.withAlphaComponent(0.3) : UIColor.white.withAlphaComponent(0.5)

        for (index, dot) in pageControlStack.arrangedSubviews.enumerated() {
            let isActive = index == activeIndex
            dot.backgroundColor = isActive ? activeColor : inactiveColor
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

    private func updateAdPillVisibility() {
        guard !pages.isEmpty else {
            adLabelContainer.alpha = 0
            return
        }
        let pageIndex = currentPage % pages.count
        let isAdPage: Bool
        if case .nativeAd = pages[pageIndex] {
            isAdPage = true
        } else {
            isAdPage = false
        }

        UIView.animate(withDuration: 0.2) {
            self.adLabelContainer.alpha = isAdPage ? 1 : 0
            self.gradientView.alpha = isAdPage ? 0 : 1
        }
        updateDotColors(isAdPage: isAdPage)
    }

    private func updateDotColors(isAdPage: Bool) {
        let activeColor: UIColor = isAdPage ? .m1 : .white
        let inactiveColor: UIColor = isAdPage ? UIColor.m1.withAlphaComponent(0.3) : UIColor.white.withAlphaComponent(0.5)

        guard !pages.isEmpty else { return }
        let activeIndex = currentPage % pages.count
        for (index, dot) in pageControlStack.arrangedSubviews.enumerated() {
            dot.backgroundColor = index == activeIndex ? activeColor : inactiveColor
        }
    }
}

// MARK: - Auto Scroll

extension AdImageCollectionViewCell {

    private func currentPageInterval() -> TimeInterval {
        guard !pages.isEmpty else { return Self.imagePageInterval }
        let pageIndex = currentPage % pages.count
        if case .nativeAd = pages[pageIndex] {
            return Self.adPageInterval
        }
        return Self.imagePageInterval
    }

    func resumeAutoScrollIfNeeded() {
        guard carouselShown, autoScrollWork == nil else { return }
        scheduleNextScroll()
    }

    private func startAutoScroll() {
        stopAutoScroll()

        guard !UIAccessibility.isReduceMotionEnabled, !pages.isEmpty else { return }

        currentPage = pages.count
        bannerCollectionView.scrollToItem(
            at: IndexPath(item: currentPage, section: 0),
            at: .centeredHorizontally,
            animated: false
        )

        scheduleNextScroll()
    }

    private func scheduleNextScroll() {
        autoScrollWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.scrollToNextPage()
        }
        autoScrollWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + currentPageInterval(), execute: work)
    }

    private func stopAutoScroll() {
        autoScrollWork?.cancel()
        autoScrollWork = nil
    }

    private func scrollToNextPage() {
        guard !pages.isEmpty else { return }
        currentPage += 1
        if currentPage >= pages.count * 2 {
            currentPage = pages.count
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
        updateAdPillVisibility()
        scheduleNextScroll()
    }
}

// MARK: - Accessibility

extension AdImageCollectionViewCell {

    private func updateAccessibility() {
        guard !pages.isEmpty else { return }
        let pageIndex = currentPage % pages.count
        let isAdPage: Bool
        if case .nativeAd = pages[pageIndex] {
            isAdPage = true
        } else {
            isAdPage = false
        }

        isAccessibilityElement = true
        if isAdPage {
            accessibilityLabel = "광고 배너, \(pageIndex + 1)/\(pages.count)"
        } else {
            accessibilityLabel = "프로모션 배너, \(pageIndex + 1)/\(pages.count)"
        }
    }
}

// MARK: - UIScrollViewDelegate

extension AdImageCollectionViewCell: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView === bannerCollectionView else { return }
        // 배너 가로 스와이프 시 상위 세로 스크롤 잠금
        findParentScrollView()?.isScrollEnabled = false
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === bannerCollectionView else { return }
        if !decelerate {
            findParentScrollView()?.isScrollEnabled = true
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === bannerCollectionView, scrollView.frame.width > 0 else { return }

        findParentScrollView()?.isScrollEnabled = true

        currentPage = Int(scrollView.contentOffset.x / scrollView.frame.width)

        // 무한 스크롤: 양 끝에 도달하면 중간 범위로 리셋
        if !pages.isEmpty {
            if currentPage < pages.count {
                currentPage += pages.count
                bannerCollectionView.scrollToItem(
                    at: IndexPath(item: currentPage, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
            } else if currentPage >= pages.count * 2 {
                currentPage -= pages.count
                bannerCollectionView.scrollToItem(
                    at: IndexPath(item: currentPage, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
            }
        }

        updatePageDots()
        updateAdPillVisibility()
        scheduleNextScroll()
    }

    private func findParentScrollView() -> UIScrollView? {
        if let cached = cachedParentScrollView { return cached }
        var view = superview
        while let v = view {
            if let scrollView = v as? UIScrollView, scrollView !== bannerCollectionView {
                cachedParentScrollView = scrollView
                return scrollView
            }
            view = v.superview
        }
        return nil
    }
}

// MARK: - Carousel Setup

extension AdImageCollectionViewCell {

    private func setCarousel() {
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
        containerView.addSubviews(bannerCollectionView, shimmerView, gradientView, adLabelContainer, pageControlStack)
        adLabelContainer.contentView.addSubview(adLabel)

        shadowView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(8)
        }

        containerView.snp.makeConstraints {
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

        // 초기 상태: shimmer만 표시
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
        return pages.count * 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BannerCell", for: indexPath)
        guard !pages.isEmpty else { return cell }

        let pageIndex = indexPath.item % pages.count
        switch pages[pageIndex] {
        case .image(let image):
            cell.contentView.backgroundColor = .clear
            if let imageView = cell.contentView.viewWithTag(100) as? UIImageView {
                imageView.image = image
            } else {
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                let imageView = UIImageView()
                imageView.tag = 100
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.image = image
                cell.contentView.addSubview(imageView)
                imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
            }

        case .nativeAd(let nativeAd):
            cell.contentView.backgroundColor = .w1
            // 기존 nativeAdView 재사용 (tag 200)
            if let existingAdView = cell.contentView.viewWithTag(200) as? GADNativeAdView {
                configureNativeAdView(existingAdView, with: nativeAd)
            } else {
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                let nativeAdView = makeNativeAdView()
                nativeAdView.tag = 200
                cell.contentView.addSubview(nativeAdView)
                nativeAdView.snp.makeConstraints { $0.edges.equalToSuperview() }
                configureNativeAdView(nativeAdView, with: nativeAd)
            }
        }
        return cell
    }
}

// MARK: - Native Ad View Builder

extension AdImageCollectionViewCell {

    private func makeNativeAdView() -> GADNativeAdView {
        let adView = GADNativeAdView()
        adView.tag = 200

        let mediaView = GADMediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.tag = 201

        let overlayContainer = UIView()
        overlayContainer.tag = 205

        let headlineLabel = UILabel()
        headlineLabel.font = .b4
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 1
        headlineLabel.tag = 202

        let advertiserLabel = UILabel()
        advertiserLabel.font = .b6
        advertiserLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        advertiserLabel.numberOfLines = 1
        advertiserLabel.tag = 203

        let adBadge = UILabel()
        adBadge.text = "광고"
        adBadge.font = .b9
        adBadge.textColor = .w1
        adBadge.backgroundColor = .m1
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true
        adBadge.tag = 204

        let overlayGradient = UIView()
        overlayGradient.tag = 206
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.5).cgColor
        ]
        gradient.locations = [0.4, 1.0]
        overlayGradient.layer.addSublayer(gradient)

        adView.addSubview(mediaView)
        adView.addSubview(overlayGradient)
        adView.addSubview(overlayContainer)
        overlayContainer.addSubview(headlineLabel)
        overlayContainer.addSubview(advertiserLabel)
        adView.addSubview(adBadge)

        adView.mediaView = mediaView
        adView.headlineView = headlineLabel
        adView.advertiserView = advertiserLabel

        mediaView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        overlayGradient.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalToSuperview().multipliedBy(0.5)
        }

        overlayContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(12)
        }

        headlineLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        advertiserLabel.snp.makeConstraints {
            $0.top.equalTo(headlineLabel.snp.bottom).offset(2)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        adBadge.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(8)
            $0.width.equalTo(30)
            $0.height.equalTo(16)
        }

        return adView
    }

    private func configureNativeAdView(_ adView: GADNativeAdView, with nativeAd: GADNativeAd) {
        adView.nativeAd = nativeAd

        if let mediaView = adView.viewWithTag(201) as? GADMediaView {
            mediaView.mediaContent = nativeAd.mediaContent
        }

        if let headlineLabel = adView.viewWithTag(202) as? UILabel {
            headlineLabel.text = nativeAd.headline
        }

        if let advertiserLabel = adView.viewWithTag(203) as? UILabel {
            advertiserLabel.text = nativeAd.advertiser
            advertiserLabel.isHidden = nativeAd.advertiser == nil
        }

        // overlayGradient 레이어 프레임 갱신
        if let overlayGradient = adView.viewWithTag(206) {
            DispatchQueue.main.async {
                if let gradientLayer = overlayGradient.layer.sublayers?.first as? CAGradientLayer {
                    gradientLayer.frame = overlayGradient.bounds
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension AdImageCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = containerView.bounds.size
        guard size.width > 0 && size.height > 0 else {
            let bannerWidth = UIScreen.main.bounds.width - 32
            let bannerHeight = bannerWidth * (174.0 / 390.0)
            return CGSize(width: bannerWidth, height: bannerHeight)
        }
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
