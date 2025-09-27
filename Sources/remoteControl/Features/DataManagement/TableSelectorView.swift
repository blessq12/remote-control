import SwiftUI

struct TableSelectorView: View {
    let tables: [SchemaTable]
    @Binding var selectedTable: SchemaTable?
    let onTableSelected: (SchemaTable) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Выберите таблицу")
                .font(.headline)
                .padding(.horizontal)
            
            if tables.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "table")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Нет доступных таблиц")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Загрузите схему данных для продолжения")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(tables, id: \.id) { table in
                    TableRowView(
                        table: table,
                        isSelected: selectedTable?.id == table.id
                    ) {
                        selectedTable = table
                        onTableSelected(table)
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TableRowView: View {
    let table: SchemaTable
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Table icon
                Image(systemName: "table")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                // Table info
                VStack(alignment: .leading, spacing: 4) {
                    Text(table.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(table.fields.count) полей")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let sampleTables = [
        SchemaTable(
            name: "companies",
            fields: [
                SchemaField(name: "id", type: .integer, readonly: true),
                SchemaField(name: "name", type: .string, readonly: false),
                SchemaField(name: "email", type: .email, readonly: false)
            ]
        ),
        SchemaTable(
            name: "users",
            fields: [
                SchemaField(name: "id", type: .integer, readonly: true),
                SchemaField(name: "username", type: .string, readonly: false),
                SchemaField(name: "active", type: .boolean, readonly: false)
            ]
        )
    ]
    
    return TableSelectorView(
        tables: sampleTables,
        selectedTable: .constant(sampleTables.first)
    ) { _ in }
    .padding()
}
