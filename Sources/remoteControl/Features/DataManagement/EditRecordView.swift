import SwiftUI

struct EditRecordView: View {
    let record: DataRecord
    let table: SchemaTable
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var fieldValues: [String: String] = [:]
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    init(record: DataRecord, table: SchemaTable, dataService: DataService) {
        self.record = record
        self.table = table
        self.dataService = dataService
    }
    
    var body: some View {
        NavigationView {
            DynamicFormView(
                table: table,
                fieldValues: $fieldValues
            )
            .navigationTitle("Редактировать запись")
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
                    .disabled(isSaving)
                }
            }
            .onAppear {
                initializeFieldValues()
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func initializeFieldValues() {
        fieldValues = [:]
        for field in table.fields {
            if let value = record.data[field.name] {
                // Convert AnyCodable value to string
                switch value.value {
                case let stringValue as String:
                    fieldValues[field.name] = stringValue
                case let intValue as Int:
                    if field.type == .boolean {
                        fieldValues[field.name] = intValue == 1 ? "true" : "false"
                    } else {
                        fieldValues[field.name] = String(intValue)
                    }
                case let doubleValue as Double:
                    fieldValues[field.name] = String(doubleValue)
                case let boolValue as Bool:
                    fieldValues[field.name] = boolValue ? "true" : "false"
                case let dateValue as Date:
                    if field.type == .date {
                        fieldValues[field.name] = DateFormatter.dateFormatter.string(from: dateValue)
                    } else {
                        fieldValues[field.name] = ISO8601DateFormatter().string(from: dateValue)
                    }
                default:
                    fieldValues[field.name] = String(describing: value.value)
                }
            } else {
                // Set default values for empty fields
                if !field.readonly {
                    switch field.type {
                    case .boolean:
                        fieldValues[field.name] = "false"
                    case .date:
                        fieldValues[field.name] = DateFormatter.dateFormatter.string(from: Date())
                    case .datetime:
                        fieldValues[field.name] = ISO8601DateFormatter().string(from: Date())
                    default:
                        fieldValues[field.name] = ""
                    }
                }
            }
        }
    }
    
    private func saveRecord() {
        isSaving = true
        
        // Convert field values to AnyCodable dictionary
        var data: [String: AnyCodable] = [:]
        
        for field in table.fields {
            if !field.readonly {
                let value = fieldValues[field.name] ?? ""
                
                // Send all values as strings - server handles type conversion
                let codableValue = AnyCodable(value)
                
                data[field.name] = codableValue
            } else {
                // Keep readonly fields as they are
                if let existingValue = record.data[field.name] {
                    data[field.name] = existingValue
                }
            }
        }
        
        // Create updated record with same ID
        var updatedRecord = record
        updatedRecord.data = data
        
        // Save via DataService
        dataService.updateRecord(updatedRecord)
        
        // Close the sheet after a short delay to allow for the record to be updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    let sampleRecord = DataRecord(data: [
        "name": AnyCodable("Test Product"),
        "price": AnyCodable("100"),
        "visible": AnyCodable(1)
    ])
    
    let sampleTable = SchemaTable(
        name: "products",
        fields: [
            SchemaField(name: "name", type: .string, required: true),
            SchemaField(name: "price", type: .decimal, required: true),
            SchemaField(name: "visible", type: .boolean)
        ]
    )
    
    return EditRecordView(
        record: sampleRecord,
        table: sampleTable,
        dataService: DataService()
    )
}
