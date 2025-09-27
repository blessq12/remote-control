import Foundation
import Combine

class CompanyStorageService: ObservableObject {
    @Published var companies: [Company] = []
    
    private let storageKey = "saved_companies"
    
    init() {
        loadCompanies()
    }
    
    func addCompany(_ company: Company) {
        companies.append(company)
        saveCompanies()
    }
    
    func updateCompany(_ company: Company) {
        if let index = companies.firstIndex(where: { $0.id == company.id }) {
            companies[index] = company
            saveCompanies()
        }
    }
    
    func deleteCompany(_ company: Company) {
        companies.removeAll { $0.id == company.id }
        saveCompanies()
    }
    
    func setActiveCompany(_ company: Company) {
        companies.indices.forEach { index in
            companies[index].isActive = false
        }
        
        if let index = companies.firstIndex(where: { $0.id == company.id }) {
            companies[index].isActive = true
            saveCompanies()
        }
    }
    
    var activeCompany: Company? {
        companies.first { $0.isActive }
    }
    
    private func saveCompanies() {
        if let data = try? JSONEncoder().encode(companies) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadCompanies() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let companies = try? JSONDecoder().decode([Company].self, from: data) {
            self.companies = companies
        }
    }
}
