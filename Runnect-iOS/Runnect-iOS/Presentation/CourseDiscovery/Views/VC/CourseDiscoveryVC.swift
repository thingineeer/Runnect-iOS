//
//  CourseDiscoveryVC.swift
//  Runnect-iOS
//
//  Created by 이명진 on 2023/11/21.
//

import UIKit
import Then
import SnapKit
import Combine
import Moya
import GoogleMobileAds
import Kingfisher

protocol ScrapStateDelegate: AnyObject {
    func didUpdateScrapState(publicCourseId: Int, isScrapped: Bool)
    func didRemoveCourse(publicCourseId: Int)
    // 코스 상세 에서 스크랩 누르면 코스발견에 해당 부분 스크랩 누르는 이벤트 전달
}

protocol UploadSuccessDelegate: AnyObject {
    // 코스 업로드시, 코스 발견 피드 새로 고침
    func didUploadSuccess()
}

final class CourseDiscoveryVC: UIViewController {
    
    // MARK: - Properties
    
    private let publicCourseProvider = Providers.publicCourseProvider
    private let scrapProvider = Providers.scrapProvider
    private let serverResponseNumber = 10
    
    private var courseList = [PublicCourse]()
    private var cancelBag = CancelBag()
    private var specialList = [String]()
    private var totalPageNum = 0
    private var isEnd: Bool = false
    private var pageNo: Int = 1
    private var sort = "date"
    private var isFetchingData = false

    /// 남은 아이템이 이 수 이하일 때 다음 페이지 프리페치 시작
    private let prefetchThreshold = 6

    // MARK: - Native Ad Properties

    private static let nativeAdInterval = 10
    private static let maxNativeAds = 3
    private static let adFreeAppLaunchThreshold = 3

    private var nativeAds = [GADNativeAd]()
    private var adLoader: GADAdLoader?

    private var shouldShowNativeAds: Bool {
        guard UserManager.shared.userType != .visitor else { return false }
        let launchCount = UserDefaultKeyList.Ad.appLaunchCount ?? 0
        return launchCount > Self.adFreeAppLaunchThreshold
    }
    
    // MARK: - UIComponents
    
    private lazy var naviBar = CustomNavigationBar(self, type: .title).setTitle("코스 발견")
    
    private let searchButton = UIButton(type: .system).then {
        $0.setImage(ImageLiterals.icSearch, for: .normal)
        $0.tintColor = .g3
    }
    private let uploadButton = CustomButton(title: "업로드").then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 20
        $0.setImage(ImageLiterals.icPlus, for: .normal)
        $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        $0.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
    }
    
    private let miniUploadButton = UIButton(type: .system).then {
        $0.setImage(ImageLiterals.icPlusButton, for: .normal)
    }
    
    private let emptyView = ListEmptyView(description: "공유할 수 있는 코스가 없어요!\n코스를 그려주세요",
                                          buttonTitle: "코스 그리기")
    
    // MARK: - collectionview
    
    private lazy var mapCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad () {
        super.viewDidLoad()
        setUI()
        register()
        setNavigationBar()
        setDelegate()
        setLayout()
        setAddTarget()
        setCombineEvent()
        loadNativeAds()
        self.getCourseData(pageNo: pageNo)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideTabBar(wantsToHide: false)
    }
}

// MARK: - Methods

extension CourseDiscoveryVC {
    
    private func setData(courseList: [PublicCourse]) {
        self.courseList = courseList
        mapCollectionView.reloadData()
        self.emptyView.isHidden = !courseList.isEmpty
    }
    
    private func setDelegate() {
        mapCollectionView.delegate = self
        mapCollectionView.dataSource = self
        mapCollectionView.prefetchDataSource = self
        emptyView.delegate = self
    }
    
    private func register() {
        let cellTypes: [UICollectionViewCell.Type] = [AdImageCollectionViewCell.self,
                                                      MarathonTitleCollectionViewCell.self,
                                                      MarathonMapCollectionViewCell.self,
                                                      TitleCollectionViewCell.self,
                                                      CourseListCVC.self,
                                                      NativeAdCVC.self]
        cellTypes.forEach { cellType in
            mapCollectionView.register(cellType, forCellWithReuseIdentifier: cellType.className)
        }
    }
    
    private func setAddTarget() {
        self.searchButton.addTarget(self, action: #selector(pushToSearchVC), for: .touchUpInside)
        self.uploadButton.addTarget(self, action: #selector(pushToCourseSelectVC), for: .touchUpInside)
        self.miniUploadButton.addTarget(self, action: #selector(pushToCourseSelectVC), for: .touchUpInside)
    }
    
    private func setCombineEvent() {
        CourseSelectionPublisher.shared.didSelectCourse
            .sink { [weak self] indexPath in
                self?.setMarathonCourseSelection(at: indexPath)
            }
            .store(in: cancelBag)
    }
    
    private func reloadCellForCourse(publicCourseId: Int) {
        if let index = courseList.firstIndex(where: { $0.id == publicCourseId }) {
            let collectionViewItem = collectionViewItem(for: index)
            let indexPath = IndexPath(item: collectionViewItem, section: Section.courseList)
            mapCollectionView.reloadItems(at: [indexPath])
            print("\(indexPath) 부분 스크랩 교체 되었음")
        }
    }

    // MARK: - Native Ad Helpers

    /// 광고가 삽입되는 위치인지 확인
    private func isAdPosition(at item: Int) -> Bool {
        guard shouldShowNativeAds, !nativeAds.isEmpty else { return false }
        guard item > 0 else { return false }
        // 매 10개 코스 뒤 (item 10, 21, 32, ...)
        // item 10 -> 광고 0번째 (코스 0~9 뒤)
        // item 21 -> 광고 1번째 (코스 10~19 뒤)
        let adInterval = Self.nativeAdInterval + 1 // 코스 10개 + 광고 1개 = 11개 단위
        if (item + 1) % adInterval == 0 {
            let adIndex = (item + 1) / adInterval - 1
            return adIndex < nativeAds.count
        }
        return false
    }

    /// collectionView item 인덱스에서 실제 courseList 인덱스로 변환
    private func courseIndex(for item: Int) -> Int {
        guard shouldShowNativeAds, !nativeAds.isEmpty else { return item }
        let adInterval = Self.nativeAdInterval + 1
        let adsBefore = item / adInterval // 이 item 이전에 삽입된 광고 수
        // 현재 위치가 광고면 이 함수를 호출하면 안됨
        return item - adsBefore
    }

    /// courseList 인덱스에서 collectionView item 인덱스로 변환
    private func collectionViewItem(for courseIndex: Int) -> Int {
        guard shouldShowNativeAds, !nativeAds.isEmpty else { return courseIndex }
        let adInterval = Self.nativeAdInterval
        let adsBefore = min(courseIndex / adInterval, nativeAds.count)
        return courseIndex + adsBefore
    }

    /// 광고 포함 전체 아이템 수
    private func totalItemCount() -> Int {
        let courseCount = courseList.count
        guard shouldShowNativeAds, !nativeAds.isEmpty else { return courseCount }
        let possibleAds = min(courseCount / Self.nativeAdInterval, nativeAds.count)
        return courseCount + possibleAds
    }

    /// 해당 item의 광고 인덱스 반환
    private func nativeAdIndex(for item: Int) -> Int {
        let adInterval = Self.nativeAdInterval + 1
        return (item + 1) / adInterval - 1
    }

    func refresh() {
        print("refresh")
        pageNo = 1
        isFetchingData = false
        self.courseList = []
        self.getCourseData(pageNo: pageNo)
    }
}

// MARK: - @objc Function

extension CourseDiscoveryVC {
    @objc private func pushToSearchVC() {
        let nextVC = CourseSearchVC()
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    
    @objc private func pushToCourseSelectVC() {
        guard UserManager.shared.userType != .visitor else {
            self.showToastOnWindow(text: "러넥트에 가입하면 코스를 업로드할 수 있어요.")
            
            analyze(buttonName: GAEvent.Button.clickJoinInCourseDiscovery)
            return
        }
        
        analyze(buttonName: GAEvent.Button.clickUploadButton)
        
        let nextVC = MyCourseSelectVC()
        nextVC.delegate = self
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}

// MARK: - UI & Layout

extension CourseDiscoveryVC {
    private func setUI() {
        view.backgroundColor = .w1
        mapCollectionView.backgroundColor = .w1
        self.emptyView.isHidden = true
        self.miniUploadButton.alpha = 0.0 /// 이거 없으면 처음에 UIView.animate 효과 보임
    }
    
    private func setNavigationBar() {
        view.addSubview(naviBar)
        view.addSubview(searchButton)
        
        naviBar.snp.makeConstraints {
            $0.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }
        searchButton.snp.makeConstraints {
            $0.trailing.equalTo(self.view.safeAreaLayoutGuide).inset(16)
            $0.centerY.equalTo(naviBar)
        }
    }
    
    private func setLayout() {
        view.addSubviews(mapCollectionView, uploadButton, miniUploadButton)
        view.bringSubviewToFront(uploadButton)
        view.bringSubviewToFront(miniUploadButton)
        mapCollectionView.addSubview(emptyView)
        
        mapCollectionView.snp.makeConstraints {
            $0.top.equalTo(self.naviBar.snp.bottom)
            $0.leading.bottom.trailing.equalTo(view.safeAreaLayoutGuide)
        }
        
        uploadButton.snp.makeConstraints {
            $0.trailing.equalTo(self.view.safeAreaLayoutGuide).inset(21)
            $0.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(40)
            $0.width.equalTo(92)
        }
        
        miniUploadButton.snp.makeConstraints {
            $0.trailing.equalTo(self.view.safeAreaLayoutGuide).inset(22)
            $0.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(20)
        }
        
        emptyView.snp.makeConstraints {
            $0.top.equalTo(naviBar.snp.bottom).offset(300)
            $0.centerX.equalTo(naviBar)
        }
        
        self.view.bringSubviewToFront(uploadButton)
        self.view.bringSubviewToFront(miniUploadButton)
        
    }
}

// MARK: - Constants

extension CourseDiscoveryVC {
    private enum Section {
        static let adImage = 0 // 광고 이미지
        static let marathonTitle = 1 // 마라톤 코스 설명
        static let marathonCourseList = 2 // 마라톤 코스
        static let title = 3 // 추천 코스 설명
        static let courseList = 4 // 추천 코스
    }
    
    private enum Layout {
        static let cellSpacing: CGFloat = 20
        static let interitemSpacing: CGFloat = 10
        static let sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension CourseDiscoveryVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case Section.adImage, Section.marathonTitle, Section.marathonCourseList, Section.title:
            return 1
        case Section.courseList:
            return totalItemCount()
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case Section.adImage:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AdImageCollectionViewCell.className, for: indexPath) as? AdImageCollectionViewCell else { return UICollectionViewCell() }
            cell.setRootViewController(self)
            return cell
        case Section.marathonTitle:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MarathonTitleCollectionViewCell.className, for: indexPath) as? MarathonTitleCollectionViewCell else { return UICollectionViewCell() }
            return cell
        case Section.marathonCourseList:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MarathonMapCollectionViewCell.className, for: indexPath) as? MarathonMapCollectionViewCell else { return UICollectionViewCell() }
            return cell
        case Section.title:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitleCollectionViewCell.className, for: indexPath) as? TitleCollectionViewCell else { return UICollectionViewCell() }
            cell.delegate = self
            return cell
        case Section.courseList:
            if isAdPosition(at: indexPath.item) {
                return nativeAdCell(collectionView: collectionView, indexPath: indexPath)
            }
            return courseListCell(collectionView: collectionView, indexPath: indexPath)
        default:
            return UICollectionViewCell()
        }
    }
    
    // 최신순, 스크랩순 막 연달아 누르면 앱 터짐..
    private func courseListCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseListCVC.className, for: indexPath) as? CourseListCVC else { return UICollectionViewCell() }
        cell.setCellType(type: .all)
        cell.delegate = self
        let realIndex = courseIndex(for: indexPath.item)
        guard realIndex < courseList.count else { return UICollectionViewCell() }
        let model = self.courseList[realIndex]
        let location = "\(model.departure.region) \(model.departure.city)"
        cell.setData(imageURL: model.image, title: model.title, location: location, didLike: model.scrap, indexPath: realIndex)
        return cell
    }

    private func nativeAdCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NativeAdCVC.className, for: indexPath) as? NativeAdCVC else { return UICollectionViewCell() }
        let adIndex = nativeAdIndex(for: indexPath.item)
        if adIndex < nativeAds.count {
            cell.configure(with: nativeAds[adIndex])
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CourseDiscoveryVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        
        switch indexPath.section {
        case Section.adImage:
            let bannerWidth = screenWidth - 32
            let bannerHeight = bannerWidth * (174.0 / 390.0)
            return CGSize(width: screenWidth, height: bannerHeight + 20)
        case Section.marathonTitle:
            return CGSize(width: screenWidth, height: 98)
        case Section.marathonCourseList:
            return CGSize(width: screenWidth, height: 194)
        case Section.title:
            return CGSize(width: screenWidth, height: 106)
        case Section.courseList:
            let cellWidth = (screenWidth - 42) / 2
            if isAdPosition(at: indexPath.item) {
                // 네이티브 광고: 코스 셀과 동일한 크기 (2열 그리드 중 1칸)
                let cellHeight = CourseListCVCType.getCellHeight(type: .all, cellWidth: cellWidth)
                return CGSize(width: cellWidth, height: cellHeight)
            }
            let cellHeight = CourseListCVCType.getCellHeight(type: .all, cellWidth: cellWidth)
            return CGSize(width: cellWidth, height: cellHeight)
        default:
            return CGSize(width: 0, height: 0)
        }
    }
    
    /// section 이 4일때만 정해진 레이아웃 리턴
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return section == Section.courseList ? Layout.cellSpacing : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return section == Section.courseList ? Layout.interitemSpacing : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return section == Section.courseList ? Layout.sectionInset : .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == Section.courseList {
            guard !isAdPosition(at: indexPath.item) else { return }
            let realIndex = courseIndex(for: indexPath.item)
            guard realIndex < courseList.count else { return }
            let courseDetailVC = CourseDetailVC()
            courseDetailVC.delegate = self
            let courseModel = courseList[realIndex]
            courseDetailVC.setCourseId(courseId: courseModel.courseId, publicCourseId: courseModel.id)
            courseDetailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(courseDetailVC, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == Section.courseList else { return }

        let totalItems = totalItemCount()
        let remainingItems = totalItems - indexPath.item - 1

        // 남은 아이템이 threshold 이하이면 다음 페이지 로드
        if remainingItems <= prefetchThreshold {
            loadNextPageIfNeeded()
        }
    }

    /// 다음 페이지 로드 조건을 확인하고 로드
    private func loadNextPageIfNeeded() {
        // 이미 로딩 중이면 무시
        guard !isFetchingData else { return }
        // 마지막 페이지면 무시
        guard pageNo < totalPageNum else { return }
        // 현재 페이지의 데이터가 다 안 왔으면 무시
        guard courseList.count >= pageNo * serverResponseNumber else { return }

        pageNo += 1
        getCourseData(pageNo: pageNo)
    }
    
    // 외부에서 Marathon Cell에서 받아오는 indexPath를 처리 합니다.
    private func setMarathonCourseSelection(at indexPath: IndexPath) {
        if let marathonCell = mapCollectionView.cellForItem(at: IndexPath(item: 0, section: Section.marathonCourseList)) as? MarathonMapCollectionViewCell {
            let marathonCourseList = marathonCell.marathonCourseList
            let courseDetailVC = CourseDetailVC()
            courseDetailVC.marathonDelegate = marathonCell
            let courseModel = marathonCourseList[indexPath.item]
            courseDetailVC.setCourseId(courseId: courseModel.courseId, publicCourseId: courseModel.id)
            courseDetailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(courseDetailVC, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension CourseDiscoveryVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        changeButtonStyleOnScroll()
    }
    
    private func changeButtonStyleOnScroll() {
        let contentOffsetY = mapCollectionView.contentOffset.y
        let scrollThreshold = mapCollectionView.bounds.size.height * 0.1 // 10% 스크롤 했으면 UI 변경
        
        UIView.animate(withDuration: 0.25) {
            if contentOffsetY > scrollThreshold {
                // 10% 이상 스크롤 했을 때
                self.downScroll()
            } else {
                self.upScroll()
            }
        }
    }
    
    private func downScroll() {
        self.uploadButton.transform = CGAffineTransform(scaleX: 0.3, y: 0.96)
        self.miniUploadButton.frame.origin.x = 332 // 직접 피그마보고 상수 맞췄습니다.
        self.uploadButton.alpha = 0.0
        self.miniUploadButton.alpha = 1.0
    }
    
    private func upScroll() {
        self.uploadButton.transform = .identity
        self.miniUploadButton.alpha = 0.0
        self.uploadButton.alpha = 1.0
        self.miniUploadButton.frame.origin.x = 276
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension CourseDiscoveryVC: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let imageURLs = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.section == Section.courseList else { return nil }
            guard !isAdPosition(at: indexPath.item) else { return nil }
            let realIndex = courseIndex(for: indexPath.item)
            guard realIndex < courseList.count else { return nil }
            return URL(string: courseList[realIndex].image)
        }

        guard !imageURLs.isEmpty else { return }
        ImagePrefetcher(urls: imageURLs).start()
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let imageURLs = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.section == Section.courseList else { return nil }
            guard !isAdPosition(at: indexPath.item) else { return nil }
            let realIndex = courseIndex(for: indexPath.item)
            guard realIndex < courseList.count else { return nil }
            return URL(string: courseList[realIndex].image)
        }

        guard !imageURLs.isEmpty else { return }
        ImagePrefetcher(urls: imageURLs).stop()
    }
}

// MARK: - CourseListCVCDelegate

extension CourseDiscoveryVC: CourseListCVCDelegate {
    func likeButtonTapped(wantsTolike: Bool, index: Int) {
        guard UserManager.shared.userType != .visitor else {
            showToastOnWindow(text: "러넥트에 가입하면 코스를 스크랩할 수 있어요")
            return
        }
        
        let publicCourseId = courseList[index].id
        self.scrapCourse(publicCourseId: publicCourseId, scrapTF: wantsTolike)
    }
}

// MARK: - CourseDetailVCDelegate

extension CourseDiscoveryVC: ScrapStateDelegate {
    func didUpdateScrapState(publicCourseId: Int, isScrapped: Bool) {
        // CourseDetail에서 id와 scrap정보를 받아와 여기서 처리
        if let index = courseList.firstIndex(where: { $0.id == publicCourseId }) {
            courseList[index].scrap = isScrapped
            reloadCellForCourse(publicCourseId: publicCourseId)
            print("‼️CourseDiscoveryVC 델리게이트 받음 index=\(index)")
        }
    }
    
    func didRemoveCourse(publicCourseId: Int) {
        //        if let index = courseList.firstIndex(where: { $0.id == publicCourseId }) {
        //            courseList.remove(at: index)
        //            self.mapCollectionView.reloadData()
        //        }
        // ⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️
        // 원래 해당하는 데이터(index) 만 가지고, 그 데이터 삭제 후 courseList를 받아야하는데, 삭제가 이미되어버려서 if let index 부분이 안들어옴
        // 왜??? 이미 데이터는 삭제가 되어서 $0.id 랑 publicCourseId 가 같은게 매치가 될 수 없어!!!
        // 네트워크 성공하기 전에 didRemoveCourse(publicCourseId:) 를 호출 해야 해당 부분 확인하고 지운다음, 서버측에서 지워야 1페이지부터 시작 안하고 지울 수 있음
        // ⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️
        self.refresh()
    }
}

// MARK: - didUploadCourse

extension CourseDiscoveryVC: UploadSuccessDelegate {
    func didUploadSuccess() {
        print("여기서 didUploadSuccess 함수 호출\n MyCourseSelectVC -> CourseDiscoveryVC 이벤트 전달")
        self.refresh()
        print("코스 발견 피드 새로고침 완료 되었음")
    }
}

// MARK: - Native Ad Loading

extension CourseDiscoveryVC: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {
    private func loadNativeAds() {
        guard shouldShowNativeAds else { return }

        let multipleAdOptions = GADMultipleAdsAdLoaderOptions()
        multipleAdOptions.numberOfAds = Self.maxNativeAds

        adLoader = GADAdLoader(
            adUnitID: Config.adMobNativeAdUnitId,
            rootViewController: self,
            adTypes: [.native],
            options: [multipleAdOptions]
        )
        adLoader?.delegate = self
        adLoader?.load(GADRequest())
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        nativeAds.append(nativeAd)
    }

    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        if !nativeAds.isEmpty {
            mapCollectionView.reloadData()
        }
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("[AdMob] 네이티브 광고 로드 실패: \(error.localizedDescription)")
    }
}

// MARK: - Network

extension CourseDiscoveryVC {
    private func getCourseData(pageNo: Int) {
        isFetchingData = true

        // 첫 페이지 로드 시에만 로딩 인디케이터 표시 (페이지네이션은 백그라운드 로딩)
        let isFirstPage = (pageNo == 1)
        if isFirstPage {
            LoadingIndicator.showLoading()
        }

        publicCourseProvider.request(.getCourseData(pageNo: pageNo, sort: sort)) { [weak self] response in
            guard let self = self else { return }

            if isFirstPage {
                LoadingIndicator.hideLoading()
            }
            self.isFetchingData = false

            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    do {
                        let responseDto = try result.map(BaseResponse<PickedMapListResponseDto>.self)
                        guard let data = responseDto.data else { return }

                        guard let totalPageNum = data.totalPageSize, let isEnd = data.isEnd else { return }
                        self.totalPageNum = totalPageNum
                        self.isEnd = isEnd

                        let newCourses = data.publicCourses

                        if isFirstPage {
                            // 첫 페이지(초기 로드 또는 정렬 변경): reloadData 사용
                            self.courseList = newCourses
                            self.mapCollectionView.reloadData()
                            self.emptyView.isHidden = !newCourses.isEmpty
                        } else {
                            // 페이지네이션: performBatchUpdates + insertItems 사용
                            self.insertNewCourses(newCourses)
                        }

                        print("pageNo= \(pageNo), isEnd= \(self.isEnd), totalPageNum= \(self.totalPageNum)")
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

    /// 새 코스를 기존 리스트에 추가하면서 광고 셀도 함께 삽입하는 incremental update
    private func insertNewCourses(_ newCourses: [PublicCourse]) {
        guard !newCourses.isEmpty else { return }

        // 삽입 전 상태 (광고 포함 전체 아이템 수)
        let oldTotalItemCount = totalItemCount()

        // courseList에 새 데이터 추가
        courseList.append(contentsOf: newCourses)

        // 삽입 후 상태 (광고 포함 전체 아이템 수)
        let newTotalItemCount = totalItemCount()

        // 새로 삽입할 IndexPath 계산 (코스 셀 + 광고 셀 모두 포함)
        let insertedIndexPaths = (oldTotalItemCount..<newTotalItemCount).map {
            IndexPath(item: $0, section: Section.courseList)
        }

        guard !insertedIndexPaths.isEmpty else { return }

        mapCollectionView.performBatchUpdates({
            self.mapCollectionView.insertItems(at: insertedIndexPaths)
        }, completion: nil)
    }
    
    private func scrapCourse(publicCourseId: Int, scrapTF: Bool) {
        LoadingIndicator.showLoading()
        scrapProvider.request(.createAndDeleteScrap(publicCourseId: publicCourseId, scrapTF: scrapTF)) { [weak self] response in
            LoadingIndicator.hideLoading()
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    print("스크랩 성공")
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

// MARK: - Section Heading

extension CourseDiscoveryVC: ListEmptyViewDelegate {
    func emptyViewButtonTapped() {
        self.tabBarController?.selectedIndex = 0
    }
}

extension CourseDiscoveryVC: TitleCollectionViewCellDelegate {
    func didTapSortButton(ordering: String) {
        pageNo = 1
        isFetchingData = false
        sort = ordering
        self.courseList.removeAll()
        getCourseData(pageNo: pageNo)
        
        switch ordering {
        case "date":
            analyze(buttonName: GAEvent.Button.clickDate)
        case "scrap":
            analyze(buttonName: GAEvent.Button.clickScrap)
        default:
            break
        }
    }
}

