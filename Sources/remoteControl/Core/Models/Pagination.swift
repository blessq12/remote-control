import Foundation

struct PaginatedResponse<T: Codable>: Codable {
    let data: T
    let pagination: PaginationInfo
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        print("🔍 PaginatedResponse: Starting to decode")
        
        self.data = try container.decode(T.self, forKey: .data)
        self.pagination = try container.decode(PaginationInfo.self, forKey: .pagination)
        
        print("✅ PaginatedResponse: Successfully decoded data and pagination")
    }
    
    private enum CodingKeys: String, CodingKey {
        case data, pagination
    }
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
    let hasMore: Bool
    
    private enum CodingKeys: String, CodingKey {
        case page, limit, total, pages
        case hasMore = "has_more"
    }
}
