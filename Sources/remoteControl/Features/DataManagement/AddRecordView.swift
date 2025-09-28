import SwiftUI

struct AddRecordView: View {
    let table: SchemaTable
    let dataService: DataService
    let onDismiss: () -> Void
    
    @State private var fieldValues: [String: String] = [:]
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var formView: DynamicFormView?
    
    init(table: SchemaTable, dataService: DataService, onDismiss: @escaping () -> Void) {
        self.table = table
        self.dataService = dataService
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Новая запись")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Сохранить") {
                    saveRecord()
                }
                .disabled(isSaving)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Form content
            ScrollView {
                DynamicFormView(
                    table: table,
                    fieldValues: $fieldValues
                )
                .padding()
                .onAppear {
                    // Сохраняем ссылку на форму для обновления ошибок
                    if formView == nil {
                        formView = DynamicFormView(table: table, fieldValues: $fieldValues)
                    }
                }
            }
        }
        .onAppear {
            initializeFieldValues()
        }
        .onReceive(dataService.$validationErrors) { errors in
            // Обновляем ошибки валидации в форме
            formView?.setValidationErrors(errors)
        }
        .onReceive(dataService.$error) { error in
            if let error = error {
                formView?.setGeneralError(error)
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
        
        // Clear previous validation errors
        dataService.clearValidationErrors()
        formView?.clearValidationErrors()
        
        // Save via DataService
        dataService.createRecord(record)
        
        // Close the page after a short delay to allow for the record to be created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            // Only dismiss if no validation errors
            if dataService.validationErrors.isEmpty {
                onDismiss()
            }
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
        dataService: DataService(),
        onDismiss: {}
    )
}