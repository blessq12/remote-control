import Foundation

struct Schema: Codable, Equatable {
    let tables: [SchemaTable]
}

struct SchemaTable: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let fields: [SchemaField]
    
    init(name: String, fields: [SchemaField]) {
        self.id = UUID()
        self.name = name
        self.fields = fields
    }
    
    // Custom decoder to generate UUID if not provided
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate new UUID for each table
        self.name = try container.decode(String.self, forKey: .name)
        self.fields = try container.decode([SchemaField].self, forKey: .fields)
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, fields
    }
}

struct SchemaField: Codable, Identifiable, Equatable {
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
    
    // Custom decoder to generate UUID if not provided
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate new UUID for each field
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(FieldType.self, forKey: .type)
        self.readonly = try container.decodeIfPresent(Bool.self, forKey: .readonly) ?? false
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, type, readonly
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

