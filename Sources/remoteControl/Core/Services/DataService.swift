import Foundation
import Combine

class DataService: ObservableObject {
    @Published var records: [DataRecord] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var currentCompany: Company?
    
    func setCompany(_ company: Company) {
        currentCompany = company
        fetchRecords()
    }
    
    func fetchRecords() {
        guard let company = currentCompany else { return }
        
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(company.url)/records") else {
            error = "Неверный URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [DataRecord].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] records in
                    self?.records = records
                }
            )
            .store(in: &cancellables)
    }
    
    func createRecord(_ record: DataRecord) {
        guard let company = currentCompany else { return }
        
        guard let url = URL(string: "\(company.url)/records"),
              let data = try? JSONEncoder().encode(record) else {
            error = "Ошибка создания записи"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: DataRecord.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] newRecord in
                    self?.records.append(newRecord)
                }
            )
            .store(in: &cancellables)
    }
    
    func updateRecord(_ record: DataRecord) {
        guard let company = currentCompany else { return }
        
        guard let url = URL(string: "\(company.url)/records/\(record.id)"),
              let data = try? JSONEncoder().encode(record) else {
            error = "Ошибка обновления записи"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: DataRecord.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
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
        guard let company = currentCompany else { return }
        
        guard let url = URL(string: "\(company.url)/records/\(record.id)") else {
            error = "Ошибка удаления записи"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTaskPublisher(for: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.records.removeAll { $0.id == record.id }
                }
            )
            .store(in: &cancellables)
    }
}
