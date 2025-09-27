import Foundation
import Combine

class SchemaService: ObservableObject {
    @Published var currentSchema: Schema?
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchSchema(for company: Company) {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(company.url)/schema") else {
            error = "Неверный URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: Schema.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] schema in
                    self?.currentSchema = schema
                }
            )
            .store(in: &cancellables)
    }
    
    func clearSchema() {
        currentSchema = nil
        error = nil
    }
}
