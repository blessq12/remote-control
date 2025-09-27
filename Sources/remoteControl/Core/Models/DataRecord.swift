import Foundation

struct DataRecord: Identifiable, Codable {
    let id: UUID
    var data: [String: AnyCodable]
    let createdAt: Date?
    var updatedAt: Date?
    
    init(data: [String: AnyCodable]) {
        self.id = UUID()
        self.data = data
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        // Генерируем UUID для локального использования
        self.id = UUID()
        
        // Извлекаем все поля кроме служебных
        var data: [String: AnyCodable] = [:]
        let allKeys = container.allKeys
        
        for key in allKeys {
            if key.stringValue != "id" && key.stringValue != "created_at" && key.stringValue != "updated_at" {
                if let value = try? container.decode(AnyCodable.self, forKey: key) {
                    data[key.stringValue] = value
                }
            }
        }
        
        self.data = data
        
        // Парсим даты если они есть
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: DynamicCodingKey(stringValue: "created_at"))
        self.updatedAt = try? container.decodeIfPresent(Date.self, forKey: DynamicCodingKey(stringValue: "updated_at"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        // Кодируем все поля данных
        for (key, value) in data {
            try container.encode(value, forKey: DynamicCodingKey(stringValue: key))
        }
        
        // Кодируем даты если они есть
        if let createdAt = createdAt {
            try container.encode(createdAt, forKey: DynamicCodingKey(stringValue: "created_at"))
        }
        if let updatedAt = updatedAt {
            try container.encode(updatedAt, forKey: DynamicCodingKey(stringValue: "updated_at"))
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Dynamic coding key для работы с произвольными ключами
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// Helper для работы с Any в Codable
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = ()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
