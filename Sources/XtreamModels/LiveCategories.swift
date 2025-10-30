import Foundation

public struct XtreamLiveCategory: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let parentID: Int?

    public init(id: String, name: String, parentID: Int?) {
        self.id = id
        self.name = name
        self.parentID = parentID
    }
}

public struct XtreamLiveCategoryResponse: Sendable, Decodable {
    public let categoryID: String
    public let categoryName: String
    public let parentID: String?

    private enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case categoryName = "category_name"
        case parentID = "parent_id"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.categoryID = try container.decode(String.self, forKey: .categoryID)
        self.categoryName = try container.decode(String.self, forKey: .categoryName)

        if let stringValue = try? container.decode(String.self, forKey: .parentID) {
            self.parentID = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .parentID) {
            self.parentID = String(intValue)
        } else {
            self.parentID = nil
        }
    }
}

public extension XtreamLiveCategory {
    init(from response: XtreamLiveCategoryResponse) {
        self.init(
            id: response.categoryID,
            name: response.categoryName,
            parentID: Int(response.parentID ?? "")
        )
    }
}
