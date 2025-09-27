import SwiftUI

struct AddCompanyView: View {
    @ObservedObject var companyStorage: CompanyStorageService
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    @State private var name = ""
    @State private var url = ""
    @State private var secret = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum Field {
        case name, url, secret
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Добавить компанию")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Название компании")
                        .font(.headline)
                    TextField("Введите название", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .name)
                        .onSubmit {
                            focusedField = .url
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("URL сервера")
                        .font(.headline)
                    TextField("https://example.com", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .url)
                        .onSubmit {
                            focusedField = .secret
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Secret ключ")
                        .font(.headline)
                    TextField("Введите secret для авторизации", text: $secret)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .secret)
                        .onSubmit {
                            if !name.isEmpty && !url.isEmpty {
                                saveCompany()
                            }
                        }
                }
                
                Text("Укажите полный URL включая протокол (http:// или https://)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Сохранить") {
                    saveCompany()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(name.isEmpty || url.isEmpty)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .onAppear {
            // Принудительно активируем окно и фокусируемся на первом поле
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                // Даем время sheet'у полностью загрузиться
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    focusedField = .name
                }
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveCompany() {
        guard !name.isEmpty, !url.isEmpty else {
            errorMessage = "Заполните все поля"
            showingError = true
            return
        }
        
        // Простая валидация URL
        guard URL(string: url) != nil else {
            errorMessage = "Введите корректный URL"
            showingError = true
            return
        }
        
        let company = Company(name: name, url: url, secret: secret)
        companyStorage.addCompany(company)
        dismiss()
    }
}
