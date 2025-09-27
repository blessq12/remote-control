import SwiftUI

struct TableDataView: View {
    let table: SchemaTable
    @ObservedObject var dataService: DataService
    @State private var showingAddRecord = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with table info and actions
            TableDataHeader(
                table: table,
                showingAddRecord: $showingAddRecord
            )
            
            Divider()
            
            // Data content
            TableDataContent(
                table: table,
                dataService: dataService
            )
        }
        .sheet(isPresented: $showingAddRecord) {
            AddRecordView(
                schema: Schema(tables: [table]),
                dataService: dataService
            )
        }
    }
}

struct TableDataHeader: View {
    let table: SchemaTable
    @Binding var showingAddRecord: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "table")
                        .foregroundColor(.blue)
                    Text(table.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Text("\(table.fields.count) полей • \(dataCount) записей")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { showingAddRecord = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Добавить запись")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
    
    private var dataCount: Int {
        // This would be passed from parent or observed from dataService
        return 0
    }
}

struct TableDataContent: View {
    let table: SchemaTable
    @ObservedObject var dataService: DataService
    
    var body: some View {
        if dataService.isLoading {
            ProgressView("Загрузка данных...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = dataService.error {
            TableErrorView(error: error)
        } else if dataService.records.isEmpty {
            TableEmptyDataView()
        } else {
            TableDataGrid(table: table, dataService: dataService)
        }
    }
}

struct TableDataGrid: View {
    let table: SchemaTable
    @ObservedObject var dataService: DataService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dataService.records, id: \.id) { record in
                    DataRecordCard(
                        record: record,
                        table: table,
                        dataService: dataService
                    )
                }
            }
            .padding()
        }
    }
}

struct DataRecordCard: View {
    let record: DataRecord
    let table: SchemaTable
    @ObservedObject var dataService: DataService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Record header with ID
            HStack {
                Text("ID: \(record.id.uuidString.prefix(8))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button("Редактировать") {
                        // TODO: Edit record
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    
                    Button("Удалить") {
                        dataService.deleteRecord(record)
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            // Fields grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(table.fields, id: \.id) { field in
                    FieldValueView(
                        field: field,
                        value: record.data[field.name]
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
}

struct FieldValueView: View {
    let field: SchemaField
    let value: AnyCodable?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: fieldIcon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(field.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                if field.required {
                    Text("*")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Text(formattedValue)
                .font(.system(size: 13))
                .foregroundColor(field.readonly ? .secondary : .primary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
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
    
    private var formattedValue: String {
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
                formatter.timeStyle = .none
                return formatter.string(from: dateValue)
            }
            return String(describing: value.value)
        case .datetime:
            if let dateValue = value.value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return formatter.string(from: dateValue)
            }
            return String(describing: value.value)
        case .decimal:
            if let doubleValue = value.value as? Double {
                return String(format: "%.2f", doubleValue)
            }
            return String(describing: value.value)
        case .password:
            return "••••••••"
        case .json:
            return "JSON объект"
        default:
            return String(describing: value.value)
        }
    }
}

struct TableErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 12) {
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

struct TableEmptyDataView: View {
    var body: some View {
        VStack(spacing: 12) {
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

#Preview {
    let sampleTable = SchemaTable(
        name: "companies",
        fields: [
            SchemaField(name: "id", type: .integer, readonly: true),
            SchemaField(name: "name", type: .string, required: true),
            SchemaField(name: "email", type: .email, required: true),
            SchemaField(name: "phone", type: .string),
            SchemaField(name: "created_at", type: .datetime, readonly: true)
        ]
    )
    
    return TableDataView(
        table: sampleTable,
        dataService: DataService()
    )
}
