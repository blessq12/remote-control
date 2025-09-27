import SwiftUI

struct DynamicFormView: View {
    let table: SchemaTable
    @Binding var fieldValues: [String: String]
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Table info header
            VStack(alignment: .leading, spacing: 8) {
                Text("Таблица: \(table.name)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(table.fields.count) полей")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // Dynamic form fields
            VStack(spacing: 16) {
                ForEach(table.fields, id: \.id) { field in
                    FieldRowView(
                        field: field,
                        value: Binding(
                            get: { fieldValues[field.name] ?? "" },
                            set: { fieldValues[field.name] = $0 }
                        )
                    )
                }
            }
        }
        .padding()
        .alert("Ошибка валидации", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // Validation method
    func validateForm() -> Bool {
        for field in table.fields {
            let value = fieldValues[field.name] ?? ""
            
            // Check required fields (we'll assume all non-readonly fields are required for now)
            if !field.readonly && value.isEmpty {
                errorMessage = "Поле '\(field.name)' обязательно для заполнения"
                showingError = true
                return false
            }
            
            // Type-specific validation
            if !value.isEmpty {
                switch field.type {
                case .email:
                    if !isValidEmail(value) {
                        errorMessage = "Поле '\(field.name)' должно содержать корректный email"
                        showingError = true
                        return false
                    }
                case .url:
                    if !isValidURL(value) {
                        errorMessage = "Поле '\(field.name)' должно содержать корректный URL"
                        showingError = true
                        return false
                    }
                case .integer:
                    if Int(value) == nil {
                        errorMessage = "Поле '\(field.name)' должно содержать число"
                        showingError = true
                        return false
                    }
                case .boolean:
                    if !["true", "false", "1", "0", "yes", "no"].contains(value.lowercased()) {
                        errorMessage = "Поле '\(field.name)' должно содержать true/false"
                        showingError = true
                        return false
                    }
                default:
                    break
                }
            }
        }
        return true
    }
    
    // Helper validation methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
}

struct FieldRowView: View {
    let field: SchemaField
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(field.name, systemImage: fieldIcon)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if field.readonly {
                    Text("Только чтение")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            
            fieldInputView
            
            if let description = fieldDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var fieldInputView: some View {
        if field.readonly {
            Text(value.isEmpty ? "—" : value)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        } else {
            switch field.type {
            case .string, .email, .url:
                TextField(fieldPlaceholder, text: $value)
                    .textFieldStyle(.roundedBorder)
                
            case .integer:
                TextField(fieldPlaceholder, text: $value)
                    .textFieldStyle(.roundedBorder)
                
            case .boolean:
                Picker("", selection: $value) {
                    Text("Да").tag("true")
                    Text("Нет").tag("false")
                }
                .pickerStyle(.segmented)
                
            case .date:
                DatePicker("", selection: Binding(
                    get: { 
                        if let date = ISO8601DateFormatter().date(from: value) {
                            return date
                        }
                        return Date()
                    },
                    set: { newDate in
                        value = ISO8601DateFormatter().string(from: newDate)
                    }
                ))
                .datePickerStyle(.compact)
            }
        }
    }
    
    private var fieldIcon: String {
        switch field.type {
        case .string: return "textformat"
        case .integer: return "number"
        case .boolean: return "checkmark.circle"
        case .date: return "calendar"
        case .email: return "envelope"
        case .url: return "link"
        }
    }
    
    private var fieldPlaceholder: String {
        switch field.type {
        case .string: return "Введите текст"
        case .integer: return "Введите число"
        case .boolean: return "Выберите значение"
        case .date: return "Выберите дату"
        case .email: return "example@domain.com"
        case .url: return "https://example.com"
        }
    }
    
    private var fieldDescription: String? {
        switch field.type {
        case .email: return "Введите корректный email адрес"
        case .url: return "Введите полный URL с протоколом"
        case .integer: return "Введите целое число"
        case .boolean: return "Выберите Да или Нет"
        case .date: return "Выберите дату"
        default: return nil
        }
    }
}

#Preview {
    let sampleTable = SchemaTable(
        name: "companies",
        fields: [
            SchemaField(name: "id", type: .integer, readonly: true),
            SchemaField(name: "name", type: .string, readonly: false),
            SchemaField(name: "email", type: .email, readonly: false)
        ]
    )
    
    return DynamicFormView(
        table: sampleTable,
        fieldValues: .constant(["id": "1", "name": "Test Company", "email": "test@example.com"])
    )
    .padding()
}
