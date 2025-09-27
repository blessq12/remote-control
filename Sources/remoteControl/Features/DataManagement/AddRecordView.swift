import SwiftUI

struct AddRecordView: View {
    let schema: Schema
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTable: SchemaTable?
    @State private var fieldValues: [String: String] = [:]
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if selectedTable == nil {
                    TableSelectorView(
                        tables: schema.tables,
                        selectedTable: $selectedTable
                    ) { table in
                        selectedTable = table
                        initializeFieldValues(for: table)
                    }
                    .navigationTitle("Выберите таблицу")
                } else {
                    DynamicFormView(
                        table: selectedTable!,
                        fieldValues: $fieldValues
                    )
                    .navigationTitle("Новая запись")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Назад") {
                                selectedTable = nil
                                fieldValues = [:]
                            }
                        }
                        
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") {
                                dismiss()
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Сохранить") {
                                saveRecord()
                            }
                            .disabled(!isFormValid)
                        }
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
    
    private func initializeFieldValues(for table: SchemaTable) {
        fieldValues = [:]
        for field in table.fields {
            if !field.readonly {
                switch field.type {
                case .boolean:
                    fieldValues[field.name] = "false"
                case .date:
                    fieldValues[field.name] = ISO8601DateFormatter().string(from: Date())
                default:
                    fieldValues[field.name] = ""
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let table = selectedTable else { return false }
        
        for field in table.fields {
            let value = fieldValues[field.name] ?? ""
            
            // Check required fields (non-readonly fields are required)
            if !field.readonly && value.isEmpty {
                return false
            }
        }
        
        return true
    }
    
    private func saveRecord() {
        guard let table = selectedTable else { return }
        
        // Convert field values to AnyCodable dictionary
        var data: [String: AnyCodable] = [:]
        
        for field in table.fields {
            let value = fieldValues[field.name] ?? ""
            
            // Convert value based on field type
            let codableValue: AnyCodable
            switch field.type {
            case .string, .email, .url:
                codableValue = AnyCodable(value)
            case .integer:
                codableValue = AnyCodable(Int(value) ?? 0)
            case .boolean:
                codableValue = AnyCodable(value.lowercased() == "true" || value == "1")
            case .date:
                if let date = ISO8601DateFormatter().date(from: value) {
                    codableValue = AnyCodable(date)
                } else {
                    codableValue = AnyCodable(value)
                }
            }
            
            data[field.name] = codableValue
        }
        
        let record = DataRecord(data: data)
        
        // Save via DataService
        dataService.createRecord(record)
        
        dismiss()
    }
}

#Preview {
    let sampleSchema = Schema(tables: [
        SchemaTable(
            name: "companies",
            fields: [
                SchemaField(name: "id", type: .integer, readonly: true),
                SchemaField(name: "name", type: .string, readonly: false),
                SchemaField(name: "email", type: .email, readonly: false)
            ]
        )
    ])
    
    return AddRecordView(
        schema: sampleSchema,
        dataService: DataService()
    )
}