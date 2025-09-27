import SwiftUI

struct DataTableView: View {
    @ObservedObject var dataService: DataService
    @ObservedObject var schemaService: SchemaService
    @State private var showingAddRecord = false
    @State private var selectedTable: SchemaTable?
    
    var body: some View {
        VStack(spacing: 0) {
            DataTableHeader(
                showingAddRecord: $showingAddRecord, 
                schemaService: schemaService,
                selectedTable: $selectedTable
            )
            
            Divider()
            
            DataTableContent(
                dataService: dataService, 
                schemaService: schemaService,
                showingAddRecord: $showingAddRecord,
                selectedTable: selectedTable
            )
        }
        .sheet(isPresented: $showingAddRecord) {
            if let schema = schemaService.currentSchema {
                AddRecordView(schema: schema, dataService: dataService)
            }
        }
        .onAppear {
            // Auto-select first table if available
            if selectedTable == nil, let firstTable = schemaService.currentSchema?.tables.first {
                selectedTable = firstTable
            }
        }
        .onChange(of: schemaService.currentSchema) { schema in
            // Reset selection when schema changes
            selectedTable = schema?.tables.first
        }
    }
}

struct DataTableHeader: View {
    @Binding var showingAddRecord: Bool
    @ObservedObject var schemaService: SchemaService
    @Binding var selectedTable: SchemaTable?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Данные")
                    .font(.headline)
                
                if let table = selectedTable {
                    Text("Таблица: \(table.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Table selector
            if let schema = schemaService.currentSchema, schema.tables.count > 1 {
                Menu {
                    ForEach(schema.tables, id: \.id) { table in
                        Button(action: {
                            selectedTable = table
                        }) {
                            HStack {
                                Text(table.name)
                                if selectedTable?.id == table.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "table")
                        Text(selectedTable?.name ?? "Выберите таблицу")
                        Image(systemName: "chevron.down")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            Button(action: { showingAddRecord = true }) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
            .disabled(schemaService.currentSchema == nil)
        }
        .padding()
    }
}

struct DataTableContent: View {
    @ObservedObject var dataService: DataService
    @ObservedObject var schemaService: SchemaService
    @Binding var showingAddRecord: Bool
    let selectedTable: SchemaTable?
    
    var body: some View {
        if dataService.isLoading {
            ProgressView("Загрузка данных...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = dataService.error {
            ErrorView(error: error)
        } else if dataService.records.isEmpty {
            EmptyDataView()
        } else if selectedTable != nil {
            DataTable(dataService: dataService, schemaService: schemaService, selectedTable: selectedTable!)
        } else {
            Text("Выберите таблицу для просмотра данных")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ErrorView: View {
    let error: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Ошибка загрузки")
                .font(.headline)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyDataView: View {
    var body: some View {
        VStack {
            Image(systemName: "table")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Нет данных")
                .font(.headline)
            Text("Добавьте первую запись")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DataTable: View {
    @ObservedObject var dataService: DataService
    @ObservedObject var schemaService: SchemaService
    let selectedTable: SchemaTable
    
    var body: some View {
        List(dataService.records) { record in
            DataRowView(
                record: record, 
                schemaService: schemaService, 
                dataService: dataService,
                table: selectedTable
            )
        }
    }
}

struct DataRowView: View {
    let record: DataRecord
    @ObservedObject var schemaService: SchemaService
    @ObservedObject var dataService: DataService
    let table: SchemaTable
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(table.fields, id: \.id) { field in
                HStack {
                    Text(field.name + ":")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatFieldValue(record.data[field.name], for: field))
                        .font(.system(size: 12))
                        .foregroundColor(field.readonly ? .secondary : .primary)
                }
            }
            
            HStack {
                Spacer()
                Button("Редактировать") {
                    // TODO: Редактирование записи
                }
                .buttonStyle(.borderless)
                
                Button("Удалить") {
                    dataService.deleteRecord(record)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatFieldValue(_ value: AnyCodable?, for field: SchemaField) -> String {
        guard let value = value else { return "—" }
        
        switch field.type {
        case .boolean:
            if let boolValue = value.value as? Bool {
                return boolValue ? "Да" : "Нет"
            }
            return String(describing: value.value)
        case .date:
            if let dateValue = value.value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: dateValue)
            }
            return String(describing: value.value)
        default:
            return String(describing: value.value)
        }
    }
}
