import SwiftUI

struct AddRecordView: View {
    let schema: Schema
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var fieldValues: [String: String] = [:]
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(schema.tables.first?.fields ?? [], id: \.id) { field in
                    FieldSection(field: field, fieldValues: $fieldValues)
                }
            }
            .navigationTitle("Новая запись")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveRecord()
                    }
                }
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveRecord() {
        // Валидация обязательных полей
        for field in schema.tables.first?.fields ?? [] {
            if field.isRequired && (fieldValues[field.name]?.isEmpty ?? true) {
                errorMessage = "Поле '\(field.name)' обязательно для заполнения"
                showingError = true
                return
            }
        }
        
        // Конвертация значений в AnyCodable
        var data: [String: AnyCodable] = [:]
        
        for field in schema.tables.first?.fields ?? [] {
            let value = fieldValues[field.name] ?? ""
            
            switch field.type {
            case .string, .email, .url:
                data[field.name] = AnyCodable(value)
            case .integer:
                data[field.name] = AnyCodable(Int(value) ?? 0)
            case .boolean:
                data[field.name] = AnyCodable(value == "true")
            case .date:
                data[field.name] = AnyCodable(value)
            }
        }
        
        let record = DataRecord(data: data)
        dataService.createRecord(record)
        dismiss()
    }
}

struct FieldSection: View {
    let field: SchemaField
    @Binding var fieldValues: [String: String]
    
    var body: some View {
        Section(field.name) {
            switch field.type {
            case .string, .email, .url:
                TextField(field.name, text: Binding(
                    get: { fieldValues[field.name] ?? "" },
                    set: { fieldValues[field.name] = $0 }
                ))
                
            case .integer:
                TextField(field.name, text: Binding(
                    get: { fieldValues[field.name] ?? "" },
                    set: { fieldValues[field.name] = $0 }
                ))
                
            case .boolean:
                Toggle(field.name, isOn: Binding(
                    get: { fieldValues[field.name] == "true" },
                    set: { fieldValues[field.name] = $0 ? "true" : "false" }
                ))
                
            case .date:
                DatePicker(field.name, selection: Binding(
                    get: { 
                        if let dateString = fieldValues[field.name],
                           let date = ISO8601DateFormatter().date(from: dateString) {
                            return date
                        }
                        return Date()
                    },
                    set: { 
                        fieldValues[field.name] = ISO8601DateFormatter().string(from: $0)
                    }
                ))
            }
        }
    }
}
