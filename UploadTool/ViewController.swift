//
//  ViewController.swift
//  UploadTool
//
//  Created by 姜万宝 on 13/02/2018.
//  Copyright © 2018 姜万宝. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
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
            uploadFileToAWS(urlString: uploadURL, name: "file", fileName: imageName, mimeType: "image/jpg", parameters: ["key":"\(imageName)"], fileData: imageData!, sucess: {(responseData)-> Void in
                let result = String(data: responseData! as Data, encoding: String.Encoding.utf8)
                print(result ?? "")
            }, failure: { (error) -> Void in

            })
//            uploadFile(urlString: uploadURL, name: "file", fileName: filePath, mimeType: "multipart/form-data", parameters: ["key":"\(timeStamp)"], fileData: imageData!, sucess: {(responseData)-> Void in
//                let result = String(data: responseData! as Data, encoding: String.Encoding.utf8)
//                print(result ?? "")
//            }, failure: { (error) -> Void in
//
//            })
        }
        
        picker.dismiss(animated: true, completion: nil)
    }

}

