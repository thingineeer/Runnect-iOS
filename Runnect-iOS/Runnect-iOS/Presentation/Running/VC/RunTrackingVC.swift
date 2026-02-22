//
//  RunTrackingVC.swift
//  Runnect-iOS
//
//  Created by sejin on 2023/01/04.
//

import UIKit
import Combine
import CoreLocation

import SnapKit
import Then

import NMapsMap

final class RunTrackingVC: UIViewController {

    // MARK: - Properties

    private var runningModel: RunningModel?

    private let stopwatch = Stopwatch()
    private var cancelBag = CancelBag()
    var totalTime: Int = 0
    var distance: String = "0.0"

    // GPS 기반 실제 뛴 거리 (Watch 전송용)
    private let runLocationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var runDistance: Double = 0.0  // meters
    private let distanceQueue = DispatchQueue(label: "com.runnect.distance", qos: .userInitiated)

    // Watch 건강 데이터
    private var healthCancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private let statsView = UIView().then {
        $0.backgroundColor = .w1
        $0.layer.cornerRadius = 40
        $0.layer.maskedCorners = [.layerMaxXMaxYCorner]
    }
    
    private let backButton = UIButton(type: .system).then {
        $0.setImage(ImageLiterals.icArrowBack, for: .normal)
        $0.tintColor = .g1
    }
    
    private let distanceImageView = UIImageView().then {
        $0.image = ImageLiterals.icDistance
        $0.tintColor = .g2
    }
    
    private let distanceLabel = UILabel().then {
        $0.text = "총 거리"
        $0.font = .b4
        $0.textColor = .g2
    }
    
    private lazy var distanceInfoStackView = UIStackView(
        arrangedSubviews: [distanceImageView, distanceLabel]
    ).then {
        $0.spacing = 8
        $0.alignment = .leading
    }
    
    private lazy var totalDistanceLabel = UILabel().then {
        $0.attributedText = makeAttributedLabelForDistance(distance: "0.0")
    }
    
    private lazy var distanceStatsStackView = UIStackView(
        arrangedSubviews: [distanceInfoStackView, totalDistanceLabel]
    ).then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 14
    }
    
    private let timeImageView = UIImageView().then {
        $0.image = ImageLiterals.icTime
        $0.tintColor = .g2
    }
    
    private let timeLabel = UILabel().then {
        $0.text = "시간"
        $0.font = .b4
        $0.textColor = .g2
    }
    
    private lazy var timeInfoStackView = UIStackView(
        arrangedSubviews: [timeImageView, timeLabel]
    ).then {
        $0.spacing = 8
        $0.alignment = .leading
    }
    
    private let timeStatsLabel = UILabel().then {
        $0.text = "00:00:00"
        $0.font = .h1
        $0.textColor = .g1
    }
    
    private lazy var timeStatsStackView = UIStackView(
        arrangedSubviews: [timeInfoStackView, timeStatsLabel]
    ).then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 14
    }
    
    private lazy var statsStackView = UIStackView(
        arrangedSubviews: [distanceStatsStackView, timeStatsStackView]
    ).then {
        $0.spacing = 38
    }
    
    private let bigStarImageView = UIImageView().then {
        $0.image = ImageLiterals.icStar2
    }
    
    private let smallStarImageView = UIImageView().then {
        $0.image = ImageLiterals.icStar
    }

    // Watch 건강 데이터 UI (statsView 내부에 배치)
    private let healthDividerLine = UIView().then {
        $0.backgroundColor = .g4
        $0.isHidden = true
    }

    private let heartRateImageView = UIImageView().then {
        $0.image = UIImage(systemName: "heart.fill")
        $0.tintColor = .g2
        $0.contentMode = .scaleAspectFit
    }

    private let heartRateTitleLabel = UILabel().then {
        $0.text = "심박수"
        $0.font = .b4
        $0.textColor = .g2
    }

    private lazy var heartRateInfoStackView = UIStackView(
        arrangedSubviews: [heartRateImageView, heartRateTitleLabel]
    ).then {
        $0.spacing = 8
        $0.alignment = .leading
    }

    private let heartRateValueLabel = UILabel().then {
        $0.attributedText = {
            let attr = NSMutableAttributedString(
                string: "--",
                attributes: [.font: UIFont.h3, .foregroundColor: UIColor.g1]
            )
            attr.append(NSAttributedString(
                string: " BPM",
                attributes: [.font: UIFont.b4, .foregroundColor: UIColor.g2]
            ))
            return attr
        }()
    }

    private lazy var heartRateStatsStackView = UIStackView(
        arrangedSubviews: [heartRateInfoStackView, heartRateValueLabel]
    ).then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 14
    }

    private let calorieImageView = UIImageView().then {
        $0.image = UIImage(systemName: "flame.fill")
        $0.tintColor = .g2
        $0.contentMode = .scaleAspectFit
    }

    private let calorieTitleLabel = UILabel().then {
        $0.text = "칼로리"
        $0.font = .b4
        $0.textColor = .g2
    }

    private lazy var calorieInfoStackView = UIStackView(
        arrangedSubviews: [calorieImageView, calorieTitleLabel]
    ).then {
        $0.spacing = 8
        $0.alignment = .leading
    }

    private let calorieValueLabel = UILabel().then {
        $0.attributedText = {
            let attr = NSMutableAttributedString(
                string: "0",
                attributes: [.font: UIFont.h3, .foregroundColor: UIColor.g1]
            )
            attr.append(NSAttributedString(
                string: " kcal",
                attributes: [.font: UIFont.b4, .foregroundColor: UIColor.g2]
            ))
            return attr
        }()
    }

    private lazy var calorieStatsStackView = UIStackView(
        arrangedSubviews: [calorieInfoStackView, calorieValueLabel]
    ).then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 14
    }

    private lazy var healthStatsStackView = UIStackView(
        arrangedSubviews: [heartRateStatsStackView, calorieStatsStackView]
    ).then {
        $0.spacing = 38
        $0.isHidden = true
    }

    private let mapView = RNMapView()
        .showLocationButton(toShow: true)
        .makeContentPadding(padding: UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0))
        .setPositionMode(mode: .normal)
    
    private let runningCompleteButton = CustomButton(title: "러닝 종료")
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.setLayout()
        self.setAddTarget()
        self.bindStopwatch()
        self.observeWatchCommand()
        self.bindWatchHealthData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.stopwatch.isRunning = true
        self.startRunLocationTracking()
        self.startWatchDataSync()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelBag.cancel()
        healthCancellables.forEach { $0.cancel() }
        stopRunLocationTracking()
        WatchSessionService.shared.stopSendingRunningData()
    }
}

// MARK: - Methods

extension RunTrackingVC {
    func setData(runningModel: RunningModel) {
        self.runningModel = runningModel
        makePath(locations: runningModel.locations, distance: runningModel.distance ?? "0.0")
    }
    
    func makePath(locations: [NMGLatLng], distance: String) {
        self.mapView.makeMarkersWithStartMarker(at: locations, moveCameraToStartMarker: true)
        self.totalDistanceLabel.attributedText = makeAttributedLabelForDistance(distance: distance)
        self.distance = distance
    }
    
    private func setAddTarget() {
        self.backButton.addTarget(self, action: #selector(popToPreviousVC), for: .touchUpInside)
        self.runningCompleteButton.addTarget(self, action: #selector(runningCompleteButtonDidTap), for: .touchUpInside)
    }
    
    private func makeAttributedLabelForDistance(distance: String) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(
            string: distance,
            attributes: [.font: UIFont.h1, .foregroundColor: UIColor.g1]
        )
        attributedString.append(
            NSAttributedString(
                string: " Km",
                attributes: [.font: UIFont.b4, .foregroundColor: UIColor.g2]
            )
        )
        
        return attributedString
    }
    
    private func bindStopwatch() {
        stopwatch.$elapsedTime.sink { [weak self] time in
            guard let self = self else { return }
            let time = Int(time)
            self.totalTime = time
            self.setTimeLabel(with: time)
        }.store(in: cancelBag)
    }
    
    private func setTimeLabel(with totalSeconds: Int) {
        let formattedString = RNTimeFormatter.secondsToHHMMSS(seconds: totalSeconds)
        
        timeStatsLabel.text = formattedString
    }
    
    private func startRunLocationTracking() {
        runLocationManager.delegate = self
        runLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        runLocationManager.distanceFilter = 5
        runLocationManager.allowsBackgroundLocationUpdates = false
        runLocationManager.pausesLocationUpdatesAutomatically = true
        runLocationManager.activityType = .fitness
        runLocationManager.startUpdatingLocation()
    }

    private func stopRunLocationTracking() {
        runLocationManager.stopUpdatingLocation()
        runLocationManager.delegate = nil
        lastLocation = nil
    }

    private func startWatchDataSync() {
        WatchSessionService.shared.startSendingRunningData { [weak self] in
            guard let self, let runningModel = self.runningModel else { return nil }
            let currentDistance = self.distanceQueue.sync { self.runDistance }
            let actualDistanceKm = currentDistance / 1000.0
            let totalCourseDistance = Double(runningModel.distance ?? "0.0") ?? 0.0
            let progress = totalCourseDistance > 0 ? min(actualDistanceKm / totalCourseDistance, 1.0) : 0.0
            let elapsedTime = self.totalTime
            let pace = actualDistanceKm > 0 ? Int(round(Double(elapsedTime) / actualDistanceKm)) : 0

            return [
                "messageType": "runningUpdate",
                "distance": actualDistanceKm,
                "elapsedTime": elapsedTime,
                "pace": pace,
                "progress": progress,
                "totalCourseDistance": totalCourseDistance,
                "isRunning": self.stopwatch.isRunning,
                "courseName": ""
            ]
        }
    }

    private func observeWatchCommand() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWatchCommand(_:)),
            name: .watchCommandReceived,
            object: nil
        )
    }

    private func bindWatchHealthData() {
        let watchService = WatchSessionService.shared

        watchService.$realtimeHeartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                guard let self else { return }
                if heartRate > 0 {
                    self.showHealthDataRow()
                    self.heartRateValueLabel.attributedText = self.makeAttributedHealthValue(
                        value: "\(Int(heartRate))", unit: " BPM"
                    )
                }
            }
            .store(in: &healthCancellables)

        watchService.$realtimeCalories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] calories in
                guard let self else { return }
                if calories > 0 {
                    self.calorieValueLabel.attributedText = self.makeAttributedHealthValue(
                        value: "\(Int(calories))", unit: " kcal"
                    )
                }
            }
            .store(in: &healthCancellables)

        watchService.$isWatchReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reachable in
                guard let self else { return }
                if !reachable {
                    self.hideHealthDataRow()
                }
            }
            .store(in: &healthCancellables)
    }

    private func makeAttributedHealthValue(value: String, unit: String) -> NSMutableAttributedString {
        let attr = NSMutableAttributedString(
            string: value,
            attributes: [.font: UIFont.h3, .foregroundColor: UIColor.g1]
        )
        attr.append(NSAttributedString(
            string: unit,
            attributes: [.font: UIFont.b4, .foregroundColor: UIColor.g2]
        ))
        return attr
    }

    private func showHealthDataRow() {
        guard healthStatsStackView.isHidden else { return }
        healthDividerLine.isHidden = false
        healthStatsStackView.isHidden = false
        statsView.snp.updateConstraints {
            $0.height.equalTo(160)
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func hideHealthDataRow() {
        guard !healthStatsStackView.isHidden else { return }
        healthDividerLine.isHidden = true
        healthStatsStackView.isHidden = true
        statsView.snp.updateConstraints {
            $0.height.equalTo(100)
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func pushToRunningRecordVC() {
        guard var runningModel = self.runningModel else { return }

        runningModel.totalTime = self.totalTime
        runningModel.healthSummary = WatchSessionService.shared.healthSummary

        let runningRecordVC = RunningRecordVC()
        runningRecordVC.setData(runningModel: runningModel)
        self.navigationController?.pushViewController(runningRecordVC, animated: true)
    }
}

// MARK: - @objc Function

extension RunTrackingVC {
    @objc private func popToPreviousVC() {
        let alertVC = RNAlertVC(description: "러닝을 종료하시겠습니까?")
            .setButtonTitle("취소", "종료하기")
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.rightButtonTapAction = { [weak self] in
            alertVC.dismiss(animated: false)
            self?.stopwatch.isRunning = false
            self?.stopRunLocationTracking()
            WatchSessionService.shared.stopSendingRunningData()
            WatchSessionService.shared.sendRunReset()
            WatchSessionService.shared.clearHealthData()
            self?.navigationController?.popViewController(animated: true)
        }
        self.present(alertVC, animated: false)
    }
    
    @objc private func runningCompleteButtonDidTap() {
        let alertVC = RNAlertVC(description: "러닝을 종료하시겠습니까?")
            .setButtonTitle("취소", "종료하기")
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.rightButtonTapAction = { [weak self] in
            alertVC.dismiss(animated: false)
            self?.stopwatch.isRunning = false
            self?.stopRunLocationTracking()
            WatchSessionService.shared.stopSendingRunningData()
            WatchSessionService.shared.sendRunCompleted()
            self?.pushToRunningRecordVC()
        }
        self.present(alertVC, animated: false)
    }

    @objc private func handleWatchCommand(_ notification: Notification) {
        guard let command = notification.userInfo?["command"] as? String,
              command == "endRunning" else { return }
        stopwatch.isRunning = false
        stopRunLocationTracking()
        WatchSessionService.shared.stopSendingRunningData()
        WatchSessionService.shared.sendRunCompleted()
        self.pushToRunningRecordVC()
    }
}

// MARK: - CLLocationManagerDelegate

extension RunTrackingVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last,
              newLocation.horizontalAccuracy >= 0,
              newLocation.horizontalAccuracy < 30 else { return }

        if let last = lastLocation {
            let delta = newLocation.distance(from: last)
            let timeDelta = newLocation.timestamp.timeIntervalSince(last.timestamp)

            // GPS 노이즈 필터: 1m 미만 무시, 50m/초 이상(180km/h) 비현실적 이동 무시
            if delta > 1 && timeDelta > 0 && (delta / timeDelta) < 50 {
                distanceQueue.sync {
                    runDistance += delta
                }
            }
        }
        lastLocation = newLocation
    }
}

// MARK: - UI & Layout
extension RunTrackingVC {
    private func setUI() {
        view.backgroundColor = .w1
        statsView.layer.applyShadow(alpha: 0.2, x: 0, y: 5, blur: 6, spread: 0)
    }
    
    private func setLayout() {
        view.addSubviews(mapView, statsView, runningCompleteButton)
        statsView.addSubviews(backButton, statsStackView, bigStarImageView, smallStarImageView, healthDividerLine, healthStatsStackView)

        statsView.snp.makeConstraints {
            $0.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(100)
        }

        backButton.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
            $0.width.height.equalTo(48)
        }

        statsStackView.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing)
            $0.top.equalToSuperview().inset(15)
        }

        bigStarImageView.snp.makeConstraints {
            $0.centerY.equalTo(timeStatsLabel.snp.centerY)
            $0.trailing.equalToSuperview().inset(15)
        }

        smallStarImageView.snp.makeConstraints {
            $0.top.equalTo(bigStarImageView.snp.bottom).offset(2)
            $0.centerX.equalTo(bigStarImageView.snp.leading).multipliedBy(0.99)
        }

        healthDividerLine.snp.makeConstraints {
            $0.top.equalTo(statsStackView.snp.bottom).offset(8)
            $0.leading.equalTo(backButton.snp.trailing)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }

        heartRateImageView.snp.makeConstraints {
            $0.width.height.equalTo(14)
        }

        calorieImageView.snp.makeConstraints {
            $0.width.height.equalTo(14)
        }

        healthStatsStackView.snp.makeConstraints {
            $0.top.equalTo(healthDividerLine.snp.bottom).offset(8)
            $0.leading.equalTo(backButton.snp.trailing)
        }

        mapView.snp.makeConstraints {
            $0.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }

        runningCompleteButton.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().inset(34)
        }
    }
}
