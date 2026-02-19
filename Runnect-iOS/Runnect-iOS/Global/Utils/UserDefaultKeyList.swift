//
//  UserDefaultKeyList.swift
//  Runnect-iOS
//
//  Created by sejin on 2022/12/29.
//

import Foundation

struct UserDefaultKeyList {
    struct Auth {
        @UserDefaultWrapper<Bool>(key: "didSignIn") public static var didSignIn
    }

    struct Ad {
        @UserDefaultWrapper<Int>(key: "appLaunchCount") public static var appLaunchCount
        @UserDefaultWrapper<String>(key: "lastKnownAppVersion") public static var lastKnownAppVersion
    }

    struct Update {
        @UserDefaultWrapper<String>(key: "optionalUpdateDismissedVersion") public static var optionalUpdateDismissedVersion
    }

    struct Dev {
        @UserDefaultWrapper<Bool>(key: "isDeveloperMode") public static var isDeveloperMode
    }
}
