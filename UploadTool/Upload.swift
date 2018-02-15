//
//  Upload.swift
//  UploadTool
//
//  Created by 姜万宝 on 13/02/2018.
//  Copyright © 2018 姜万宝. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

//let boundaryStr = "--"
//let boundaryID = "aws-file-upload"

func uploadFileToAWS(urlString: String, name: String, fileName: String, mimeType: String, parameters: [String: String], fileData: Data, sucess:@escaping (NSData?)-> Void, failure:@escaping (NSData?)->Void){

    let request:NSMutableURLRequest = NSMutableURLRequest()
    request.url = NSURL(string: urlString)! as URL
    request.httpMethod = "POST"
    request.timeoutInterval = 10
    let body:NSMutableData = NSMutableData()
    //设置表单分隔符
    let boundary:NSString = "----------------------1465789351321346"
    let contentType = "multipart/form-data;boundary=\(boundary)"
    request.addValue(contentType, forHTTPHeaderField: "Content-Type")
     //写入Info内容
    for(key, value) in parameters {
        body.append(NSString(format: "--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key).data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format:"%@\r\n", value).data(using: String.Encoding.utf8.rawValue)!)
    }
    
     //写入图片内容
//    let ImgPath = NSHomeDirectory()+(carData.value(forKey: "key") as! String)
    let ImgPath = fileName
     print(ImgPath)
    body.append(NSString(format: "--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
    body.append(NSString(format: "Content-Disposition:form-data;name=\"%@\";filename=\"\(ImgPath)\"\r\n" as NSString, "file").data(using: String.Encoding.utf8.rawValue)!)
    body.append("Content-Type:image/jpeg\r\n\r\n".data(using: String.Encoding.utf8)!)
    body.append(fileData)
    body.append("\r\n".data(using: String.Encoding.utf8)!)
    
    //写入尾部
    body.append(NSString(format: "--%@--\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
    request.httpBody = body as Data

    print(request)
    
//    let session=URLSession.shared
//    session.dataTask(with: request as URLRequest) { (responseData, response, error) -> Void in
//        if error==nil{
//            sucess(responseData as NSData?)
//        }
//        else{
//            failure(error as? NSData)
//        }
//    }.resume()
    
    let session = URLSession.shared
    session.dataTask(with: request as URLRequest, completionHandler: {(responseData, response, error) in
        if responseData != nil {
            sucess(responseData as NSData?)
        }else if error != nil {
            failure(error as? NSData)
        }else if response != nil {
            print(response ?? "response completed")
        }
    }).resume()
    
//    let que=OperationQueue()
//    NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: que, completionHandler: {
//
//        (response, data, error) ->Void in
//
//        if (error != nil){
//
//            print(error ?? "")
//
//        }else{
//
//            //Handle data in NSData type
//
//            let tr:String=NSString(data:data!,encoding:String.Encoding.utf8.rawValue)! as String
//
//            print(tr)
//        }
//
//    })
    
}


func uploadFileToS3(urlString: String, name: String, fileName: String, mimeType: String, parameters: [String: String], fileData: Data, sucess:@escaping (NSData?)-> Void, failure:@escaping (NSData?)->Void){

    if urlString.isEmpty{
        print ("主地址不能为空")
        return
    }
    
    let boundary = "Boundary-\(UUID().uuidString)"
    //固定拼接的第一部分
    let top=NSMutableString()
    top.appendFormat("%@%@\r\n", "--",UUID().uuidString)
    top.appendFormat("Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name,fileName)
    top.appendFormat("Content-Type: %s\r\n\r\n", mimeType)
    
    //固定拼接第三部分
    let buttom=NSMutableString()
    for(key, value) in parameters {
        buttom.appendFormat("%@%@\r\n", "--",UUID().uuidString)
        buttom.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
        buttom.append("\(value)\r\n")
        buttom.appendFormat("%@%@--\r\n", "--",UUID().uuidString)
    }
    
    let form = NSMutableString()
    let boundaryPrefix = "--\(boundary)\r\n"
    for(key, value) in parameters {
        form.append(boundaryPrefix)
        form.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
        form.append("\(value)\r\n")
        form.appendFormat("%@%@boundary--\r\n", "--",UUID().uuidString)
    }
    //拼接
    let fromData=NSMutableData()
    //非文件参数
//    if (parameters != nil){
//        fromData.append((paramters.data(using: String.Encoding.utf8))!)
//    }
    fromData.append(form.data(using: String.Encoding.utf8.rawValue)!)
    fromData.append(fileData as Data)
    fromData.append(top.data(using: String.Encoding.utf8.rawValue)!)
    fromData.append(buttom.data(using: String.Encoding.utf8.rawValue)!)
    
    //可变请求
//    let bodyData: Data = createBody(parameters: paramters, boundary: boundary, data: fileData, mimeType: mimeType, filename: fileName)
    
    let request=NSMutableURLRequest(url: NSURL(string: urlString)! as URL)
    request.httpBody=fromData as Data
    request.httpMethod="POST"
    request.addValue(String(fromData.length), forHTTPHeaderField:"Content-Length")
//    let contype=String(format: "multipart/form-data; boundary=%s", boundary)
    let contype = "multipart/form-data; boundary=\(boundary)"
    request.setValue(contype, forHTTPHeaderField: "Content-Type")
    
    let session=URLSession.shared
    session.uploadTask(with: request as URLRequest, from: nil) { (responseData, response, error) -> Void in
        if error==nil{
            sucess(responseData as NSData?)
        }
        else{
            failure(error as? NSData)
        }
        }.resume()
}

func createBody(parameters: [String: String], boundary: String, data: Data, mimeType: String, filename: String)->Data {
    let body = NSMutableData()
    let boundaryPrefix = "--\(boundary)\r\n"
    let form = NSMutableString()
    for(key, value) in parameters {
        form.append(boundaryPrefix)
        form.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
        form.append("\(value)\r\n")
    }
    body.append(form.data(using: String.Encoding.utf8.rawValue)!)
    
    let part2 = NSMutableString()
    part2.append("Boundary-\(UUID().uuidString)")
    part2.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
    part2.append("Content-Type: \(mimeType)\r\n\r\n")
    body.append(part2.data(using: String.Encoding.utf8.rawValue)!)
    
    body.append(data)
    
    let part3 = NSMutableString()
    part3.append("\r\n")
    part3.append("--".appending(boundary.appending("--")))
    body.append(part3.data(using: String.Encoding.utf8.rawValue)!)
    print(body)
    return body as Data
}

func uploadFile(urlString: String, name: String, fileName: String, mimeType: String, parameters: [String: String], fileData: Data, sucess:@escaping (NSData?)-> Void, failure:@escaping (NSData?)->Void){
    
    Alamofire.upload(multipartFormData: { (multipartFormData) in
        multipartFormData.append(fileData, withName: fileName, fileName: fileName, mimeType: mimeType)
        for (key, value) in parameters {
            multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
        }
    }, to:urlString)
    { (result) in
        switch result {
        case .success(let upload, _, _):
            
            upload.uploadProgress(closure: { (Progress) in
                print("Upload Progress: \(Progress.fractionCompleted)")
            })
            
            upload.responseJSON { response in
                //self.delegate?.showSuccessAlert()
                print(response.request ?? "")  // original URL request
                print(response.response ?? "") // URL response
                print(response.data ?? "")     // server data
                print(response.result)   // result of response serialization
                //                        self.showSuccesAlert()
                //self.removeImage("frame", fileExtension: "txt")
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
            }
            
        case .failure(let encodingError):
            //self.delegate?.showFailAlert()
            print(encodingError)
        }
        
    }
    
}
