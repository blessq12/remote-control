import Foundation

struct PaginatedResponse<T: Codable>: Codable {
    let data: T
    let pagination: PaginationInfo
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
