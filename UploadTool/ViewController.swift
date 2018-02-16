//
//  ViewController.swift
//  UploadTool
//
//  Created by 姜万宝 on 13/02/2018.
//  Copyright © 2018 姜万宝. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    @IBOutlet weak var selectedImageView: UIImageView!
    
    @IBOutlet weak var uploadProgressView: UIProgressView!
    
    @IBOutlet weak var uploadProgressLabel: UILabel!
    
    @IBOutlet weak var uploadButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.uploadProgressView.progress = 0
        self.uploadProgressLabel.text = "0%"
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func fromAlbum(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: {()-> Void in})
        }else{
            print("读取相册错误")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.uploadButton.isEnabled = false
        self.uploadProgressView.progress = 0
        self.uploadProgressLabel.text = "0%"
        let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        selectedImageView.image = pickedImage
        selectedImageView.backgroundColor = UIColor.clear
        self.dismiss(animated: true, completion: nil)
        let imageNSURL = info[UIImagePickerControllerImageURL] as! NSURL
        print(imageNSURL.lastPathComponent ?? "")
        let imageName:String = imageNSURL.lastPathComponent!
        let fileManager = FileManager.default
        let rootPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let filePath = "\(rootPath)/pickedImage.jpg"
        let imageData = UIImageJPEGRepresentation(pickedImage, 1.0)
        fileManager.createFile(atPath: filePath, contents: imageData, attributes: nil)
        if(fileManager.fileExists(atPath: filePath)){
            let imageURL = URL(fileURLWithPath: filePath)
            print(imageURL)
//            let uploadURL:String = "http://ec2-52-87-151-146.compute-1.amazonaws.com:8080/s3/upload"
//            let uploadURL:String = "http://52.87.151.146:8080/s3/upload"
            let uploadURL: String = "http://127.0.0.1:8080/multipart/upload"
//            let uploadURL: String = "http://192.168.0.101:8080/multipart/upload"
            
//            uploadFileToAWS(urlString: uploadURL, name: "file", fileName: imageName, mimeType: "image/jpg", parameters: ["key":"\(imageName)"], fileData: imageData!, sucess: {(responseData)-> Void in
//                let result = String(data: responseData! as Data, encoding: String.Encoding.utf8)
//                print(result ?? "")
//            }, failure: { (error) -> Void in
//            })
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = uploadFileToAWS(viewController: self, session: session, urlString: uploadURL, name: "file", fileName: imageName, mimeType: "image/jpg", parameters: ["key":"\(imageName)"], fileData: imageData!)
            task.resume()
        }
        
        picker.dismiss(animated: true, completion: nil)
    }

    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64){
    
        let uploadProgress: Float = Float(totalBytesSent)/Float(totalBytesExpectedToSend)
        self.uploadProgressView.progress = uploadProgress
        let uploadPercent = Int(uploadProgress * 100)
        self.uploadProgressLabel.text = "\(uploadPercent)%"
        if uploadPercent == 100 {
            self.uploadButton.isEnabled = true
        }
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
//        let alertView = UIAlertView(title: "Alert", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
//        alertView.show()
        let alertView = UIAlertController(title: "Alert", message: error as? String, preferredStyle: .alert)
        alertView.loadView()
        self.uploadButton.isEnabled = true
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void){
        
        self.uploadButton.isEnabled = true
    }
}

