//
//  Networking.swift
//  MyLibrary
//
//  Created by Macbook on 2/1/25.
//

import Foundation
import Alamofire

public enum APIResult<T> {
    case Successs(T)
    case Failure(Error)
}

public enum APIError: Error {
    case DataFail
    case DecodingError
    case requestError(AFError)
}

public  protocol HttpRouter {
    associatedtype responseDataType: Decodable
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var parameters: Parameters? { get }
    var body: Data? { get }
    
    func handleResponse(with data: Data?, error: AFError?) -> APIResult<responseDataType>
}

extension HttpRouter {
    public func handleResponse(with data: Data?, error: AFError?) -> APIResult<responseDataType> {
        if let err = error {
            return .Failure(APIError.requestError(err))
        }
        
        guard let data = data else {
            return .Failure(APIError.DataFail)
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(responseDataType.self, from: data)
            return .Successs(result)
        } catch {
            print("=== Decoding.error", responseDataType.self, error)
            return .Failure(APIError.DecodingError)
        }
    }
}

import SwiftUI

public class APIRequest<Router: HttpRouter> {
    public let router: Router
    
    public init(router: Router) {
        self.router = router
    }
    
    @available(iOS 13.0.0, *)
    public func callAPI() async throws -> APIResult<Router.responseDataType> {
        // Tạo URL từ router
        guard let url = try? router.baseURL.asURL().appendingPathComponent(router.path) else {
            throw URLError(.badURL)
        }
        print("Enpoint: ", url, router.parameters as Any)

        // Gửi yêu cầu và đợi kết quả
        let response = await AF.request(url, method: router.method, parameters: router.parameters, headers: router.headers).serializingData().response

        // Kiểm tra kết quả trả về từ server
        let result = self.router.handleResponse(with: response.data, error: response.error)
        
        // Trả về kết quả
        return result
    }
}