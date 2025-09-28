import Foundation

// MARK: - Server Validation Error Models

struct ServerValidationError: Codable {
    let message: String
    let errors: [String: [String]]?
    let fieldErrors: [FieldValidationError]?
    
    enum CodingKeys: String, CodingKey {
        case message
        case errors
        case fieldErrors = "field_errors"
    }
}

struct FieldValidationError: Codable {
    let field: String
    let message: String
    let code: String?
    
    enum CodingKeys: String, CodingKey {
        case field
        case message
        case code
    }
}

// MARK: - Validation Error Response

struct ValidationErrorResponse: Codable {
    let error: ServerValidationError
    let status: Int?
    let timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case status
        case timestamp
    }
}

// MARK: - Error Display Helpers

extension ServerValidationError {
    /// Форматированное сообщение для отображения пользователю
    var displayMessage: String {
        var messages: [String] = []
        
        // Основное сообщение
        if !message.isEmpty {
            messages.append(message)
        }
        
        // Ошибки полей
        if let fieldErrors = fieldErrors {
            for fieldError in fieldErrors {
                messages.append("\(fieldError.field): \(fieldError.message)")
            }
        }
        
        // Общие ошибки
        if let errors = errors {
            for (field, fieldMessages) in errors {
                for fieldMessage in fieldMessages {
                    messages.append("\(field): \(fieldMessage)")
                }
            }
        }
        
        return messages.joined(separator: "\n")
    }
    
    /// Проверяет, есть ли ошибки для конкретного поля
    func hasError(for field: String) -> Bool {
        if let fieldErrors = fieldErrors {
            return fieldErrors.contains { $0.field == field }
        }
        
        if let errors = errors {
            return errors[field] != nil
        }
        
        return false
    }
    
    /// Получает сообщение об ошибке для конкретного поля
    func errorMessage(for field: String) -> String? {
        // Сначала проверяем fieldErrors
        if let fieldErrors = fieldErrors {
            if let fieldError = fieldErrors.first(where: { $0.field == field }) {
                return fieldError.message
            }
        }
        
        // Затем проверяем общие ошибки
        if let errors = errors {
            return errors[field]?.first
        }
        
        return nil
    }
}
