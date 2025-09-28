import Foundation
import Combine

class APIClient: ObservableObject {
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Generic Request Method
    
    func request<T: Codable>(
        url: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        
        guard let url = URL(string: url) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Log request for debugging
        logRequest(request)
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Логируем статус код и заголовки ответа
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 APIClient: Response status: \(httpResponse.statusCode)")
                    print("📡 APIClient: Response headers: \(httpResponse.allHeaderFields)")
                }
                
                // Логируем полный ответ сервера
                if let responseString = String(data: data, encoding: .utf8) {
                    if responseString.count > 1000 {
                        print("📡 APIClient: Response body (first 1000 chars): \(String(responseString.prefix(1000)))...")
                        print("📡 APIClient: Response body (last 500 chars): ...\(String(responseString.suffix(500)))")
                    } else {
                        print("📡 APIClient: Response body: \(responseString)")
                    }
                } else {
                    print("📡 APIClient: Response body: (binary data, \(data.count) bytes)")
                }
                
                try self.validateResponse(data: data, response: response)
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if let decodingError = error as? DecodingError {
                    return APIError.decodingFailed(decodingError)
                } else {
                    return APIError.networkError(error)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Authentication Methods
    
    func requestWithAuth<T: Codable>(
        url: String,
        method: HTTPMethod = .GET,
        secret: String? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        
        var headers: [String: String] = [:]
        
        if let secret = secret, !secret.isEmpty {
            headers["X-Remote-Secret"] = secret
        }
        
        return request(
            url: url,
            method: method,
            headers: headers,
            body: body,
            responseType: responseType
        )
    }
    
    // MARK: - Connection Testing
    
    func testConnection(to url: String, secret: String? = nil) -> AnyPublisher<Bool, APIError> {
        let checkAccessURL = "\(url)/api/remote/check-access"
        
        return requestWithAuth(
            url: checkAccessURL,
            method: .GET,
            secret: secret,
            responseType: CheckAccessResponse.self
        )
        .map { _ in true }
        .catch { error -> AnyPublisher<Bool, APIError> in
            // Handle specific errors
            switch error {
            case .unauthorized:
                // Wrong secret key
                return Just(false)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            case .forbidden:
                // Access denied
                return Just(false)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            case .notFound:
                // If check-access endpoint doesn't exist, try a simple GET request
                return self.simpleConnectionTest(url: url)
                    .eraseToAnyPublisher()
            default:
                // Other errors (network, server, etc.)
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func simpleConnectionTest(url: String) -> AnyPublisher<Bool, APIError> {
        guard let testURL = URL(string: url) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: testURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        return session.dataTaskPublisher(for: request)
            .tryMap { _, response in
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode < 500
                }
                return true
            }
            .mapError { error in
                APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Response Validation
    
    private func validateResponse(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 400:
            // Попытка парсинга ошибки валидации
            if let validationError = parseValidationError(from: data) {
                throw APIError.validationError(validationError)
            }
            throw APIError.badRequest
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.unknownError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Validation Error Parsing
    
    private func parseValidationError(from data: Data) -> ServerValidationError? {
        // Попытка парсинга как ValidationErrorResponse
        if let errorResponse = try? JSONDecoder().decode(ValidationErrorResponse.self, from: data) {
            return errorResponse.error
        }
        
        // Попытка парсинга как ServerValidationError напрямую
        if let validationError = try? JSONDecoder().decode(ServerValidationError.self, from: data) {
            return validationError
        }
        
        // Попытка парсинга простого сообщения об ошибке
        if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = errorDict["message"] as? String {
            return ServerValidationError(
                message: message,
                errors: nil,
                fieldErrors: nil
            )
        }
        
        return nil
    }
    
    // MARK: - Logging
    
    private func logRequest(_ request: URLRequest) {
        print("🌐 API Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let headers = request.allHTTPHeaderFields {
            print("📋 Headers: \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Request Body: \(bodyString)")
        } else {
            print("📦 Request Body: (empty)")
        }
    }
}

// MARK: - HTTP Methods

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingFailed(DecodingError)
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case unknownError(Int)
    case validationError(ServerValidationError)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .badRequest:
            return "Неверный запрос (400)"
        case .unauthorized:
            return "Не авторизован (401)"
        case .forbidden:
            return "Доступ запрещен (403)"
        case .notFound:
            return "Ресурс не найден (404)"
        case .serverError(let code):
            return "Ошибка сервера (\(code))"
        case .unknownError(let code):
            return "Неизвестная ошибка (\(code))"
        case .validationError(let validationError):
            return validationError.displayMessage
        }
    }
}

// MARK: - Response Models

struct CheckAccessResponse: Codable {
    let message: String
}

struct EmptyResponse: Codable {
    // Empty response for DELETE requests
}
