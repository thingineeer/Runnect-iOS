//
//  HeartRateZoneBarView.swift
//  Runnect-iOS
//
//  Created by 이명진 on 2026/02/22.
//

import UIKit

import SnapKit
import Then

final class HeartRateZoneBarView: UIView {

    // MARK: - Properties

    struct ZoneData {
        let zone: Int
        let name: String
        let percentage: Double
    }

    private static let zoneColors: [Int: UIColor] = [
        1: .m6,
        2: .m5,
        3: .m2,
        4: .m1,
        5: UIColor(hex: "#3A1FCF")
    ]

    private static let zoneNames: [Int: String] = [
        1: "워밍업",
        2: "지방 연소",
        3: "유산소",
        4: "고강도",
        5: "최대"
    ]

    // MARK: - UI Components

    private let barContainerView = UIView().then {
        $0.layer.cornerRadius = 6
        $0.clipsToBounds = true
    }

    private let legendStackView = UIStackView().then {
        $0.spacing = 12
        $0.alignment = .center
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Methods

extension HeartRateZoneBarView {
    func configure(with zones: [[String: Any]]) {
        let zoneDataList = parseZones(zones)
        guard zoneDataList.count >= 2 else {
            self.isHidden = true
            return
        }
        self.isHidden = false
        layoutBarSegments(zoneDataList)
        layoutLegend(zoneDataList)
    }

    private func parseZones(_ zones: [[String: Any]]) -> [ZoneData] {
        var result: [ZoneData] = []
        for zoneDict in zones {
            guard let zone = zoneDict["zone"] as? Int,
                  let percentage = zoneDict["percentage"] as? Double,
                  percentage > 0 else { continue }
            let name = Self.zoneNames[zone] ?? "Zone \(zone)"
            result.append(ZoneData(zone: zone, name: name, percentage: percentage))
        }
        return result.sorted { $0.zone < $1.zone }
    }

    private func layoutBarSegments(_ zones: [ZoneData]) {
        barContainerView.subviews.forEach { $0.removeFromSuperview() }

        var previousView: UIView?
        let totalPercentage = zones.reduce(0) { $0 + $1.percentage }
        guard totalPercentage > 0 else { return }

        for zone in zones {
            let segmentView = UIView()
            segmentView.backgroundColor = Self.zoneColors[zone.zone] ?? .g4
            barContainerView.addSubview(segmentView)

            let ratio = zone.percentage / totalPercentage

            segmentView.snp.makeConstraints {
                $0.top.bottom.equalToSuperview()
                if let prev = previousView {
                    $0.leading.equalTo(prev.snp.trailing)
                } else {
                    $0.leading.equalToSuperview()
                }
                $0.width.equalToSuperview().multipliedBy(ratio)
            }
            previousView = segmentView
        }
    }

    private func layoutLegend(_ zones: [ZoneData]) {
        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for zone in zones {
            let itemView = makeLegendItem(
                color: Self.zoneColors[zone.zone] ?? .g4,
                text: "\(zone.name) \(Int(zone.percentage))%"
            )
            legendStackView.addArrangedSubview(itemView)
        }
    }

    private func makeLegendItem(color: UIColor, text: String) -> UIView {
        let colorDot = UIView().then {
            $0.backgroundColor = color
            $0.layer.cornerRadius = 4
        }

        let label = UILabel().then {
            $0.text = text
            $0.font = .b8
            $0.textColor = .g2
        }

        let stack = UIStackView(arrangedSubviews: [colorDot, label]).then {
            $0.spacing = 4
            $0.alignment = .center
        }

        colorDot.snp.makeConstraints {
            $0.width.height.equalTo(8)
        }

        return stack
    }
}

// MARK: - UI & Layout

extension HeartRateZoneBarView {
    private func setLayout() {
        addSubviews(barContainerView, legendStackView)

        barContainerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(12)
        }

        legendStackView.snp.makeConstraints {
            $0.top.equalTo(barContainerView.snp.bottom).offset(8)
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
}
