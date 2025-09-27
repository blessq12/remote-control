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
    let required: Bool
    
    init(name: String, type: FieldType, readonly: Bool = false, required: Bool = false) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.readonly = readonly
        self.required = required
    }
    
    // Custom decoder to generate UUID if not provided
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate new UUID for each field
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(FieldType.self, forKey: .type)
        self.readonly = try container.decodeIfPresent(Bool.self, forKey: .readonly) ?? false
        self.required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, type, readonly, required
    }
    
    enum FieldType: String, Codable, CaseIterable {
        case string = "string"
        case integer = "integer"
        case boolean = "boolean"
        case date = "date"
        case email = "email"
        case url = "url"
        case text = "text"
        case password = "password"
        case decimal = "decimal"
        case datetime = "datetime"
        case json = "json"
    }
    
    // Computed properties for backward compatibility
    var isRequired: Bool {
        return required
    }
    
    var isEditable: Bool {
        return !readonly
    }
}

