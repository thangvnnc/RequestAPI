// *************************************************************************************************
//  Lớp (Class)         | ReqDefine
//  Dự án (Project)     | RequestAPI
//  Mô tả (Description) | Lưu thông tin kết nối host
//                      |
// -------------------------------------------------------------------------------------------------
//  Copyright (c) 2017. All rights reserved.
// *************************************************************************************************

import Foundation

///
/// Khai báo kết nối host
///
public class ReqDefine
{
    // Thời gian timeout mặc định là 30s
    public var timeout: TimeInterval = 30
    
    // Mặc định phương thức request là GET
    public var method: ReqMethod     = ReqMethod.get
    
    // Mặc định đường dẫn là nil
    public var url: String          = "127.0.0.1"

    public init()
    {}
    
    ///
    /// Constructor
    /// - parameter url: Đường dẫn gửi lên host
    ///
    public init(url: String)
    {
        self.url        = url
    }
}
