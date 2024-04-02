//
//  UploadViewController.swift
//  Runnect-iOS
//
//  Created by YEONOO on 2023/01/05.
//

import UIKit

import SnapKit
import Then
import Moya

class CourseUploadVC: UIViewController {
    
    // MARK: - Properties
    private let PublicCourseProvider = Providers.publicCourseProvider
    
    private var courseModel: Course?
    private let courseTitleMaxLength = 20
    
    weak var delegate: UploadStateDelegate?
    
    // MARK: - UI Components
    
    private lazy var navibar = CustomNavigationBar(self, type: .titleWithLeftButton).setTitle("코스 업로드")
    private let buttonContainerView = UIView()
    private let uploadButton = CustomButton(title: "업로드하기").setEnabled(false)
    
    private lazy var scrollView = UIScrollView()
    private let mapImageView = UIImageView().then {
        $0.image = UIImage(named: "")
    }
    private let courseTitleTextField = UITextField().then {
        $0.attributedPlaceholder = NSAttributedString(
            string: "글 제목",
            attributes: [.font: UIFont.h4, .foregroundColor: UIColor.g3]
        )
        $0.font = .h4
        $0.textColor = .g1
        $0.addLeftPadding(width: 2)
    }
    private let dividerView = UIView().then {
        $0.backgroundColor = .g5
    }
    private let distanceInfoView = CourseDetailInfoView(title: "거리", description: "0.0km")
    private let departureInfoView = CourseDetailInfoView(title: "출발지", description: "")
    private let placeholder = "코스에 대한 소개를 적어주세요.(난이도/풍경/지형)\n(최대 150자)"
    
    let activityTextView = UITextView().then {
        $0.font = .b4
        $0.backgroundColor = .m3
        $0.tintColor = .m1
        $0.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        setUI()
        setLayout()
        setDelegate()
        setAddTarget()
        setTapGesture()
        setKeyboardObservers()
        analyze(screenName: GAEvent.View.viewCourseUpload)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Methods

extension CourseUploadVC {
    
    func setData(courseModel: Course) {
        self.courseModel = courseModel
        self.mapImageView.setImage(with: courseModel.image)
        
        guard let distance = courseModel.distance else { return }
        self.distanceInfoView.setDescriptionText(description: "\(String(distance))km")
        
        let departureString = [
            courseModel.departure.region,
            courseModel.departure.city,
            courseModel.departure.town,
            courseModel.departure.name
        ]
            .compactMap { $0 }
            .joined(separator: " ")
        
        self.departureInfoView.setDescriptionText(description: departureString)
    }
    
    private func setAddTarget() {
        self.courseTitleTextField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
        self.uploadButton.addTarget(self, action: #selector(uploadButtonDidTap), for: .touchUpInside)
    }
    
    // 화면 터치 시 키보드 내리기
    private func setTapGesture() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    // 업로드 버튼 상태 업데이트 메소드
    private func updateUploadButtonState() {
        let isTitleNotEmpty = !(courseTitleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let isContentNotEmptyAndNotPlaceholder = !(activityTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || activityTextView.text == placeholder)
        uploadButton.setEnabled(isTitleNotEmpty && isContentNotEmptyAndNotPlaceholder)
    }
    
    private func setKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
}
// MARK: - @objc Function

extension CourseUploadVC {
    @objc private func textFieldTextDidChange() {
        updateUploadButtonState()
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let contentInset = UIEdgeInsets(
            top: 0.0,
            left: 0.0,
            bottom: keyboardFrame.size.height,
            right: 0.0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
        
        // scrollView 높이 설정
        if courseTitleTextField.isFirstResponder || activityTextView.isFirstResponder {
            let contentViewHeight = scrollView.contentSize.height
            let textViewHeight = activityTextView.frame.height
            let textViewOffsetY = contentViewHeight - (contentInset.bottom + textViewHeight)
            let position = CGPoint(x: 0, y: textViewOffsetY + 50)
            scrollView.setContentOffset(position, animated: true)
            return
        }
    }
    
    @objc private func keyboardWillHide() {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc func uploadButtonDidTap() {
        self.uploadCourse()
        
        analyze(buttonName: GAEvent.Button.clickCourseUpload)
    }
}

extension CourseUploadVC {
    
    // MARK: - naviVar Layout
    
    private func setNavigationBar() {
        view.addSubview(navibar)
        navibar.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(48)
        }
    }
    // MARK: - UI & Layout
    
    private func setUI() {
        view.backgroundColor = .w1
        scrollView.backgroundColor = .clear
        buttonContainerView.backgroundColor = .w1
        mapImageView.backgroundColor = .systemGray4
        
        activityTextView.text = placeholder
        activityTextView.textColor = .g3
    }
    
    private func setLayout() {
        view.addSubview(buttonContainerView)
        view.bringSubviewToFront(uploadButton)
        buttonContainerView.addSubview(uploadButton)
        
        buttonContainerView.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(86)
            $0.bottom.equalToSuperview()
        }
        uploadButton.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().inset(34)
        }
        
        setScrollViewLayout()
    }
    
    private func setScrollViewLayout() {
        view.addSubview(scrollView)
        
        scrollView.addSubviews(
            mapImageView,
            courseTitleTextField,
            dividerView,
            distanceInfoView,
            departureInfoView,
            activityTextView
        )
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(navibar.snp.bottom)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(uploadButton.snp.top).inset(-25)
        }
        
        mapImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalTo(self.view.safeAreaLayoutGuide)
            $0.height.equalTo(mapImageView.snp.width).multipliedBy(0.75)
        }
        
        courseTitleTextField.snp.makeConstraints {
            $0.top.equalTo(mapImageView.snp.bottom).offset(28)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(35)
        }
        
        dividerView.snp.makeConstraints {
            $0.top.equalTo(courseTitleTextField.snp.bottom).offset(0)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(2)
        }
        
        distanceInfoView.snp.makeConstraints {
            $0.top.equalTo(courseTitleTextField.snp.bottom).offset(22)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(16)
        }
        
        departureInfoView.snp.makeConstraints {
            $0.top.equalTo(distanceInfoView.snp.bottom).offset(6)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(16)
        }
        
        activityTextView.snp.makeConstraints {
            $0.top.equalTo(departureInfoView.snp.bottom).offset(34)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(187)
        }
    }
    
    func setDelegate() {
        activityTextView.delegate = self
        courseTitleTextField.delegate = self
    }
}

// MARK: - UITextViewDelegate

extension CourseUploadVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            activityTextView.textColor = .g3
            activityTextView.text = placeholder
            
        } else if textView.text == placeholder {
            activityTextView.textColor = .g1
            activityTextView.text = nil
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateUploadButtonState()
        
        if activityTextView.text.count > 150 {
            activityTextView.deleteBackward()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || textView.text == placeholder {
            activityTextView.textColor = .g3
            activityTextView.text = placeholder
        }
    }
}

// MARK: - UITextFieldDelegate

extension CourseUploadVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == courseTitleTextField {
            activityTextView.becomeFirstResponder()
            return true
        }
        return false
    }
}

// MARK: - Network

extension CourseUploadVC {
    private func uploadCourse() {
        guard let courseId = courseModel?.id else { return }
        guard let titletext = courseTitleTextField.text else { return }
        guard let descriptiontext = activityTextView.text else { return }
        let requsetDto = CourseUploadingRequestDto(courseId: courseId, title: titletext, description: descriptiontext)
        
        LoadingIndicator.showLoading()
        PublicCourseProvider.request(.courseUploadingData(param: requsetDto)) { [weak self] response in
            LoadingIndicator.hideLoading()
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    delegate?.didUploadCourse()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    // uploadCourse 업로드 성공하면, 코스발견 CVC 맨 위에 데이터 추가
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
