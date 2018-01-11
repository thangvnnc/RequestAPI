// *************************************************************************************************
//  Lớp (Class)         | ReqData
//  Dự án (Project)     | RequestAPI
//  Mô tả (Description) | Quản lý thông tin người dùng gửi lên host
//                      |
// -------------------------------------------------------------------------------------------------
//  Copyright (c) 2017. All rights reserved.
// *************************************************************************************************

import Foundation

public class ReqData
{
    // Dữ liệu cần gửi lên host
    internal var _parameters: [String: String] = [String: String]()
    
    // Constructor
    public init(){}
    
    ///
    /// Thêm parameter gửi lên host
    /// - parameter key: Giá trị key của data
    /// - parameter value: Giá trị value của data
    ///
    public func addParam(key: String, value: String)
    {
        _parameters.updateValue(value, forKey: key)
    }
    
    ///
    /// Gỡ bỏ 1 giá trị trong dữ liệu gửi lên server
    /// - parameter key: Giá trị khóa cần gỡ bỏ
    ///
    public func removeParam(key: String)
    {
        _parameters.removeValue(forKey: key)
    }
    
    ///
    /// Tạo dữ liệu trước khi request host
    /// - Returns: Dữ liệu đã được format
    ///
    internal func createParamerters() -> String
    {
        var components = URLComponents()
        components.queryItems = _parameters.map
        {
            URLQueryItem(name: $0, value: $1)
        }

        return components.url!.absoluteString
    }
}
