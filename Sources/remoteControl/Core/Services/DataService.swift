import Foundation
import Combine

class DataService: ObservableObject {
    @Published var records: [DataRecord] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var pagination: PaginationInfo?
    
    private var cancellables = Set<AnyCancellable>()
    private var currentCompany: Company?
    private var currentTable: SchemaTable?
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
    
    func setCompany(_ company: Company) {
        currentCompany = company
        print("🏢 DataService: Company set to \(company.name)")
        // Don't fetch records here - wait for table selection
    }
    
    func fetchRecords(for table: SchemaTable, page: Int = 1, limit: Int = 20) {
        guard let company = currentCompany else { 
            print("❌ DataService: No current company")
            return 
        }
        
        currentTable = table
        isLoading = true
        error = nil
        connectionStatus = .connecting
        
        let recordsURL = "\(company.url)/api/remote/\(table.name)?page=\(page)&limit=\(limit)"
        print("🔍 DataService: Fetching records from: \(recordsURL)")
        
        apiClient.requestWithAuth(
            url: recordsURL,
            method: .GET,
            secret: company.secret,
            responseType: PaginatedResponse<[DataRecord]>.self
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let apiError) = completion {
                    print("❌ DataService: Failed to fetch records: \(apiError.errorDescription ?? "Unknown error")")
                    self?.error = apiError.errorDescription
                    self?.connectionStatus = .failed(apiError.errorDescription ?? "Ошибка загрузки данных")
                }
            },
            receiveValue: { [weak self] response in
                print("✅ DataService: Successfully fetched \(response.data.count) records")
                print("📊 DataService: Pagination - page \(response.pagination.page) of \(response.pagination.pages)")
                self?.records = response.data
                self?.pagination = response.pagination
                self?.connectionStatus = .connected
            }
        )
        .store(in: &cancellables)
    }
    
    func fetchRecord(for table: SchemaTable, id: UUID) {
        guard let company = currentCompany else { return }
        
        isLoading = true
        error = nil
        connectionStatus = .connecting
        
        let recordURL = "\(company.url)/api/remote/\(table.name)/\(id)"
        
        apiClient.requestWithAuth(
            url: recordURL,
            method: .GET,
            secret: company.secret,
            responseType: DataRecord.self
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let apiError) = completion {
                    self?.error = apiError.errorDescription
                    self?.connectionStatus = .failed(apiError.errorDescription ?? "Ошибка загрузки записи")
                }
            },
            receiveValue: { [weak self] record in
                // Заменяем запись в списке если она есть, иначе добавляем
                if let index = self?.records.firstIndex(where: { $0.id == record.id }) {
                    self?.records[index] = record
                } else {
                    self?.records.append(record)
                }
                self?.connectionStatus = .connected
            }
        )
        .store(in: &cancellables)
    }
    
    func createRecord(_ record: DataRecord) {
        guard let company = currentCompany,
              let table = currentTable else { return }
        
        guard let data = try? JSONEncoder().encode(record) else {
            error = "Ошибка кодирования записи"
            return
        }
        
        let recordsURL = "\(company.url)/api/remote/\(table.name)"
        
        apiClient.requestWithAuth(
            url: recordsURL,
            method: .POST,
            secret: company.secret,
            body: data,
            responseType: DataRecord.self
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let apiError) = completion {
                    self?.error = apiError.errorDescription
                }
            },
            receiveValue: { [weak self] newRecord in
                self?.records.append(newRecord)
            }
        )
        .store(in: &cancellables)
    }
    
    func updateRecord(_ record: DataRecord) {
        guard let company = currentCompany,
              let table = currentTable else { return }
        
        guard let data = try? JSONEncoder().encode(record) else {
            error = "Ошибка кодирования записи"
            return
        }
        
        let recordURL = "\(company.url)/api/remote/\(table.name)/\(record.id)"
        
        apiClient.requestWithAuth(
            url: recordURL,
            method: .PUT,
            secret: company.secret,
            body: data,
            responseType: DataRecord.self
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let apiError) = completion {
                    self?.error = apiError.errorDescription
                }
            },
            receiveValue: { [weak self] updatedRecord in
                if let index = self?.records.firstIndex(where: { $0.id == updatedRecord.id }) {
                    self?.records[index] = updatedRecord
                }
            }
        )
        .store(in: &cancellables)
    }
    
    func deleteRecord(_ record: DataRecord) {
        guard let company = currentCompany,
              let table = currentTable else { return }
        
        let recordURL = "\(company.url)/api/remote/\(table.name)/\(record.id)"
        
        apiClient.requestWithAuth(
            url: recordURL,
            method: .DELETE,
            secret: company.secret,
            responseType: EmptyResponse.self
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let apiError) = completion {
                    self?.error = apiError.errorDescription
                }
            },
            receiveValue: { [weak self] _ in
                self?.records.removeAll { $0.id == record.id }
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
        }
    }
}
