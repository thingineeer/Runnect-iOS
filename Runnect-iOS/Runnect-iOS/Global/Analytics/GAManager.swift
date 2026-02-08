//
//  GAManager.swift
//  Runnect-iOS
//
//  Created by 이명진 on 12/24/23.
//

import UIKit

import FirebaseAnalytics

final class GAManager {
    static let shared = GAManager()
    
    private init() {}
    
    enum GAEventType {
        case screen(screenName: String)
        case button(buttonName: String)
        case share(eventName: String, courseType: String, courseId: Int)

        var eventName: String {
            switch self {
            case .screen:
                return "screen"
            case .button:
                return "button"
            case .share(let eventName, _, _):
                return eventName
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .screen(let screenName):
                return ["screen": screenName]
            case .button(let buttonName):
                return ["button": buttonName]
            case .share(_, let courseType, let courseId):
                return ["course_type": courseType, "course_id": courseId]
            }
        }
    }

    func logEvent(eventType: GAEventType) {
        Analytics.logEvent(eventType.eventName, parameters: eventType.parameters)
    }
}
