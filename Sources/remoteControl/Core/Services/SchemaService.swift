import Foundation
import Combine

class SchemaService: ObservableObject {
    @Published var currentSchema: Schema?
    @Published var isLoading = false
    @Published var error: String?
    @Published var connectionStatus: ConnectionStatus = .unknown
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient()
    
    enum ConnectionStatus: Equatable {
        case unknown
        case connecting
        case connected
        case failed(String)
        
        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
        
        static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown), (.connecting, .connecting), (.connected, .connected):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    func fetchSchema(for company: Company) {
        isLoading = true
        error = nil
        connectionStatus = .connecting
        
        let schemaURL = "\(company.url)/api/remote/schema"
        
        apiClient.requestWithAuth(
            url: schemaURL,
            method: .GET,
            secret: company.secret,
            responseType: Schema.self
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let apiError) = completion {
                    self?.error = apiError.errorDescription
                    self?.connectionStatus = .failed(apiError.errorDescription ?? "Неизвестная ошибка")
                }
            },
            receiveValue: { [weak self] schema in
                self?.currentSchema = schema
                self?.connectionStatus = .connected
            }
        )
        .store(in: &cancellables)
    }
    
    func testConnection(to company: Company) {
        connectionStatus = .connecting
        
        apiClient.testConnection(to: company.url, secret: company.secret)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let apiError) = completion {
                        let errorMessage = self?.getConnectionErrorMessage(for: apiError) ?? "Ошибка соединения"
                        self?.connectionStatus = .failed(errorMessage)
                    }
                },
                receiveValue: { [weak self] isConnected in
                    self?.connectionStatus = isConnected ? .connected : .failed("Неверный ключ авторизации")
                }
            )
            .store(in: &cancellables)
    }
    
    private func getConnectionErrorMessage(for error: APIError) -> String {
        switch error {
        case .unauthorized:
            return "Неверный ключ авторизации"
        case .forbidden:
            return "Доступ запрещен"
        case .notFound:
            return "Сервер не поддерживает проверку соединения"
        case .badRequest:
            return "Неверный запрос"
        case .serverError(let code):
            return "Ошибка сервера (\(code))"
        case .networkError:
            return "Ошибка сети"
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .decodingFailed:
            return "Ошибка обработки данных"
        case .unknownError(let code):
            return "Неизвестная ошибка (\(code))"
        case .validationError(let validationError):
            return validationError.displayMessage
        }
    }
    
    func clearSchema() {
        currentSchema = nil
        error = nil
    }
}
