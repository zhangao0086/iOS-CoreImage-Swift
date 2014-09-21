//
//  ViewController.swift
//  RealTimeFilter
//
//  Created by ZhangAo on 14-9-20.
//  Copyright (c) 2014年 ZhangAo. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

class ViewController: UIViewController , AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet var filterButtonsContainer: UIView!
    var captureSession: AVCaptureSession!
    var previewLayer: CALayer!
    var filter: CIFilter!
    lazy var context: CIContext = {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(EAGLContext: eaglContext, options: options)
    }()
    lazy var filterNames: [String] = {
        return ["CIColorInvert","CIPhotoEffectMono","CIPhotoEffectInstant","CIPhotoEffectTransfer"]
    }()
    var ciImage: CIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer = CALayer()
        // previewLayer.bounds = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
        // previewLayer.position = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
        // previewLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0)));
        previewLayer.anchorPoint = CGPointZero
        previewLayer.bounds = view.bounds
        
        filterButtonsContainer.hidden = true
        
        self.view.layer.insertSublayer(previewLayer, atIndex: 0)
        
        setupCaptureSession()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let deviceInput = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: nil) as AVCaptureDeviceInput
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        let queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL)
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
        captureSession.commitConfiguration()
    }

    @IBAction func openCamera(sender: UIButton) {
        sender.enabled = false
        captureSession.startRunning()
        self.filterButtonsContainer.hidden = false
    }
    
    @IBAction func applyFilter(sender: UIButton) {
        var filterName = filterNames[sender.tag]
        filter = CIFilter(name: filterName)
    }
    
    @IBAction func takePicture(sender: UIButton) {
        sender.enabled = false
        captureSession.stopRunning()

        var cgImage = context.createCGImage(ciImage, fromRect: ciImage.extent())
        ALAssetsLibrary().writeImageToSavedPhotosAlbum(cgImage, metadata: ciImage.properties())
            { (url: NSURL!, error :NSError!) -> Void in
                if error == nil {
                    println("保存成功")
                    println(url)
                } else {
                    let alert = UIAlertView(title: "错误", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "确定")
                    alert.show()
                }
                self.captureSession.startRunning()
                sender.enabled = true
        }
    }
    
    //MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(captureOutput: AVCaptureOutput!,
                        didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                        fromConnection connection: AVCaptureConnection!) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

        // CVPixelBufferLockBaseAddress(imageBuffer, 0)
        // let width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        // let height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        // let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        // let lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        //
        // let grayColorSpace = CGColorSpaceCreateDeviceGray()
        // let context = CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace, CGBitmapInfo.allZeros)
        // let cgImage = CGBitmapContextCreateImage(context)
        
        var outputImage = CIImage(CVPixelBuffer: imageBuffer)
                            
        let orientation = UIDevice.currentDevice().orientation
        var t: CGAffineTransform!
        if orientation == UIDeviceOrientation.Portrait {
            t = CGAffineTransformMakeRotation(CGFloat(-M_PI / 2.0))
        } else if orientation == UIDeviceOrientation.PortraitUpsideDown {
            t = CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0))
        } else if (orientation == UIDeviceOrientation.LandscapeRight) {
            t = CGAffineTransformMakeRotation(CGFloat(M_PI))
        } else {
            t = CGAffineTransformMakeRotation(0)
        }
        outputImage = outputImage.imageByApplyingTransform(t)
        
        if filter != nil {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            outputImage = filter.outputImage
        }
        
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        ciImage = outputImage

        dispatch_sync(dispatch_get_main_queue(), {
            self.previewLayer.contents = cgImage
        })
    }
}

