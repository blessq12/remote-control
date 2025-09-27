import Foundation

struct Schema: Codable {
    let fields: [SchemaField]
    let endpoints: [String: String]
}

struct SchemaField: Codable, Identifiable {
    let id = UUID()
    let name: String
    let type: FieldType
    let isRequired: Bool
    let isEditable: Bool
    
    enum FieldType: String, Codable, CaseIterable {
        case string = "string"
        case integer = "integer"
        case boolean = "boolean"
        case date = "date"
        case email = "email"
        case url = "url"
    }
}

extension SchemaField: Equatable {
    static func == (lhs: SchemaField, rhs: SchemaField) -> Bool {
        lhs.id == rhs.id
    }
}
