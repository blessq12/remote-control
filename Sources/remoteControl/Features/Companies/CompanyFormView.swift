import SwiftUI

struct CompanyFormView: View {
    @ObservedObject var companyStorage: CompanyStorageService
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    @State private var name: String
    @State private var url: String
    @State private var secret: String
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let mode: FormMode
    let company: Company?
    
    enum Field {
        case name, url, secret
    }
    
    enum FormMode {
        case add
        case edit
        
        var title: String {
            switch self {
            case .add: return "Добавить компанию"
            case .edit: return "Редактировать компанию"
            }
        }
        
        var saveButtonTitle: String {
            switch self {
            case .add: return "Добавить"
            case .edit: return "Сохранить"
            }
        }
    }
    
    init(companyStorage: CompanyStorageService, company: Company? = nil) {
        self.companyStorage = companyStorage
        self.company = company
        self.mode = company == nil ? .add : .edit
        
        if let company = company {
            self._name = State(initialValue: company.name)
            self._url = State(initialValue: company.url)
            self._secret = State(initialValue: company.secret)
        } else {
            self._name = State(initialValue: "")
            self._url = State(initialValue: "")
            self._secret = State(initialValue: "")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: mode == .add ? "plus.circle.fill" : "pencil.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text(mode.title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
                
                // Form
                VStack(alignment: .leading, spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Название компании", systemImage: "building.2")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Введите название", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .name)
                            .onSubmit {
                                focusedField = .url
                            }
                    }
                    
                    // URL field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("URL сервера", systemImage: "globe")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("https://example.com", text: $url)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .url)
                            .onSubmit {
                                focusedField = .secret
                            }
                        
                        Text("Укажите полный URL включая протокол")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Secret field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Secret ключ", systemImage: "key")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Введите secret для авторизации", text: $secret)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .secret)
                            .onSubmit {
                                if !name.isEmpty && !url.isEmpty {
                                    saveCompany()
                                }
                            }
                        
                        Text("Необязательное поле для дополнительной авторизации")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Buttons
                HStack(spacing: 12) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button(mode.saveButtonTitle) {
                        saveCompany()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(name.isEmpty || url.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .name
            }
        }
        .frame(width: 500, height: 600)
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveCompany() {
        // Validation
        guard !name.isEmpty else {
            errorMessage = "Название компании не может быть пустым"
            showingError = true
            return
        }
        
        guard !url.isEmpty else {
            errorMessage = "URL сервера не может быть пустым"
            showingError = true
            return
        }
        
        // URL validation
        guard let urlObject = URL(string: url), 
              (urlObject.scheme == "http" || urlObject.scheme == "https") else {
            errorMessage = "Введите корректный URL с протоколом (http:// или https://)"
            showingError = true
            return
        }
        
        // Check for duplicate names (excluding current company if editing)
        let existingCompanies = companyStorage.companies.filter { 
            $0.name.lowercased() == name.lowercased() && $0.id != company?.id 
        }
        
        if !existingCompanies.isEmpty {
            errorMessage = "Компания с таким названием уже существует"
            showingError = true
            return
        }
        
        // Save company
        switch mode {
        case .add:
            let newCompany = Company(name: name, url: url, secret: secret)
            companyStorage.addCompany(newCompany)
            
        case .edit:
            guard let company = company else { return }
            var updatedCompany = company
            updatedCompany.name = name
            updatedCompany.url = url
            updatedCompany.secret = secret
            companyStorage.updateCompany(updatedCompany)
        }
        
        dismiss()
    }
}
