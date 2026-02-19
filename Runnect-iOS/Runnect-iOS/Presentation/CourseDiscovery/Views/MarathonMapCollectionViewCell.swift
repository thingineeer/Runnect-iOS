//
//  MarathonMapCollectionViewCell.swift
//  Runnect-iOS
//
//  Created by 이명진 on 11/18/23.
//

import UIKit
import Combine

import SnapKit

protocol MarathonScrapStateDelegate: AnyObject {
    func didUpdateMarathonScrapState(publicCourseId: Int, isScrapped: Bool)
}

class CourseSelectionPublisher {
    static let shared = CourseSelectionPublisher()
    
    private init() {}
    
    let didSelectCourse = PassthroughSubject<IndexPath, Never>()
}

final class MarathonMapCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    private let PublicCourseProvider = Providers.publicCourseProvider
    private let scrapProvider = Providers.scrapProvider
    private var hasLoaded = false
    var marathonCourseList = [marathonCourse]() // Cell 사용하는 곳에서 사용 중이라 private ❌
    
    // MARK: - UIComponents
    
    private lazy var marathonCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    // MARK: - Constants
    
    private let collectionViewInset = UIEdgeInsets(top: 0, left: 16, bottom: 34, right: 16)
    private let itemSpacing: CGFloat = 10
    private let lineSpacing: CGFloat = 10
    
    // MARK: - Life cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
        register()
        setDelegate()
        getMarathonCourseData()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Method

extension MarathonMapCollectionViewCell {
    private func setDelegate() {
        marathonCollectionView.delegate = self
        marathonCollectionView.dataSource = self
    }
    
    private func register() {
        marathonCollectionView.register(CourseListCVC.self,
                                        forCellWithReuseIdentifier: CourseListCVC.className)
    }
    
    private func marathonReloadCellForCourse(publicCourseId: Int) {
        print("✅ 2. \(publicCourseId)번 부분이 교체가 되는가")
        if let index = marathonCourseList.firstIndex(where: { $0.id == publicCourseId }) {
            let indexPath = IndexPath(item: index, section: 0)
            marathonCollectionView.reloadItems(at: [indexPath])
            print("✅ 3. \(indexPath) 마라톤 부분 스크랩 교체 되었음 \n reloadItems까지는 작동은 했음 여기서 안되면 코드가 잘 못 된것.")
        }
    }
}

// MARK: - Layout Helpers

extension MarathonMapCollectionViewCell {
    private func setLayout() {
        contentView.backgroundColor = .clear
        contentView.addSubview(marathonCollectionView)
        
        marathonCollectionView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalTo(contentView.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }
    }
    
    private func setData(marathonCourseList: [marathonCourse]) {
        self.marathonCourseList = marathonCourseList
        marathonCollectionView.reloadData()
    }
}
// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension MarathonMapCollectionViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return marathonCourseList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseListCVC.className,
                                                            for: indexPath)
                as? CourseListCVC else { return UICollectionViewCell() }
        cell.setCellType(type: .all)
        cell.delegate = self
        let model = self.marathonCourseList[indexPath.item]
        let location = "\(model.departure.region) \(model.departure.city)"
        cell.setData(imageURL: model.image, title: model.title, location: location, didLike: model.scrap, indexPath: indexPath.item)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MarathonMapCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 156, height: 160)
    } // 셀사이즈 RecommendedCVC와  연결 되면 변경
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.collectionViewInset
    }
    
    // 이게 반대방향
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemSpacing
    }
    
    // 이게 스크롤방향
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        CourseSelectionPublisher.shared.didSelectCourse.send(indexPath)
        // 코스 발견에 이벤트 전달
    }
}

// MARK: - CourseListCVCDelegate

extension MarathonMapCollectionViewCell: CourseListCVCDelegate {
    func likeButtonTapped(wantsTolike: Bool, index: Int) {
        guard UserManager.shared.userType != .visitor else {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                Toast.show(message: "러넥트에 가입하면 코스를 스크랩할 수 있어요", view: window, safeAreaBottomInset: window.safeAreaInsets.bottom)
            }
            return
        }
        
        let publicCourseId = self.marathonCourseList[index].id
        self.scrapCourse(publicCourseId: publicCourseId, scrapTF: wantsTolike)
        
        print("마라톤에 들어온 index = \(index)")
    }
}

extension MarathonMapCollectionViewCell: MarathonScrapStateDelegate {
    func didUpdateMarathonScrapState(publicCourseId: Int, isScrapped: Bool) {
        print("✅ 1. 마라톤 델리게이트 들어오는가 🫶🏻")
        if let index = marathonCourseList.firstIndex(where: { $0.id == publicCourseId }) {
            marathonCourseList[index].scrap = isScrapped
            marathonReloadCellForCourse(publicCourseId: publicCourseId)
            print("✅ 4. ‼️MarathonMapCollectionViewCell에서 작업 완료")
        }
    }
}

// MARK: - NetWork

extension MarathonMapCollectionViewCell {
    private func getMarathonCourseData() {
        guard !hasLoaded else { return }
        hasLoaded = true

        PublicCourseProvider.request(.getMarathonCourseData) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    do {
                        let responseDto = try result.map(BaseResponse<MarathonListResponseDto>.self)
                        guard let data = responseDto.data else { return }
                        self.setData(marathonCourseList: data.marathonPublicCourses)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                if status >= 400 {
                    print("400 error")
                }
            case .failure(let error):
                self.hasLoaded = false
                print(error.localizedDescription)
            }
        }
    }
    
    private func scrapCourse(publicCourseId: Int, scrapTF: Bool) {
        LoadingIndicator.showLoading()
        
        scrapProvider.request(.createAndDeleteScrap(publicCourseId: publicCourseId, scrapTF: scrapTF)) { [weak self] response in
            defer {
                LoadingIndicator.hideLoading()
            }
            
            guard self != nil else { return }
            
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    print("스크랩 성공")
                } else if status >= 400 {
                    print("400 error")
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
