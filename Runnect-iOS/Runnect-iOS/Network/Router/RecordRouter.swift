//
//  RecordRouter.swift
//  Runnect-iOS
//
//  Created by sejin on 2023/02/16.
//

import Foundation

import Moya

enum RecordRouter {
    case recordRunning(param: RunningRecordRequestDto)
    case getActivityRecordInfo
    case deleteRecord(recordIdList: [Int])
    case updateRecordTitle(recordId: Int, recordTitle: String)
    case saveHealthData(recordId: Int, param: HealthDataSaveRequestDto)
    case getHealthData(recordId: Int)
    case deleteHealthData(recordId: Int)
    case getHealthSummary(startDate: String, endDate: String)
}

extension RecordRouter: TargetType {
    var baseURL: URL {
        guard let url = URL(string: Config.baseURL) else {
            fatalError("baseURL could not be configured")
        }
        
        return url
    }
    
    var path: String {
        switch self {
        case .recordRunning, .deleteRecord:
            return "/record"
        case .getActivityRecordInfo:
            return "/record/user"
        case .updateRecordTitle(recordId: let recordId, _):
            return "/record/\(recordId)"
        case .saveHealthData(let recordId, _),
             .getHealthData(let recordId),
             .deleteHealthData(let recordId):
            return "/record/\(recordId)/health"
        case .getHealthSummary:
            return "/health/summary"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .recordRunning, .saveHealthData:
            return .post
        case .getActivityRecordInfo, .getHealthData, .getHealthSummary:
            return .get
        case .deleteRecord:
            return .put
        case .updateRecordTitle:
            return .patch
        case .deleteHealthData:
            return .delete
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .recordRunning(let param):
            do {
                return .requestParameters(parameters: try param.asParameter(), encoding: JSONEncoding.default)
            } catch {
                fatalError(error.localizedDescription)
            }
        case .getActivityRecordInfo:
            return .requestPlain
        case .deleteRecord(let recordIdList):
            return .requestParameters(parameters: ["recordIdList": recordIdList], encoding: JSONEncoding.default)
        case .updateRecordTitle(_, let recordTitle):
            do {
                return .requestParameters(parameters: ["title": recordTitle], encoding: JSONEncoding.default)
            }
        case .saveHealthData(_, let param):
            do {
                return .requestParameters(parameters: try param.asParameter(), encoding: JSONEncoding.default)
            } catch {
                fatalError(error.localizedDescription)
            }
        case .getHealthData, .deleteHealthData:
            return .requestPlain
        case .getHealthSummary(let startDate, let endDate):
            return .requestParameters(
                parameters: ["startDate": startDate, "endDate": endDate],
                encoding: URLEncoding.queryString
            )
        }
    }
    
    var headers: [String: String]? {
        switch self {
        default:
            return Config.defaultHeader
        }
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
}
