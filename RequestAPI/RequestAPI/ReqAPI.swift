// *************************************************************************************************
//  Lớp (Class)         | ReqAPI
//  Dự án (Project)     | RequestAPI
//  Mô tả (Description) | Quản lý kế nối, lấy dữ liệu, đọc ghi file
//                      |
// -------------------------------------------------------------------------------------------------
//  Copyright (c) 2017. All rights reserved.
// *************************************************************************************************

import Foundation

//  - MARK: ReqAPI

public class ReqAPI: NSObject
{
    public typealias CompletionHandler = (_ error: URLError?, _ urlResponse: URLResponse?, _ resData: String?) -> Void

    public override init() {}
    
    ///
    /// Singleton class
    ///
    public static var intance: ReqAPI
    {
        let instance = ReqAPI()
        return instance
    }
    
    ///
    /// Gửi request lên host
    /// - parameter reqDefine: Thông tin kết nối host
    /// - parameter reqData: Dữ liệu cần gửi lên host (Không bao gồm gửi file)
    /// - parameter completionHandler: Handler thông báo trả về từ host
    ///
    public func request(
        reqDefine: ReqDefine,
        reqData: ReqData,
        completionHandler: @escaping CompletionHandler
        )
    {
        var urlString: String       =   reqDefine.url
        var url: URL                =   URL(string: reqDefine.url)!
        var request: URLRequest!    =   nil
        
        // Kiểm tra là method: post
        if (reqDefine.method == ReqMethod.post)
        {
            // Tạo request post thêm param vào body request
            request                 =   URLRequest(url: url)
            var postString          =   reqData.createParamerters()
            postString.remove(at: postString.startIndex)
            request.httpBody        =   postString.data(using: .utf8)
        }
        else
        {
            // Tạo request get thêm param vào đường dẫn url
            urlString               +=  "\(reqData.createParamerters())"
            url                     =   URL(string: urlString)!
            request                 =   URLRequest(url: url)
        }
        
        // Set method cho request
        request.httpMethod          =   reqDefine.method.rawValue
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = reqDefine.timeout
        let session: URLSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request, completionHandler:
            {
                data, response, error in
                guard let data = data, error == nil else
                {
                    let urlError: URLError = error as! URLError
                    completionHandler(urlError, nil, nil)
                    return
                }
                let responseString = String(data: data, encoding: .utf8)
                guard let httpStatus: HTTPURLResponse = response as? HTTPURLResponse else
                {
                    completionHandler(nil, nil, responseString)
                    
                    return
                }
                completionHandler(nil, httpStatus, responseString)
            }
        )
        task.resume()
    }
}

//  - MARK: URLSessionDelegate

extension ReqAPI: URLSessionDelegate
{
    ///
    /// Xác nhận chứng chỉ ssl thực hiện request https
    ///
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?)-> Void)
    {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
        {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
        }
    }
}
