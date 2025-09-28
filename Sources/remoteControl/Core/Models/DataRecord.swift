import Foundation

struct DataRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var data: [String: AnyCodable]
    let createdAt: Date?
    var updatedAt: Date?
    let serverId: String? // Реальный ID с сервера
    
    init(data: [String: AnyCodable]) {
        self.id = UUID()
        self.data = data
        self.createdAt = nil
        self.updatedAt = nil
        self.serverId = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        // Извлекаем реальный ID с сервера
        var actualServerId: String?
        
        if let serverId = try? container.decodeIfPresent(String.self, forKey: DynamicCodingKey(stringValue: "id")) {
            actualServerId = serverId
            // Пытаемся создать UUID из строки сервера
            if let uuid = UUID(uuidString: serverId) {
                self.id = uuid
                print("✅ DataRecord: Using server UUID: \(serverId)")
            } else {
                // Если не UUID, генерируем локальный UUID, но сохраняем серверный ID
                self.id = UUID()
                print("⚠️ DataRecord: Server ID '\(serverId)' is not UUID, using local: \(self.id), server: \(serverId)")
            }
        } else if let serverIdInt = try? container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "id")) {
            // Если ID - число, сохраняем как строку
            actualServerId = String(serverIdInt)
            self.id = UUID()
            print("⚠️ DataRecord: Server ID is integer \(serverIdInt), using local: \(self.id), server: \(actualServerId!)")
        } else {
            // Если нет ID, генерируем новый
            self.id = UUID()
            print("⚠️ DataRecord: No server ID found, generating new: \(self.id)")
        }
        
        self.serverId = actualServerId
        
        // Извлекаем все поля кроме служебных
        var data: [String: AnyCodable] = [:]
        let allKeys = container.allKeys
        
        print("🔍 DataRecord: Decoding record with \(allKeys.count) keys: \(allKeys.map { $0.stringValue })")
        
        for key in allKeys {
            if key.stringValue != "id" && key.stringValue != "created_at" && key.stringValue != "updated_at" {
                if let value = try? container.decode(AnyCodable.self, forKey: key) {
                    data[key.stringValue] = value
                    print("✅ DataRecord: Decoded field '\(key.stringValue)': \(value.value)")
                } else {
                    print("❌ DataRecord: Failed to decode field '\(key.stringValue)'")
                }
            }
        }
        
        self.data = data
        
        // Парсим даты если они есть
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: DynamicCodingKey(stringValue: "created_at"))
        self.updatedAt = try? container.decodeIfPresent(Date.self, forKey: DynamicCodingKey(stringValue: "updated_at"))
        
        print("📊 DataRecord: Final data has \(data.count) fields, ID: \(self.id)")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        // НЕ кодируем ID - сервер сам его назначит при создании
        // ID нужен только для обновления существующих записей
        
        // Кодируем все поля данных напрямую (без обертки data)
        for (key, value) in data {
            // Правильно обрабатываем разные типы данных
            switch value.value {
            case let stringValue as String:
                // Если это JSON строка, пытаемся распарсить
                if key.contains("json") || key.contains("JSON") {
                    if let jsonData = stringValue.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) {
                        try container.encode(AnyCodable(jsonObject), forKey: DynamicCodingKey(stringValue: key))
                    } else {
                        try container.encode(stringValue, forKey: DynamicCodingKey(stringValue: key))
                    }
                } else {
                    try container.encode(stringValue, forKey: DynamicCodingKey(stringValue: key))
                }
            case let arrayValue as [Any]:
                try container.encode(AnyCodable(arrayValue), forKey: DynamicCodingKey(stringValue: key))
            case let dictValue as [String: Any]:
                try container.encode(AnyCodable(dictValue), forKey: DynamicCodingKey(stringValue: key))
            default:
                try container.encode(value, forKey: DynamicCodingKey(stringValue: key))
            }
        }
        
        // Кодируем даты если они есть
        if let createdAt = createdAt {
            try container.encode(createdAt, forKey: DynamicCodingKey(stringValue: "created_at"))
        }
        if let updatedAt = updatedAt {
            try container.encode(updatedAt, forKey: DynamicCodingKey(stringValue: "updated_at"))
        }
    }
    
    // Специальный метод для кодирования с ID (для обновления)
    func encodeWithId(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        // Кодируем ID для обновления (используем реальный ID сервера)
        let recordId = serverId ?? id.uuidString
        try container.encode(recordId, forKey: DynamicCodingKey(stringValue: "id"))
        
        // Кодируем все поля данных напрямую (без обертки data)
        for (key, value) in data {
            // Правильно обрабатываем разные типы данных
            switch value.value {
            case let stringValue as String:
                // Если это JSON строка, пытаемся распарсить
                if key.contains("json") || key.contains("JSON") {
                    if let jsonData = stringValue.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) {
                        try container.encode(AnyCodable(jsonObject), forKey: DynamicCodingKey(stringValue: key))
                    } else {
                        try container.encode(stringValue, forKey: DynamicCodingKey(stringValue: key))
                    }
                } else {
                    try container.encode(stringValue, forKey: DynamicCodingKey(stringValue: key))
                }
            case let arrayValue as [Any]:
                try container.encode(AnyCodable(arrayValue), forKey: DynamicCodingKey(stringValue: key))
            case let dictValue as [String: Any]:
                try container.encode(AnyCodable(dictValue), forKey: DynamicCodingKey(stringValue: key))
            default:
                try container.encode(value, forKey: DynamicCodingKey(stringValue: key))
            }
        }
        
        // Кодируем даты если они есть
        if let createdAt = createdAt {
            try container.encode(createdAt, forKey: DynamicCodingKey(stringValue: "created_at"))
        }
        if let updatedAt = updatedAt {
            try container.encode(updatedAt, forKey: DynamicCodingKey(stringValue: "updated_at"))
        }
    }
    
    // Создаем кодируемую версию с ID
    var encodedWithId: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Структура для кодирования записи с ID
struct DataRecordWithId: Codable {
    let id: String
    let createdAt: Date?
    let updatedAt: Date?
    // Динамические поля будут добавлены через encode(to:)
    
    init(record: DataRecord) {
        self.id = record.serverId ?? record.id.uuidString
        self.createdAt = record.createdAt
        self.updatedAt = record.updatedAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        // Кодируем ID
        try container.encode(id, forKey: DynamicCodingKey(stringValue: "id"))
        
        // Кодируем даты если они есть
        if let createdAt = createdAt {
            try container.encode(createdAt, forKey: DynamicCodingKey(stringValue: "created_at"))
        }
        if let updatedAt = updatedAt {
            try container.encode(updatedAt, forKey: DynamicCodingKey(stringValue: "updated_at"))
        }
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
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
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

// MARK: - Hashable conformance
extension DataRecord {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DataRecord, rhs: DataRecord) -> Bool {
        return lhs.id == rhs.id
    }
}
