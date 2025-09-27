import SwiftUI

struct TableDataView: View {
    let table: SchemaTable
    @ObservedObject var dataService: DataService
    @State private var showingAddRecord = false
    @State private var showingEditRecord = false
    @State private var recordToEdit: DataRecord?
    
    var body: some View {
        Group {
            if showingAddRecord {
                print("🔘 TableDataView: Showing AddRecordView")
                return AnyView(AddRecordView(
                    table: table,
                    dataService: dataService,
                    onDismiss: {
                        showingAddRecord = false
                    }
                ))
            } else if showingEditRecord, let recordToEdit = recordToEdit {
                print("🔘 TableDataView: Showing EditRecordView")
                return AnyView(
                    EditRecordView(
                        record: recordToEdit,
                        table: table,
                        dataService: dataService,
                        onDismiss: {
                            showingEditRecord = false
                        }
                    )
                )
            } else {
                print("🔘 TableDataView: Showing main view")
                return AnyView(
                    VStack(spacing: 0) {
                        // Header with table info and actions
                        TableDataHeader(
                            table: table,
                            dataService: dataService,
                            onAddRecord: {
                                print("🔘 TableDataView: Add record button pressed")
                                showingAddRecord = true
                            }
                        )
                        
                        Divider()
                        
                        // Data content
                        TableDataContent(
                            table: table,
                            dataService: dataService,
                            onEditRecord: { record in
                                print("🔘 TableDataView: Edit record button pressed for record: \(record.id)")
                                recordToEdit = record
                                showingEditRecord = true
                            }
                        )
                    }
                )
            }
        }
    }
}

struct TableDataHeader: View {
    let table: SchemaTable
    @ObservedObject var dataService: DataService
    let onAddRecord: () -> Void
    
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
                
                HStack(spacing: 8) {
                    Text("\(table.fields.count) полей • \(dataService.records.count) записей")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let pagination = dataService.pagination {
                        Text("• Страница \(pagination.page) из \(pagination.pages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Pagination controls
                if let pagination = dataService.pagination, pagination.pages > 1 {
                    HStack(spacing: 8) {
                        Button(action: {
                            if pagination.page > 1 {
                                dataService.fetchRecords(for: table, page: pagination.page - 1)
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(pagination.page <= 1)
                        
                        Text("\(pagination.page)/\(pagination.pages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            if pagination.hasMore {
                                dataService.fetchRecords(for: table, page: pagination.page + 1)
                            }
                        }) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(!pagination.hasMore)
                    }
                    .buttonStyle(.plain)
                }
                
                       Button(action: onAddRecord) {
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
}

struct TableDataContent: View {
    let table: SchemaTable
    @ObservedObject var dataService: DataService
    let onEditRecord: (DataRecord) -> Void
    
    var body: some View {
        if dataService.isLoading {
            ProgressView("Загрузка данных...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = dataService.error {
            TableErrorView(error: error)
        } else if dataService.records.isEmpty {
            TableEmptyDataView()
        } else {
                TableDataGrid(table: table, dataService: dataService, onEditRecord: onEditRecord)
        }
    }
}

struct TableDataGrid: View {
    let table: SchemaTable
    @ObservedObject var dataService: DataService
    let onEditRecord: (DataRecord) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dataService.records, id: \.id) { record in
                    DataRecordCard(
                        record: record,
                        table: table,
                        dataService: dataService,
                        onEdit: {
                            onEditRecord(record)
                        }
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
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Record header
            HStack {
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button("Редактировать") {
                        onEdit()
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
            
            // Fields list
            VStack(alignment: .leading, spacing: 8) {
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
        HStack(alignment: .top, spacing: 12) {
            // Field info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: fieldIcon)
                        .font(.caption2)
                        .foregroundColor(fieldTypeColor)
                        .frame(width: 12)
                    
                    Text(field.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if field.required {
                        Text("*")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if field.readonly {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(field.type.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, alignment: .leading)
            
            // Value
            Text(formattedValue)
                .font(.subheadline)
                .foregroundColor(field.readonly ? .secondary : .primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
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
    
    private var fieldTypeColor: Color {
        switch field.type {
        case .string, .text, .url, .email, .password: return .blue
        case .integer, .decimal: return .green
        case .boolean: return .purple
        case .date, .datetime: return .orange
        case .json: return .red
        }
    }
    
    private var formattedValue: String {
        guard let value = value else { return "—" }
        
        switch field.type {
        case .boolean:
            if let boolValue = value.value as? Bool {
                return boolValue ? "Да" : "Нет"
            } else if let intValue = value.value as? Int {
                return intValue == 1 ? "Да" : "Нет"
            }
            return String(describing: value.value)
        case .date:
            if let dateValue = value.value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return formatter.string(from: dateValue)
            } else if let stringValue = value.value as? String {
                // Try to parse ISO date string
                if let date = ISO8601DateFormatter().date(from: stringValue) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    return formatter.string(from: date)
                }
                return stringValue
            }
            return String(describing: value.value)
        case .datetime:
            if let dateValue = value.value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return formatter.string(from: dateValue)
            } else if let stringValue = value.value as? String {
                // Try to parse ISO datetime string
                if let date = ISO8601DateFormatter().date(from: stringValue) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    return formatter.string(from: date)
                }
                return stringValue
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
