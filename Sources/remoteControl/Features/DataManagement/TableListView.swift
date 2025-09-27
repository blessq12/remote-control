import SwiftUI

struct TableListView: View {
    let tables: [SchemaTable]
    let onViewData: (SchemaTable) -> Void
    let onAddRecord: (SchemaTable) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(tables, id: \.id) { table in
                    TableCardView(
                        table: table,
                        onViewData: { onViewData(table) },
                        onAddRecord: { onAddRecord(table) }
                    )
                }
            }
            .padding()
        }
    }
}

struct TableCardView: View {
    let table: SchemaTable
    let onViewData: () -> Void
    let onAddRecord: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "table")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(table.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(table.fields.count) полей")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Fields preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Поля:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(table.fields.prefix(6), id: \.id) { field in
                        FieldChipView(field: field)
                    }
                    
                    if table.fields.count > 6 {
                        Text("+\(table.fields.count - 6) еще")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Divider()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onViewData) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .font(.caption)
                        Text("Данные")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: onAddRecord) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Добавить")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct FieldChipView: View {
    let field: SchemaField
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: fieldIcon)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(field.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            if field.required {
                Text("*")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if field.readonly {
                Image(systemName: "lock")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
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
}

#Preview {
    let sampleTables = [
        SchemaTable(
            name: "companies",
            fields: [
                SchemaField(name: "id", type: .integer, readonly: true),
                SchemaField(name: "name", type: .string, required: true),
                SchemaField(name: "email", type: .email, required: true),
                SchemaField(name: "phone", type: .string),
                SchemaField(name: "created_at", type: .datetime, readonly: true)
            ]
        ),
        SchemaTable(
            name: "users",
            fields: [
                SchemaField(name: "id", type: .integer, readonly: true),
                SchemaField(name: "username", type: .string, required: true),
                SchemaField(name: "email", type: .email, required: true),
                SchemaField(name: "password", type: .password, required: true),
                SchemaField(name: "active", type: .boolean),
                SchemaField(name: "created_at", type: .datetime, readonly: true),
                SchemaField(name: "updated_at", type: .datetime, readonly: true)
            ]
        )
    ]
    
    return TableListView(
        tables: sampleTables,
        onViewData: { _ in },
        onAddRecord: { _ in }
    )
    .padding()
}
