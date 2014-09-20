//
//  ViewController.swift
//  RealTimeFilter
//
//  Created by ZhangAo on 14-9-20.
//  Copyright (c) 2014年 ZhangAo. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController , AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet var filterButtonsContainer: UIView!
    var captureSession: AVCaptureSession!
    var previewLayer: CALayer!
//    var filter: CIFilter!
//    lazy var context: CIContext = {
//        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
//        let options = [kCIContextWorkingColorSpace : NSNull()]
//        return CIContext(EAGLContext: eaglContext, options: options)
//    }()
//    lazy var filterNames: [String] = {
//        return ["CIColorInvert","CIPhotoEffectMono","CIPhotoEffectInstant","CIPhotoEffectTransfer"]
//    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer = CALayer()
        previewLayer.bounds = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
        previewLayer.position = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
        previewLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0)));
        
        //ignored
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
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let deviceInput = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: nil) as AVCaptureDeviceInput
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        let queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL)
        dataOutput.setSampleBufferDelegate(self, queue: queue)
    }

    @IBAction func openCamera(sender: UIButton) {
        sender.enabled = false
        captureSession.startRunning()
//        self.filterButtonsContainer.hidden = false
    }
    
    @IBAction func applyFilter(sender: UIButton) {
//        var filterName = filterNames[sender.tag]
//        filter = CIFilter(name: filterName)
    }
    
    //MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(captureOutput: AVCaptureOutput!,
                        didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                        fromConnection connection: AVCaptureConnection!) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        let width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let grayColorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace, CGBitmapInfo.allZeros)
        let cgImage = CGBitmapContextCreateImage(context)
        
        
//        var outputImage = CIImage(CVPixelBuffer: imageBuffer)
        
//        if filter != nil {
//            filter.setValue(outputImage, forKey: kCIInputImageKey)
//            outputImage = filter.outputImage
//        }
//        
//        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        
        dispatch_sync(dispatch_get_main_queue(), {
            self.previewLayer.contents = cgImage
        })
    }
}

