import SwiftUI

extension DateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct DynamicFormView: View {
    let table: SchemaTable
    @Binding var fieldValues: [String: String]
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var validationErrors: [String: String] = [:]
    
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
                        ),
                        validationError: validationErrors[field.name]
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
    
    // MARK: - Validation Error Handling
    
    func setValidationErrors(_ errors: [String: String]) {
        validationErrors = errors
    }
    
    func clearValidationErrors() {
        validationErrors.removeAll()
    }
    
    func setGeneralError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

struct FieldRowView: View {
    let field: SchemaField
    @Binding var value: String
    let validationError: String?
    
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
            
            // Показ ошибки валидации
            if let validationError = validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(validationError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
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
            case .string, .text, .url:
                TextField(fieldPlaceholder, text: $value)
                    .textFieldStyle(.roundedBorder)
                
            case .email:
                TextField(fieldPlaceholder, text: $value)
                    .textFieldStyle(.roundedBorder)
                
            case .password:
                SecureField(fieldPlaceholder, text: $value)
                    .textFieldStyle(.roundedBorder)
                
            case .integer, .decimal:
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
                        if let date = DateFormatter.dateFormatter.date(from: value) {
                            return date
                        }
                        return Date()
                    },
                    set: { newDate in
                        value = DateFormatter.dateFormatter.string(from: newDate)
                    }
                ))
                .datePickerStyle(.compact)
                
            case .datetime:
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
                
            case .json:
                TextEditor(text: $value)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var fieldIcon: String {
        switch field.type {
        case .string, .text: return "textformat"
        case .integer, .decimal: return "number"
        case .boolean: return "checkmark.circle"
        case .date: return "calendar"
        case .datetime: return "clock"
        case .email: return "envelope"
        case .url: return "link"
        case .password: return "lock"
        case .json: return "curlybraces"
        }
    }
    
    private var fieldPlaceholder: String {
        switch field.type {
        case .string: return "Введите текст"
        case .text: return "Введите длинный текст"
        case .integer: return "Введите число"
        case .decimal: return "Введите десятичное число"
        case .boolean: return "Выберите значение"
        case .date: return "Выберите дату"
        case .datetime: return "Выберите дату и время"
        case .email: return "example@domain.com"
        case .url: return "https://example.com"
        case .password: return "Введите пароль"
        case .json: return "Введите JSON"
        }
    }
    
    private var fieldDescription: String? {
        switch field.type {
        case .email: return "Введите корректный email адрес"
        case .url: return "Введите полный URL с протоколом"
        case .integer: return "Введите целое число"
        case .decimal: return "Введите десятичное число (например: 123.45)"
        case .boolean: return "Выберите Да или Нет"
        case .date: return "Выберите дату"
        case .datetime: return "Выберите дату и время"
        case .password: return "Введите пароль"
        case .json: return "Введите валидный JSON"
        case .text: return "Многострочный текст"
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
