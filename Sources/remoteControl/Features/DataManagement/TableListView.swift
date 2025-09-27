import SwiftUI

struct TableListView: View {
    let tables: [SchemaTable]
    let onViewSchema: (SchemaTable) -> Void
    let onViewData: (SchemaTable) -> Void
    let onAddRecord: (SchemaTable) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 350, maximum: 400), spacing: 24)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(tables, id: \.id) { table in
                    TableCardView(
                        table: table,
                        onViewSchema: { onViewSchema(table) },
                        onViewData: { onViewData(table) },
                        onAddRecord: { onAddRecord(table) }
                    )
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 24)
        }
    }
}

struct TableCardView: View {
    let table: SchemaTable
    let onViewSchema: () -> Void
    let onViewData: () -> Void
    let onAddRecord: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "table")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(table.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("\(table.fields.count) полей")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 8) {
                // Schema button
                Button(action: onViewSchema) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.subheadline)
                        Text("Просмотр схемы")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                // Data and Add buttons
                HStack(spacing: 10) {
                    Button(action: onViewData) {
                        HStack(spacing: 6) {
                            Image(systemName: "eye")
                                .font(.subheadline)
                            Text("Данные")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onAddRecord) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.subheadline)
                            Text("Добавить")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
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
        onViewSchema: { _ in },
        onViewData: { _ in },
        onAddRecord: { _ in }
    )
    .padding()
}
