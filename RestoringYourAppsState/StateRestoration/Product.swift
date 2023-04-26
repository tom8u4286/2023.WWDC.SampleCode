/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's main data model describing the product.
*/

import Foundation

struct Product: Hashable, Codable {

    // MARK: - Types

    /// 有關於CodingKey類別的說明，可參考：
    /// https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-enum-codingkeys-客製-json-對應的-property-1b27f29c0c32
    ///
    /// 主要的功能就是將JSON解析出來Key值，對應到這個Struct的變數中。
    /// 但是目前我們的JSON檔的Key值都與變數都相同，因此不需要另外在撰寫如 case name = "nameOfProudct" 等等。
    ///
    /// -Authors: Tomtom Chu
    /// -Date: 2023.4.26
    private enum CoderKeys: String, CodingKey {
        case name
        case imageName
        case year
        case price
        case identifier
    }

    // MARK: - Properties
    
    var name: String
    var imageName: String
    var year: Int
    var price: Double
    var identifier: UUID
        
    // MARK: - Initializers
    
    init(identifier: UUID, name: String, imageName: String, year: Int, price: Double) {
        self.identifier = identifier
        self.name = name
        self.imageName = imageName
        self.year = year
        self.price = price
    }
    
    // MARK: - Data Representation
    
    // Given the endoded JSON representation, return a product instance.
    func decodedProduct(data: Data) -> Product? {
        var product: Product?
        let decoder = JSONDecoder()
        if let decodedProduct = try? decoder.decode(Product.self, from: data) {
            product = decodedProduct
        }
        return product
    }
    
    // MARK: - Codable
    
    // For NSUserActivity scene-based state restoration.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(year, forKey: .year)
        try container.encode(price, forKey: .price)
        try container.encode(identifier, forKey: .identifier)
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        name = try values.decode(String.self, forKey: .name)
        year = try values.decode(Int.self, forKey: .year)
        price = try values.decode(Double.self, forKey: .price)
        imageName = try values.decode(String.self, forKey: .imageName)

        let decodedIdentifier = try values.decode(String.self, forKey: .identifier)
        identifier = UUID(uuidString: decodedIdentifier)!
    }
    
}
