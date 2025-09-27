import SwiftUI

struct AddRecordView: View {
    let table: SchemaTable
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var fieldValues: [String: String] = [:]
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    init(table: SchemaTable, dataService: DataService) {
        self.table = table
        self.dataService = dataService
    }
    
    var body: some View {
        NavigationView {
            DynamicFormView(
                table: table,
                fieldValues: $fieldValues
            )
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
            if !field.readonly {
                switch field.type {
                case .boolean:
                    fieldValues[field.name] = "false"
                case .date:
                    fieldValues[field.name] = ISO8601DateFormatter().string(from: Date())
                case .datetime:
                    fieldValues[field.name] = ISO8601DateFormatter().string(from: Date())
                default:
                    fieldValues[field.name] = ""
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
            }
        }
        
        let record = DataRecord(data: data)
        
        // Save via DataService
        dataService.createRecord(record)
        
        // Close the sheet after a short delay to allow for the record to be created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
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
    
    return AddRecordView(
        table: sampleTable,
        dataService: DataService()
    )
}