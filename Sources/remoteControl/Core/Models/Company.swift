import Foundation

struct Company: Identifiable, Codable {
    let id = UUID()
    var name: String
    var url: String
    var secret: String
    var isActive: Bool = false
    
    init(name: String, url: String, secret: String = "") {
        self.name = name
        self.url = url
        self.secret = secret
    }
}

extension Company: Equatable {
    static func == (lhs: Company, rhs: Company) -> Bool {
        lhs.id == rhs.id
    }
}
