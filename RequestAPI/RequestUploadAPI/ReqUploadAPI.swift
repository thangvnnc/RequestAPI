// *************************************************************************************************
//  Lớp (Class)         | ReqUploadAPI
//  Dự án (Project)     | RequestAPI
//  Mô tả (Description) | Class hổ trợ upload file
//                      |
// -------------------------------------------------------------------------------------------------
//  Copyright (c) 2017. All rights reserved.
// *************************************************************************************************

import Foundation

// - MARK: Protocol process upload file
public protocol ReqUploadAPIDelegate
{
    ///
    /// Delegate trả về thông tin file upload
    /// - parameter totalBytes: Số byte đã gửi
    /// - parameter totalBytesExpectedToSend: Tổng số cần gửi
    ///
    func didProcessSendData (totalBytes: Int64, totalBytesExpectedToSend: Int64)
    
    ///
    /// Delegate kết thúc gửi file
    /// - parameter error: Khác nil có lổi
    /// - parameter data: Dữ liệu nhận về từ server
    ///
    func didCompleteSendData (_ error: Error?, _ urlResponse: URLResponse?, _ data: Data?)
}

// - MARK: ReqUploadAPI

public class ReqUploadAPI: NSObject
{
    // Delegate trả về progressUpload
    public var delegate: ReqUploadAPIDelegate?
    
    // Biến lưu giá trị trả về
    private var _responseData: NSMutableData = NSMutableData()
    
    // Biến lưu thông tin trạng thái response
    private var _urlResponse: URLResponse? = nil
    
    public override init() {}
    
    ///
    /// Gửi request lên host
    /// - parameter reqDefine: Thông tin kết nối host
    /// - parameter pathFile: Đường dẫn file upload
    /// - parameter completionHandler: Handler thông báo trả về từ host
    ///
    public func request(
        reqDefine: ReqDefine,
        urlFile: URL
        )
    {
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
            delegate?.didCompleteSendData(error, nil, nil)
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

extension ReqUploadAPI: URLSessionDelegate
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

extension ReqUploadAPI: URLSessionTaskDelegate
{
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if error != nil
        {
            delegate?.didCompleteSendData(error, nil, nil)
        }
        else
        {
            delegate?.didCompleteSendData(nil, _urlResponse, _responseData as Data)
            
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
        delegate?.didProcessSendData(totalBytes: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
}

// - MARK: URLSessionDataDelegate

extension ReqUploadAPI: URLSessionDataDelegate
{
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        // Lưu trạng thái trả về của host
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
        // Lưu dữ liệu gửi về từ host
        _responseData.append(data)
    }
}
