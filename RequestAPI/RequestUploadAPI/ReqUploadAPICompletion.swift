// *************************************************************************************************
//  Lớp (Class)         | ReqUploadAPICompletion
//  Dự án (Project)     | ReqUploadAPICompletion
//  Mô tả (Description) | Class hổ trợ upload file
//                      |
// -------------------------------------------------------------------------------------------------
//  Copyright (c) 2017. All rights reserved.
// *************************************************************************************************

import Foundation

// - MARK: ReqUploadAPI

public class ReqUploadAPICompletion: NSObject
{
    public typealias CompletionHandler = (_ error: Error?, _ urlResponse: URLResponse?, _ resData: Data?) -> Void
    
    public typealias CompletionHandlerProcess = (_ totalBytes: Int64, _ totalBytesExpectedToSend: Int64) -> Void
    
    private var _completionHandlerProcess: CompletionHandlerProcess?
    private var _completionHandler: CompletionHandler?

    // Biến lưu giá trị trả về
    private var _responseData: NSMutableData = NSMutableData()
    
    // Biến lưu thông tin trạng thái response
    private var _urlResponse: URLResponse? = nil
    
    public override init() {}
    
    ///
    /// Singleton class
    ///
    public static var intance: ReqUploadAPICompletion
    {
        let instance = ReqUploadAPICompletion()
        return instance
    }
    
    ///
    /// Gửi request lên host
    /// - parameter reqDefine: Thông tin kết nối host
    /// - parameter pathFile: Đường dẫn file upload
    /// - parameter completionHandler: Handler thông báo trả về từ host
    ///
    public func request(
        reqDefine: ReqDefine,
        urlFile: URL,
        completionHandlerProcess: CompletionHandlerProcess?,
        completionHandler: CompletionHandler?
        )
    {
        self._completionHandlerProcess = completionHandlerProcess
        self._completionHandler = completionHandler

        do
        {
            let data: Data = try Data(contentsOf: urlFile)
            var request: URLRequest = URLRequest(url: URL(string: reqDefine.url)!)
            request.httpMethod = reqDefine.method.rawValue
            let boundary = generateBoundaryString()
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.setValue(urlFile.lastPathComponent, forHTTPHeaderField: "file")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            uploadFiles(reqDefine: reqDefine, request: request, data: data)
        }
        catch (let error)
        {
            self._completionHandler?(error, nil, nil)
        }
    }
    
    ///
    /// Hàm tạo key cho file khi upload
    /// - returns: Giá trị của key file tự phát sinh
    ///
    private func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    ///
    /// Hàm bắt đầu thực hiện gửi file
    /// - parameter request: Thông tin host cần gửi
    /// - parameter data: dữ liệu file
    ///
    private func uploadFiles(reqDefine: ReqDefine, request: URLRequest, data: Data)
    {
        let sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = reqDefine.timeout
        let session: URLSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
        
        let task: URLSessionUploadTask = session.uploadTask(with: request, from: data)
        
        task.resume()
    }
}

// - MARK: URLSessionDelegate

extension ReqUploadAPICompletion: URLSessionDelegate
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

// - MARK: URLSessionTaskDelegate

extension ReqUploadAPICompletion: URLSessionTaskDelegate
{
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if error != nil
        {
            self._completionHandler?(error, nil, nil)
        }
        else
        {
            self._completionHandler?(nil, _urlResponse, _responseData as Data)
            
            // Reset response status
            _urlResponse = nil
       
            // Reset data response
            _responseData.setData(Data())
        }
    }
    
    ///
    /// Delegate nhận giá trị thông số upload
    /// - parameter session: Phiên upload
    /// - parameter task: task upload
    /// - parameter totalBytesSent: Số byte đã gửi
    /// - parameter totalBytesExpectedToSend: tổng số byte cần gửi
    ///
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64)
    {
        self._completionHandlerProcess?(totalBytesSent, totalBytesExpectedToSend)
    }
}

// - MARK: URLSessionDataDelegate

extension ReqUploadAPICompletion: URLSessionDataDelegate
{
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        _urlResponse = response
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    ///
    /// Delegate nhận dữ liệu gửi về từ host
    /// - parameter session: Phiên làm việc của host
    /// - parameter dataTask: Task đang hoạt động
    /// - parameter data: Dữ liệu host gửi về
    ///
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        _responseData.append(data)
    }
}
