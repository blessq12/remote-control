import Foundation

struct Schema: Codable {
    let tables: [SchemaTable]
}

struct SchemaTable: Codable, Identifiable {
    let id: UUID
    let name: String
    let fields: [SchemaField]
    
    init(name: String, fields: [SchemaField]) {
        self.id = UUID()
        self.name = name
        self.fields = fields
    }
}

struct SchemaField: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: FieldType
    let readonly: Bool
    
    init(name: String, type: FieldType, readonly: Bool) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.readonly = readonly
    }
    
    enum FieldType: String, Codable, CaseIterable {
        case string = "string"
        case integer = "integer"
        case boolean = "boolean"
        case date = "date"
        case email = "email"
        case url = "url"
    }
    
    // Computed properties for backward compatibility
    var isRequired: Bool {
        return false // Based on the new structure, we don't have required field info
    }
    
    var isEditable: Bool {
        return !readonly
    }
}

extension SchemaTable: Equatable {
    static func == (lhs: SchemaTable, rhs: SchemaTable) -> Bool {
        lhs.id == rhs.id
    }
}

extension SchemaField: Equatable {
    static func == (lhs: SchemaField, rhs: SchemaField) -> Bool {
        lhs.id == rhs.id
    }
}
