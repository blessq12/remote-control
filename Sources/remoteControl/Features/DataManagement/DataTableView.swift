import SwiftUI

struct DataTableView: View {
    @ObservedObject var dataService: DataService
    @ObservedObject var schemaService: SchemaService
    @State private var showingAddRecord = false
    
    var body: some View {
        VStack(spacing: 0) {
            DataTableHeader(showingAddRecord: $showingAddRecord, schemaService: schemaService)
            
            Divider()
            
            DataTableContent(
                dataService: dataService, 
                schemaService: schemaService,
                showingAddRecord: $showingAddRecord
            )
        }
        .sheet(isPresented: $showingAddRecord) {
            if let schema = schemaService.currentSchema {
                AddRecordView(schema: schema, dataService: dataService)
            }
        }
    }
}

struct DataTableHeader: View {
    @Binding var showingAddRecord: Bool
    @ObservedObject var schemaService: SchemaService
    
    var body: some View {
        HStack {
            Text("Данные")
                .font(.headline)
            Spacer()
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
    
    var body: some View {
        if dataService.isLoading {
            ProgressView("Загрузка данных...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = dataService.error {
            ErrorView(error: error)
        } else if dataService.records.isEmpty {
            EmptyDataView()
        } else {
            DataTable(dataService: dataService, schemaService: schemaService)
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
    
    var body: some View {
        List(dataService.records) { record in
            DataRowView(record: record, schemaService: schemaService, dataService: dataService)
        }
    }
}

struct DataRowView: View {
    let record: DataRecord
    @ObservedObject var schemaService: SchemaService
    @ObservedObject var dataService: DataService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(schemaService.currentSchema?.tables.first?.fields ?? [], id: \.id) { field in
                HStack {
                    Text(field.name + ":")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(describing: record.data[field.name]?.value ?? ""))
                        .font(.system(size: 12))
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
}
