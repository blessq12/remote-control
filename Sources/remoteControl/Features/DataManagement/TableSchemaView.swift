import SwiftUI

struct TableSchemaView: View {
    let table: SchemaTable
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Table header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "table")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(table.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("\(table.fields.count) полей")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Fields list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Поля таблицы")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(table.fields, id: \.id) { field in
                            SchemaFieldRow(field: field)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct SchemaFieldRow: View {
    let field: SchemaField
    
    var body: some View {
        HStack(spacing: 12) {
            // Field type icon
            Image(systemName: fieldIcon)
                .font(.title3)
                .foregroundColor(fieldColor)
                .frame(width: 24)
            
            // Field info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(field.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if field.required {
                        Text("*")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    if field.readonly {
                        Image(systemName: "lock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
                
                Text(fieldTypeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Field type badge
            Text(field.type.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(fieldColor.opacity(0.1))
                .foregroundColor(fieldColor)
                .cornerRadius(6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
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
    
    private var fieldColor: Color {
        switch field.type {
        case .string, .text: return .blue
        case .integer, .decimal: return .green
        case .boolean: return .orange
        case .date, .datetime: return .purple
        case .email: return .cyan
        case .url: return .indigo
        case .password: return .red
        case .json: return .brown
        }
    }
    
    private var fieldTypeDescription: String {
        switch field.type {
        case .string: return "Текстовое поле"
        case .text: return "Многострочный текст"
        case .integer: return "Целое число"
        case .decimal: return "Десятичное число"
        case .boolean: return "Логическое значение (да/нет)"
        case .date: return "Дата"
        case .datetime: return "Дата и время"
        case .email: return "Email адрес"
        case .url: return "URL ссылка"
        case .password: return "Пароль"
        case .json: return "JSON объект"
        }
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
            SchemaField(name: "description", type: .text),
            SchemaField(name: "active", type: .boolean),
            SchemaField(name: "created_at", type: .datetime, readonly: true)
        ]
    )
    
    return TableSchemaView(table: sampleTable)
    .padding()
}
