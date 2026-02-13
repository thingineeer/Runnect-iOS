//
//  Config.swift
//  Runnect-iOS
//
//  Created by sejin on 2023/01/06.
//

import UIKit

struct Config {
    private init() {}
    
    // node
//    static var baseURL: String {
//        return "http://3.35.184.0:3000/api"
//    }
    
    // spring server
    static var baseURL: String {
        return "http://43.201.179.83/api"
        
    }
    
    // test server
//    static var baseURL: String {
//        return "http://54.180.15.23/api"
//    }
    
    static var kakaoAddressBaseURL: String {
        return "https://dapi.kakao.com/v2/local/search"
    }
    
    static var kakaoRestAPIKey: String {
        return "f06398327f27f68dee975d91ade34bcd"
    }
    
    static var tmapAddressBaseURL: String {
        return "https://apis.openapi.sk.com/tmap/geo"
    }
    
    static var tmapAPIKey: String {
        return "l7xx26325307e8dc401eb8c7490ea62829c3"
    }
    
    static var kakaoNativeAppKey: String {
        return "27d01e20b51e5925bf386a6c5465849f"
    }
    
//    static var deviceId: String {
//        return KeychainManager.shared.getDeviceId()
//    }
    
    static var naverMapClientId: String {
        return "ldgt4i6s7l"
    }

    static var adMobBannerAdUnitId: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716" // 테스트 배너 광고 단위 ID
        #else
        return "ca-app-pub-5283496525222246/6292439277" // 프로덕션 배너 광고 단위 ID
        #endif
    }

    static var adMobNativeAdUnitId: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/3986624511" // 테스트 네이티브 광고 단위 ID
        #else
        return "" // 프로덕션 네이티브 광고 단위 ID 발급 후 교체 필요
        #endif
    }

    static var accessToken: String {
        return UserManager.shared.accessToken ?? ""
    }
    
    static var refreshToken: String {
        return UserManager.shared.refreshToken ?? ""
    }
    
    static var defaultHeader: [String: String] {
        return ["Content-Type": "application/json"]
    }
    
    static var headerWithAccessToken: [String: String] {
        return ["Content-Type": "application/json",
                "accessToken": Config.accessToken,
                "refreshToken": Config.refreshToken]
    }
    
    static var kakaoDeveloperName: String {
        return "띵진"
    }
    
    static var appleDeveloperName: String {
        return "이명진"
    }
}
