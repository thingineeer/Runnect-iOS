//
//  RunningRecordVC.swift
//  Runnect-iOS
//
//  Created by sejin on 2023/01/04.
//

import UIKit

import Moya
import SnapKit
import Then

final class RunningRecordVC: UIViewController {

    // MARK: - Properties

    private var runningModel: RunningModel?

    private let recordProvider = Providers.recordProvider

    private let courseTitleMaxLength = 20
    
    // MARK: - UI Components
    
    private lazy var naviBar = CustomNavigationBar(self, type: .titleWithLeftButton)
        .setTitle("러닝 기록")
    
    private let scrollView = UIScrollView()
    
    private let contentView = UIView()
    
    private let courseImageView = UIImageView().then {
        $0.backgroundColor = .gray
        $0.contentMode = .scaleToFill
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
    
    private let dateInfoView = CourseDetailInfoView(title: "날짜", description: RNTimeFormatter.getCurrentTimeToString(date: Date()))
    
    private let departureInfoView = CourseDetailInfoView(title: "출발지", description: "출발지 주소")
    
    private let dividerView = UIView().then {
        $0.backgroundColor = .g5
    }
    
    private let distanceStatsView = StatsInfoView(title: "거리", stats: "0.0 Km").setAttributedStats(stats: "0.0")
    private let totalTimeStatsView = StatsInfoView(title: "이동 시간", stats: "00:00:00")
    private let averagePaceStatsView = StatsInfoView(title: "평균 페이스", stats: "0'00'")
    private let verticalDividerView = UIView().then {
        $0.backgroundColor = .g2
    }
    private let verticalDividerView2 = UIView().then {
        $0.backgroundColor = .g2
    }
    
    private lazy var statsContainerStackView = UIStackView(
        arrangedSubviews: [distanceStatsView,
                           verticalDividerView,
                           totalTimeStatsView,
                           verticalDividerView2,
                           averagePaceStatsView]
    ).then {
        $0.spacing = 25
    }

    // Watch 건강 데이터 섹션
    private let healthDividerView = UIView().then {
        $0.backgroundColor = .g5
        $0.isHidden = true
    }

    private let healthTitleIcon = UIImageView().then {
        $0.image = UIImage(systemName: "heart.fill")
        $0.tintColor = .m1
        $0.contentMode = .scaleAspectFit
        $0.isHidden = true
    }

    private let healthTitleLabel = UILabel().then {
        $0.text = "건강 데이터"
        $0.font = .h5
        $0.textColor = .g1
        $0.isHidden = true
    }

    private let heartRateStatsView = StatsInfoView(title: "평균 심박수", stats: "-- BPM")
        .setAttributedStats(stats: "--", unit: " BPM")
    private let calorieStatsView = StatsInfoView(title: "칼로리", stats: "-- kcal")
        .setAttributedStats(stats: "--", unit: " kcal")
    private let maxHeartRateStatsView = StatsInfoView(title: "최대 심박수", stats: "-- BPM")
        .setAttributedStats(stats: "--", unit: " BPM")

    private let healthVerticalDividerView = UIView().then {
        $0.backgroundColor = .g2
    }
    private let healthVerticalDividerView2 = UIView().then {
        $0.backgroundColor = .g2
    }

    private lazy var healthStatsContainerStackView = UIStackView(
        arrangedSubviews: [heartRateStatsView,
                           healthVerticalDividerView,
                           calorieStatsView,
                           healthVerticalDividerView2,
                           maxHeartRateStatsView]
    ).then {
        $0.spacing = 25
        $0.isHidden = true
    }

    private let heartRateZoneBarView = HeartRateZoneBarView().then {
        $0.isHidden = true
    }

    private let saveButton = CustomButton(title: "저장하기")
        .setEnabled(false)
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.setLayout()
        self.setAddTarget()
        self.setKeyboardNotification()
        self.setTapGesture()
        self.setNaviBarBackAction()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setTextFieldBottomBorder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Methods

extension RunningRecordVC {
    private func setAddTarget() {
        self.courseTitleTextField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
        
        self.saveButton.addTarget(self, action: #selector(saveButtonDidTap), for: .touchUpInside)
    }
    
    // 키보드가 올라오면 scrollView 위치 조정
    private func setKeyboardNotification() {
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
    
    // 화면 터치 시 키보드 내리기
    private func setTapGesture() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func setNaviBarBackAction() {
        naviBar.resetLeftButtonAction({ [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }, .titleWithLeftButton)
    }

    func setData(runningModel: RunningModel) {
        self.runningModel = runningModel
        self.distanceStatsView.setAttributedStats(stats: runningModel.distance ?? "0.0")
        self.totalTimeStatsView.setStats(stats: runningModel.getFormattedTotalTime() ?? "00:00:00")
        self.averagePaceStatsView.setStats(stats: runningModel.getFormattedAveragePage() ?? "0'00''")
        self.courseImageView.image = runningModel.pathImage

        // 건강 데이터 표시 (Watch 연결 시)
        if let health = runningModel.healthSummary {
            showHealthData(health)
        }

        guard let region = runningModel.region, let city = runningModel.city else { return }
        self.departureInfoView.setDescriptionText(description: "\(region) \(city)")

        guard let imageUrl = runningModel.imageUrl else { return }
        self.courseImageView.setImage(with: imageUrl)
    }

    private func showHealthData(_ summary: WatchHealthSummary) {
        healthDividerView.isHidden = false
        healthTitleIcon.isHidden = false
        healthTitleLabel.isHidden = false
        healthStatsContainerStackView.isHidden = false

        heartRateStatsView.setAttributedStats(stats: "\(Int(summary.avgHeartRate))", unit: " BPM")
        calorieStatsView.setAttributedStats(stats: "\(Int(summary.totalCalories))", unit: " kcal")
        maxHeartRateStatsView.setAttributedStats(stats: "\(Int(summary.maxHeartRate))", unit: " BPM")

        if !summary.heartRateZones.isEmpty {
            heartRateZoneBarView.configure(with: summary.heartRateZones)
        }
    }
}

// MARK: - @objc Function

extension RunningRecordVC {
    @objc private func textFieldTextDidChange() {
        guard let text = courseTitleTextField.text else { return }
        
        saveButton.isEnabled = !text.isEmpty
        
        if text.count > courseTitleMaxLength {
            let index = text.index(text.startIndex, offsetBy: courseTitleMaxLength)
            let newString = text[text.startIndex..<index]
            self.courseTitleTextField.text = String(newString)
        }
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
    }
    
    @objc private func keyboardWillHide() {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func saveButtonDidTap() {
        self.recordRunning()
    }
}

// MARK: - UI & Layout

extension RunningRecordVC {
    private func setUI() {
        view.backgroundColor = .w1
    }
    
    private func setLayout() {
        view.addSubviews(naviBar, scrollView, saveButton)
        scrollView.addSubviews(contentView)
        
        naviBar.snp.makeConstraints {
            $0.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(48)
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(naviBar.snp.bottom)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(saveButton.snp.top)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.snp.width)
            $0.height.greaterThanOrEqualTo(scrollView)
        }
        
        setContentViewLayout()
        
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.bottom.equalToSuperview().inset(34)
            $0.height.equalTo(44)
        }
    }
    
    private func setContentViewLayout() {
        contentView.addSubviews(
            courseImageView,
            courseTitleTextField,
            dateInfoView,
            departureInfoView,
            dividerView,
            verticalDividerView,
            verticalDividerView2,
            statsContainerStackView,
            healthDividerView,
            healthTitleIcon,
            healthTitleLabel,
            healthVerticalDividerView,
            healthVerticalDividerView2,
            healthStatsContainerStackView,
            heartRateZoneBarView
        )

        courseImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(courseImageView.snp.width)
        }

        courseTitleTextField.snp.makeConstraints {
            $0.top.equalTo(courseImageView.snp.bottom).offset(27)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(35)
        }

        dateInfoView.snp.makeConstraints {
            $0.top.equalTo(courseTitleTextField.snp.bottom).offset(22)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(16)
        }

        departureInfoView.snp.makeConstraints {
            $0.top.equalTo(dateInfoView.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(16)
        }

        dividerView.snp.makeConstraints {
            $0.top.equalTo(departureInfoView.snp.bottom).offset(34)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(7)
        }

        verticalDividerView.snp.makeConstraints {
            $0.height.equalTo(44)
            $0.width.equalTo(0.5)
        }

        verticalDividerView2.snp.makeConstraints {
            $0.height.equalTo(44)
            $0.width.equalTo(0.5)
        }

        statsContainerStackView.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(25)
            $0.centerX.equalToSuperview()
        }

        // 건강 데이터 섹션 (Watch 연결 시에만 표시)
        healthDividerView.snp.makeConstraints {
            $0.top.equalTo(statsContainerStackView.snp.bottom).offset(25)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(7)
        }

        healthTitleIcon.snp.makeConstraints {
            $0.top.equalTo(healthDividerView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(16)
            $0.width.height.equalTo(16)
        }

        healthTitleLabel.snp.makeConstraints {
            $0.centerY.equalTo(healthTitleIcon)
            $0.leading.equalTo(healthTitleIcon.snp.trailing).offset(6)
        }

        healthVerticalDividerView.snp.makeConstraints {
            $0.height.equalTo(44)
            $0.width.equalTo(0.5)
        }

        healthVerticalDividerView2.snp.makeConstraints {
            $0.height.equalTo(44)
            $0.width.equalTo(0.5)
        }

        healthStatsContainerStackView.snp.makeConstraints {
            $0.top.equalTo(healthTitleLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }

        heartRateZoneBarView.snp.makeConstraints {
            $0.top.equalTo(healthStatsContainerStackView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview().inset(25)
        }
    }
    
    private func setTextFieldBottomBorder() {
        courseTitleTextField.addBottomBorder(height: 2)
    }
}

// MARK: - Network

extension RunningRecordVC {
    private func recordRunning() {
        guard let runningModel = self.runningModel,
              let courseId = runningModel.courseId,
              let titleText = courseTitleTextField.text,
              let time = runningModel.getFormattedTotalTime(),
              let secondsPerKm = runningModel.getIntPace() else { return }

        let pace = RNTimeFormatter.secondsToHHMMSS(seconds: secondsPerKm)

        let requestDto = RunningRecordRequestDto(
            courseId: courseId,
            publicCourseId: runningModel.publicCourseId,
            title: titleText,
            time: time,
            pace: pace
        )

        LoadingIndicator.showLoading()

        // Step 1: 러닝 기록 저장
        recordProvider.request(.recordRunning(param: requestDto)) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    do {
                        let responseDto = try result.map(BaseResponse<RecordResponseDto>.self)
                        guard let recordId = responseDto.data?.record.id else {
                            self.handleRecordSaveSuccess()
                            return
                        }

                        // Step 2: 건강 데이터 저장 (Watch 연결 시에만)
                        if let summary = runningModel.healthSummary {
                            self.saveHealthData(recordId: recordId, summary: summary)
                        } else {
                            self.handleRecordSaveSuccess()
                        }
                    } catch {
                        print("[RecordRunning] Response decode error: \(error)")
                        self.handleRecordSaveSuccess()
                    }
                }
                if status >= 400 {
                    LoadingIndicator.hideLoading()
                    self.showNetworkFailureToast()
                }
            case .failure(let error):
                LoadingIndicator.hideLoading()
                print(error.localizedDescription)
                self.showNetworkFailureToast()
            }
        }
    }

    private func saveHealthData(recordId: Int, summary: WatchHealthSummary) {
        let zoneDurations = summary.zoneDurations

        var sampleDtos: [HeartRateSampleDto]?
        if !summary.heartRateSamples.isEmpty {
            sampleDtos = summary.heartRateSamples.compactMap { dict in
                guard let heartRate = dict["heartRate"] as? Double,
                      let elapsedSeconds = dict["elapsedSeconds"] as? Int,
                      let zone = dict["zone"] as? Int else { return nil }
                return HeartRateSampleDto(
                    heartRate: heartRate,
                    elapsedSeconds: elapsedSeconds,
                    zone: zone
                )
            }
        }

        let healthDto = HealthDataSaveRequestDto(
            avgHeartRate: summary.avgHeartRate,
            maxHeartRate: summary.maxHeartRate,
            minHeartRate: summary.minHeartRate,
            calories: summary.totalCalories,
            zone1Seconds: zoneDurations[1] ?? 0,
            zone2Seconds: zoneDurations[2] ?? 0,
            zone3Seconds: zoneDurations[3] ?? 0,
            zone4Seconds: zoneDurations[4] ?? 0,
            zone5Seconds: zoneDurations[5] ?? 0,
            maxHeartRateConfig: nil,
            heartRateSamples: sampleDtos
        )

        recordProvider.request(.saveHealthData(recordId: recordId, param: healthDto)) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let result):
                if 200..<300 ~= result.statusCode {
                    self.handleRecordSaveSuccess()
                } else if result.statusCode == 409 {
                    self.deleteAndResaveHealthData(recordId: recordId, healthDto: healthDto)
                } else {
                    print("[HealthData] Save failed: \(result.statusCode)")
                    self.handleRecordSaveSuccess()
                }
            case .failure(let error):
                print("[HealthData] Network error: \(error.localizedDescription)")
                self.handleRecordSaveSuccess()
            }
        }
    }

    private func deleteAndResaveHealthData(recordId: Int, healthDto: HealthDataSaveRequestDto) {
        recordProvider.request(.deleteHealthData(recordId: recordId)) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let result):
                if 200..<300 ~= result.statusCode {
                    self.recordProvider.request(.saveHealthData(recordId: recordId, param: healthDto)) { [weak self] _ in
                        self?.handleRecordSaveSuccess()
                    }
                } else {
                    self.handleRecordSaveSuccess()
                }
            case .failure:
                self.handleRecordSaveSuccess()
            }
        }
    }

    private func handleRecordSaveSuccess() {
        LoadingIndicator.hideLoading()
        analyze(buttonName: GAEvent.Button.clickStoreRunningTracking)
        WatchSessionService.shared.sendRunReset()
        WatchSessionService.shared.clearHealthData()
        showToastOnWindow(text: "저장한 러닝 기록은 마이페이지에서 볼 수 있어요.")
        navigationController?.popToRootViewController(animated: true)
    }
}
