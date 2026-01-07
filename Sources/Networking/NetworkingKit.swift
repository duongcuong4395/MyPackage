//
//  NetworkingKit.swift
//  MyLibrary
//
//  Created by Macbook on 29/10/25.
//

//
//  ImprovedNetworking.swift
//  MyLibrary
//
//  Enhanced version with better logging, type safety, and structure
//

import Foundation
import Alamofire


// MARK: - API Result
public enum APIResult2<T> {
    case success(T)
    case failure(Error)
}

// MARK: - API Errors
public enum APIError2: Error {
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case requestError(AFError)
    case invalidURL
    case pathNotFound(String)
    
    var localizedDescription: String {
        switch self {
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .requestError(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        case .pathNotFound(let key):
            return "Path not found for key: \(key)"
        }
    }
}

// MARK: - Request Body Protocol
/// Protocol for request body encoding with better logging support
public protocol RequestBody {
    func encode() throws -> Data
}

// Default implementation for Encodable types
extension RequestBody where Self: Encodable {
    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

// MARK: - HTTP Router Protocol
public protocol HttpRouter2 {
    associatedtype ResponseType: Decodable
    associatedtype BodyType: RequestBody
    
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: Any]? { get }
    var body: BodyType? { get }
    var timeout: TimeInterval { get }
    
    func handleResponse(with data: Data?, error: AFError?) -> APIResult2<ResponseType>
}

// MARK: - Default implementations
public extension HttpRouter2 {
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    var queryParameters: [String: Any]? {
        return nil
    }
    
    var body: BodyType? {
        return nil
    }
    
    var timeout: TimeInterval {
        return 30.0
    }
    
    func handleResponse(with data: Data?, error: AFError?) -> APIResult2<ResponseType> {
        if let err = error {
            NetworkLogger.shared.logError(err)
            return .failure(APIError2.requestError(err))
        }
        
        guard let data = data else {
            return .failure(APIError2.noData)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(ResponseType.self, from: data)
            return .success(result)
        } catch {
            NetworkLogger.shared.logError(error)
            return .failure(APIError2.decodingError(error))
        }
    }
}

// MARK: - Path Configuration Manager
public class PathConfigurationManager {
    nonisolated(unsafe) public static let shared = PathConfigurationManager()
    
    private var pathConfigurations: [String: [String: String]] = [:]
    
    private init() {}
    
    /// Load paths from plist file
    public func loadConfiguration(from fileName: String, bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: fileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: [String: String]] else {
            throw APIError2.pathNotFound(fileName)
        }
        
        pathConfigurations.merge(plist) { (_, new) in new }
        NetworkLogger.shared.log("✅ Loaded configuration from \(fileName).plist")
    }
    
    /// Get path for a specific key in a service
    public func path(for key: String, in service: String) throws -> String {
        guard let servicePaths = pathConfigurations[service],
              let path = servicePaths[key] else {
            throw APIError2.pathNotFound("\(service).\(key)")
        }
        return path
    }
    
    /// Get all paths for a service
    public func paths(for service: String) -> [String: String]? {
        return pathConfigurations[service]
    }
}

// MARK: - Network Logger
public class NetworkLogger {
    nonisolated(unsafe) public static let shared = NetworkLogger()
    
    public var isEnabled: Bool = true
    public var logLevel: LogLevel = .verbose
    
    public enum LogLevel: Int {
        case none = 0
        case error = 1
        case info = 2
        case verbose = 3
    }
    
    private init() {}
    
    public func log(_ message: String, level: LogLevel = .info) {
        guard isEnabled, level.rawValue <= logLevel.rawValue else { return }
        
        let emoji: String
        switch level {
        case .none: return
        case .error: emoji = "❌"
        case .info: emoji = "ℹ️"
        case .verbose: emoji = "📝"
        }
        
        print("\(emoji) [Network] \(message)")
    }
    
    public func logRequest(_ request: URLRequest) {
        guard isEnabled, logLevel == .verbose else { return }
        
        var output = "\n🚀 REQUEST\n"
        output += "URL: \(request.url?.absoluteString ?? "nil")\n"
        output += "Method: \(request.httpMethod ?? "nil")\n"
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            output += "Headers: \(headers)\n"
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            output += "Body: \(bodyString)\n"
        }
        
        print(output)
    }
    
    public func logResponse(_ response: HTTPURLResponse?, data: Data?) {
        guard isEnabled, logLevel == .verbose else { return }
        
        var output = "\n✅ RESPONSE\n"
        output += "Status Code: \(response?.statusCode ?? 0)\n"
        
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            output += "Body: \(prettyString)\n"
        }
        
        print(output)
    }
    
    public func logError(_ error: Error) {
        log("Error: \(error.localizedDescription)", level: .error)
    }
}

// MARK: - Request Interceptor
public protocol NetworkInterceptor {
    func willSendRequest(_ request: URLRequest) -> URLRequest
    func didReceiveResponse(_ response: HTTPURLResponse, data: Data?)
}

public class NetworkInterceptorManager {
    nonisolated(unsafe) public static let shared = NetworkInterceptorManager()
    
    private var interceptors: [NetworkInterceptor] = []
    
    private init() {}
    
    public func add(_ interceptor: NetworkInterceptor) {
        interceptors.append(interceptor)
    }
    
    public func removeAll() {
        interceptors.removeAll()
    }
    
    func intercept(request: URLRequest) -> URLRequest {
        var modifiedRequest = request
        for interceptor in interceptors {
            modifiedRequest = interceptor.willSendRequest(modifiedRequest)
        }
        return modifiedRequest
    }
    
    func intercept(response: HTTPURLResponse, data: Data?) {
        for interceptor in interceptors {
            interceptor.didReceiveResponse(response, data: data)
        }
    }
}

// MARK: - API Request
@available(iOS 13.0.0, *)
public class APIRequest2<Router: HttpRouter2> {
    public let router: Router
    
    public init(router: Router) {
        self.router = router
    }
    
    public func execute() async throws -> APIResult2<Router.ResponseType> {
        // Build URL
        guard let baseURL = try? router.baseURL.asURL() else {
            throw APIError2.invalidURL
        }
        
        let url = baseURL.appendingPathComponent(router.path)
        
        // Build URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = router.method.rawValue
        urlRequest.timeoutInterval = router.timeout
        
        // Add headers
        if let headers = router.headers {
            headers.forEach { key, value in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add query parameters
        if let queryParams = router.queryParameters, !queryParams.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryParams.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            if let queryURL = components?.url {
                urlRequest.url = queryURL
            }
        }
        
        // Add body
        if let body = router.body {
            do {
                urlRequest.httpBody = try body.encode()
            } catch {
                throw APIError2.encodingError(error)
            }
        }
        
        // Apply interceptors
        urlRequest = NetworkInterceptorManager.shared.intercept(request: urlRequest)
        
        // Log request
        NetworkLogger.shared.logRequest(urlRequest)
        
        // Execute request
        let response = await AF.request(urlRequest).serializingData().response
        
        // Log response
        if let httpResponse = response.response {
            NetworkLogger.shared.logResponse(httpResponse, data: response.data)
            NetworkInterceptorManager.shared.intercept(response: httpResponse, data: response.data)
        }
        
        return router.handleResponse(with: response.data, error: response.error)
    }
}

// MARK: - API Execution Protocol
@available(iOS 13.0.0, *)
public protocol APIExecution2 {}

@available(iOS 13.0.0, *)
public extension APIExecution2 {
    func sendRequest<T: Decodable, R: HttpRouter2>(
        for endpoint: R
    ) async throws -> T where R.ResponseType == T {
        let request = APIRequest2(router: endpoint)
        let result = try await request.execute()
        
        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Empty Body
public struct EmptyBody: RequestBody, Encodable {
    public init() {}
    
    public func encode() throws -> Data {
        return Data()
    }
}

// MARK: - Example Request Bodies
public struct JSONBody<T: Encodable>: RequestBody {
    private let value: T
    
    public init(_ value: T) {
        self.value = value
    }
    
    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }
}

public struct FormURLEncodedBody: RequestBody {
    private let parameters: [String: String]
    
    public init(parameters: [String: String]) {
        self.parameters = parameters
    }
    
    public func encode() throws -> Data {
        let formString = parameters
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
        
        guard let data = formString.data(using: .utf8) else {
            throw APIError2.encodingError(NSError(domain: "FormEncoding", code: -1))
        }
        
        return data
    }
}
