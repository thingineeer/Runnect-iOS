//
//  AuthInterceptor.swift
//  Runnect-iOS
//
//  Created by sejin on 2023/04/04.
//

import Foundation

import Alamofire
import Moya

///// 토큰 만료 시 자동으로 refresh를 위한 서버 통신
final class AuthInterceptor: RequestInterceptor {

    static let shared = AuthInterceptor()

    private init() {}

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest

        guard urlRequest.url?.absoluteString.hasPrefix(Config.baseURL) == true else {
            completion(.success(urlRequest))
            return
        }

        // 실제 토큰이 있으면 등록 사용자로 처리
        if let accessToken = UserManager.shared.accessToken,
           let refreshToken = UserManager.shared.refreshToken {
            urlRequest.setValue(accessToken, forHTTPHeaderField: "accessToken")
            urlRequest.setValue(refreshToken, forHTTPHeaderField: "refreshToken")
            print("[AuthInterceptor] 토큰 주입 완료 - userType: \(UserManager.shared.userType), url: \(urlRequest.url?.lastPathComponent ?? "")")
            completion(.success(urlRequest))
            return
        }

        // 토큰이 없는 방문자일 경우
        if UserManager.shared.userType == .visitor {
            urlRequest.setValue("visitor", forHTTPHeaderField: "accessToken")
            urlRequest.setValue("visitor", forHTTPHeaderField: "refreshToken")
            print("[AuthInterceptor] visitor 모드 - url: \(urlRequest.url?.lastPathComponent ?? "")")
        } else {
            print("[AuthInterceptor] 토큰 nil, userType: \(UserManager.shared.userType) - url: \(urlRequest.url?.lastPathComponent ?? "")")
        }

        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        print("retry 진입")
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401, let pathComponents = request.request?.url?.pathComponents,
              !pathComponents.contains("getNewToken")
        else {
            dump(error)
            completion(.doNotRetryWithError(error))
            return
        }

        UserManager.shared.getNewToken { result in
            switch result {
            case .success:
                print("Retry-토큰 재발급 성공")
                completion(.retry)
            case .failure(let error):
                // 세션 만료 -> 로그인 화면으로 전환
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
