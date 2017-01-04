//
//  VideoViewController.swift
//  YFCameraDemo
//
//  Created by wangfeng on 16/12/6.
//  Copyright © 2016年 abc. All rights reserved.
//

import UIKit
import AVFoundation

class VideoViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var captureInput : AVCaptureInput?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var pickUIImager : UIImageView = UIImageView()
    var switchButton : UIButton = UIButton()
    var closeButton : UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        let bundlePath = Bundle.main.path(forResource: "facefinder", ofType: nil)
        
        let file = readFile(filename: bundlePath!);
        initParams(file)
        
        // 前置摄像头和后置摄像头像素不一样，可以单独设置
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        if (cameraWithPosition(position: .front) != nil) {
            beginSession()
        }
        
        pickUIImager.frame = self.view.bounds
        pickUIImager.contentMode = .center
        pickUIImager.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.view.addSubview(pickUIImager)
        
        switchButton.frame = CGRect(x:20, y:50, width:50, height:30)
        switchButton.setBackgroundImage(UIImage(named: "phone"), for: UIControlState.normal)
        switchButton.layer.cornerRadius = 5
        switchButton.clipsToBounds = true
        switchButton.addTarget(self, action: #selector(swapFrontAndBackCameras), for: .touchUpInside)
        self.view.addSubview(switchButton)
        
        let x = UIScreen.main.bounds.width - 60
        closeButton.frame = CGRect(x: x, y:50, width:50, height:30)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.setTitleColor(UIColor.blue, for: .normal)
        closeButton.addTarget(self, action: #selector(closeView), for: .touchUpInside)
        self.view.addSubview(closeButton)
    }
    
    func readFile(filename: String) -> UnsafeMutablePointer<CUnsignedChar>? {
        
        let fp = fopen(filename.cString(using: String.Encoding.utf8), "r")
        if fp == nil {
            print("Open File fail!")
            return nil
        }
        fseek(fp, 0, SEEK_END)
        let length = ftell(fp)
        fseek(fp, 0, SEEK_SET)
        let buffer = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: length)
        fread(buffer, MemoryLayout<CUnsignedChar>.size, length, fp)
        fclose(fp)
        
        return buffer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        captureSession.stopRunning()
    }
    
    func beginSession() {
        do {
            self.captureInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(self.captureInput)
        } catch _ {
            //
        }
        let output = AVCaptureVideoDataOutput()
        
        let cameraQueue = DispatchQueue(label: "cameraQueue")
        output.setSampleBufferDelegate(self, queue: cameraQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable:NSNumber(value: kCVPixelFormatType_32BGRA)]
        captureSession.addOutput(output)
        
//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer?.videoGravity = "AVLayerVideoGravityResizeAspect"
//        previewLayer?.frame = self.view.bounds
//        self.view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }

    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        let resultImage = sampleBufferToImage(sampleBuffer: sampleBuffer)
        var resultImage2 = UIImage.convert(toIplImage: resultImage)
            
        process_image(resultImage2, 1)
        
        DispatchQueue.main.async {
            self.pickUIImager.image = UIImage.convert(toUIImage: resultImage2)
            cvReleaseImage(&resultImage2)
        }
    }
    private func sampleBufferToImage(sampleBuffer: CMSampleBuffer!) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        
        
        let newContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerCompornent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)! as CGContext
        
        let imageRef: CGImage = newContext.makeImage()!
        let resultImage = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        return resultImage
    }
    
    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices()
        for device in devices! {
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                if ((device as AnyObject).position == position) {
                    captureDevice = device as?AVCaptureDevice
                    if captureDevice != nil {
                        return captureDevice
                    }
                }
            }
        }
        return nil
    }
    
    func swapFrontAndBackCameras() {
        if (self.captureDevice?.position == .front) {
            self.captureDevice = self.cameraWithPosition(position: .back)
            UIView.animate(withDuration: 0.2) {
                self.pickUIImager.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        } else {
            self.captureDevice = self.cameraWithPosition(position: .front)
            UIView.animate(withDuration: 0.2) {
                self.pickUIImager.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            }
        }
        do {
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(self.captureInput)
            self.captureInput = try AVCaptureDeviceInput(device: self.captureDevice)
            if (self.captureSession.canAddInput(self.captureInput)) {
                self.captureSession.addInput(self.captureInput)
            } else {
                // 
            }
            self.captureSession.commitConfiguration()
        } catch _ {
            //
        }
    }

    func closeView() {
        self .dismiss(animated: true, completion: nil)
    }
}

