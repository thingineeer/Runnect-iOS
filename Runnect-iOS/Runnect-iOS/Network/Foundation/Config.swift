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

    static var adMobNativeAdUnitId: String {
        return AdConfig.nativeAdUnitId
    }

    static var adMobCarouselNativeAdUnitId: String {
        return AdConfig.carouselNativeAdUnitId
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

    static var developerPassword: String {
        return "970821"
    }
}
