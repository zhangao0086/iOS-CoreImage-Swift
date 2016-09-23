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

class ViewController: UIViewController , AVCaptureVideoDataOutputSampleBufferDelegate , AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet var filterButtonsContainer: UIView!
    @IBOutlet var switchCameraButton:UIButton!
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
    
    // 标记人脸
    // var faceLayer: CALayer?
    var faceObject: AVMetadataFaceObject?
    
    // Video Records
    @IBOutlet var recordsButton: UIButton!
    var assetWriter: AVAssetWriter?
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var isWriting = false
    var currentSampleTime: CMTime?
    var currentVideoDimensions: CMVideoDimensions?
    var currentDeviceInput:AVCaptureDeviceInput?
    var currentDevice:AVCaptureDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer = CALayer()
        // previewLayer.bounds = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
        // previewLayer.position = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
        // previewLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0)));
        previewLayer.anchorPoint = CGPointZero
        previewLayer.bounds = view.bounds
        
        filterButtonsContainer.hidden = true
        switchCameraButton.hidden = true   //两个摄像头可用的时候可以切换摄像头
        
        self.view.layer.insertSublayer(previewLayer, atIndex: 0)
        
        if TARGET_IPHONE_SIMULATOR == 1 {
            UIAlertView(title: "提示", message: "不支持模拟器", delegate: nil, cancelButtonTitle: "确定").show()
        } else {
            setupCaptureSession()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        previewLayer.bounds.size = size
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
		
		
        let captureDevices  = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        guard let captureDevice = captureDevices.first as? AVCaptureDevice else{
            assert(false, "没可用的摄像头")
            return
        }
        
        currentDevice  = captureDevice
        
		let deviceInput = try! AVCaptureDeviceInput(device: captureDevice)
        currentDeviceInput = deviceInput
        
		if captureSession.canAddInput(deviceInput) {
			captureSession.addInput(deviceInput)
		}
		
        let dataOutput = AVCaptureVideoDataOutput()
		dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        let queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL)
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
        // 为了检测人脸
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            print(metadataOutput.availableMetadataObjectTypes)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        }
        
        captureSession.commitConfiguration()
    }
    
    func captureDevice(postion:AVCaptureDevicePosition = .Front,anyDevice:Bool = true) -> AVCaptureDevice{
        let captureDevices  = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        var device = captureDevices.first as? AVCaptureDevice
        
        if anyDevice {
            return device!
        }
        for  device_ in captureDevices {
            if device_.position == postion{
                device = device_ as? AVCaptureDevice
                break
            }
        }
        return device!;
    }
    
    // MARK: 点击切换按钮切换镜头
    @IBAction func clickSwitchCameraButton(sender:UIButton){
        if let  deviceInput =  currentDeviceInput{
            let animation = CATransition.init()
            animation.duration = 0.25
            animation.subtype = kCATruncationMiddle
            animation.type =  kCATransitionFade
            captureSession.removeInput(deviceInput)
            switch currentDevice!.position {
            case .Back:
                currentDevice =  captureDevice(.Front,anyDevice: false)
            case .Front:
                currentDevice =  captureDevice(.Back,anyDevice: false)
            case .Unspecified:
                break
            }
            currentDeviceInput =  try! AVCaptureDeviceInput.init(device: currentDevice)
            captureSession.addInput(currentDeviceInput)
            self.view.layer .addAnimation(animation, forKey: nil)
            faceObject = nil
        }else{
            currentDevice =  captureDevice()
            currentDeviceInput =  try! AVCaptureDeviceInput.init(device: currentDevice)
            captureSession.addInput(currentDeviceInput)
        }
    }
    
    @IBAction func openCamera(sender: UIButton) {
        sender.enabled = false
        captureSession.startRunning()
        self.filterButtonsContainer.hidden = false
        let captureDevices  = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        switchCameraButton.hidden = captureDevices.count < 1
        
    }
    
    @IBAction func applyFilter(sender: UIButton) {
        let filterName = filterNames[sender.tag]
        filter = CIFilter(name: filterName)
    }
    
    @IBAction func takePicture(sender: UIButton) {
        if ciImage == nil || isWriting {
            return
        }
        sender.enabled = false
        captureSession.stopRunning()

        let cgImage = context.createCGImage(ciImage, fromRect: ciImage.extent)
        ALAssetsLibrary().writeImageToSavedPhotosAlbum(cgImage, metadata: ciImage.properties)
            {(url: NSURL!, error :NSError!) -> Void in
                if error == nil {
                    print("保存成功")
                    print(url)
                } else {
                    let alert = UIAlertView(title: "错误", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "确定")
                    alert.show()
                }
                self.captureSession.startRunning()
                sender.enabled = true
        }
    }
    
    // MARK: - Video Records
    @IBAction func record() {
        if isWriting {
            self.isWriting = false
            assetWriterPixelBufferInput = nil
            recordsButton.enabled = false
            assetWriter?.finishWritingWithCompletionHandler({[unowned self] () -> Void in
                print("录制完成")
                self.recordsButton.setTitle("处理中...", forState: UIControlState.Normal)
                self.saveMovieToCameraRoll()
            })
        } else {
            createWriter()
            recordsButton.setTitle("停止录制...", forState: UIControlState.Normal)
            assetWriter?.startWriting()
            assetWriter?.startSessionAtSourceTime(currentSampleTime!)
            isWriting = true
        }
    }
    
    func saveMovieToCameraRoll() {
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(movieURL(), completionBlock: { (url: NSURL!, error: NSError?) -> Void in
            if let errorDescription = error?.localizedDescription {
                print("写入视频错误：\(errorDescription)")
            } else {
                self.checkForAndDeleteFile()
                print("写入视频成功")
            }
            self.recordsButton.enabled = true
            self.recordsButton.setTitle("开始录制", forState: UIControlState.Normal)
        })
    }
    
    func movieURL() -> NSURL {
        let tempDir = NSTemporaryDirectory()
		let url = NSURL(fileURLWithPath: tempDir).URLByAppendingPathComponent("tmpMov.mov")
        return url
    }
    
    func checkForAndDeleteFile() {
        let fm = NSFileManager.defaultManager()
        let url = movieURL()
        let exist = fm.fileExistsAtPath(url.path!)
		
        if exist {
			print("删除之前的临时文件")
			do {
				try fm.removeItemAtURL(url)
			} catch let error as NSError {
				print(error.localizedDescription)
			}
        }
    }
    
    func createWriter() {
        self.checkForAndDeleteFile()
		
		do {
			assetWriter = try AVAssetWriter(URL: movieURL(), fileType: AVFileTypeQuickTimeMovie)
		} catch let error as NSError {
			print("创建writer失败")
			print(error.localizedDescription)
			return
		}

        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : Int(currentVideoDimensions!.width),
            AVVideoHeightKey : Int(currentVideoDimensions!.height)
        ]
		
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings as? [String : AnyObject])
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0))
		
		let sourcePixelBufferAttributesDictionary = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
            String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height),
            String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
		]
		
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if assetWriter!.canAddInput(assetWriterVideoInput) {
            assetWriter!.addInput(assetWriterVideoInput)
        } else {
            print("不能添加视频writer的input \(assetWriterVideoInput)")
        }
    }
    
    func makeFaceWithCIImage(inputImage: CIImage, faceObject: AVMetadataFaceObject) -> CIImage {
        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        // 1.
        filter.setValue(max(inputImage.extent.size.width, inputImage.extent.size.height) / 60, forKey: kCIInputScaleKey)
        
        let fullPixellatedImage = filter.outputImage

        var maskImage: CIImage!
        let faceBounds = faceObject.bounds
        
        // 2.
        let centerX = inputImage.extent.size.width * (faceBounds.origin.x + faceBounds.size.width / 2)
        let centerY = inputImage.extent.size.height * (1 - faceBounds.origin.y - faceBounds.size.height / 2)
        let radius = faceBounds.size.width * inputImage.extent.size.width / 2
        let radialGradient = CIFilter(name: "CIRadialGradient",
            withInputParameters: [
                "inputRadius0" : radius,
                "inputRadius1" : radius + 1,
                "inputColor0" : CIColor(red: 0, green: 1, blue: 0, alpha: 1),
                "inputColor1" : CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                kCIInputCenterKey : CIVector(x: centerX, y: centerY)
            ])!

        let radialGradientOutputImage = radialGradient.outputImage!.imageByCroppingToRect(inputImage.extent)
        if maskImage == nil {
            maskImage = radialGradientOutputImage
        } else {
            print(radialGradientOutputImage)
            maskImage = CIFilter(name: "CISourceOverCompositing",
                withInputParameters: [
                    kCIInputImageKey : radialGradientOutputImage,
                    kCIInputBackgroundImageKey : maskImage
                ])!.outputImage
        }
        
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(fullPixellatedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage!
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(captureOutput: AVCaptureOutput!,didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,fromConnection connection: AVCaptureConnection!) {
        autoreleasepool {
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
            self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            
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
            
            if self.filter != nil {
                self.filter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = self.filter.outputImage!
            }
            if self.faceObject != nil {
                outputImage = self.makeFaceWithCIImage(outputImage, faceObject: self.faceObject!)
            }
            
            // 录制视频的处理
            if self.isWriting {
                if self.assetWriterPixelBufferInput?.assetWriterInput.readyForMoreMediaData == true {
                    var newPixelBuffer: CVPixelBuffer? = nil
					
                    CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)
                    
                    self.context.render(outputImage, toCVPixelBuffer: newPixelBuffer!, bounds: outputImage.extent, colorSpace: nil)
                    
                    let success = self.assetWriterPixelBufferInput?.appendPixelBuffer(newPixelBuffer!, withPresentationTime: self.currentSampleTime!)
                    
                    if success == false {
                        print("Pixel Buffer没有附加成功")
                    }
                }
            }
            
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
            
            let cgImage = self.context.createCGImage(outputImage, fromRect: outputImage.extent)
            self.ciImage = outputImage
            
            dispatch_sync(dispatch_get_main_queue(), {
                self.previewLayer.contents = cgImage
            })
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        // print(metadataObjects)
        if metadataObjects.count > 0 {
            //识别到的第一张脸
            faceObject = metadataObjects.first as? AVMetadataFaceObject
            
            /*
            if faceLayer == nil {
                faceLayer = CALayer()
                faceLayer?.borderColor = UIColor.redColor().CGColor
                faceLayer?.borderWidth = 1
                view.layer.addSublayer(faceLayer)
            }
            let faceBounds = faceObject.bounds
            let viewSize = view.bounds.size
    
            faceLayer?.position = CGPoint(x: viewSize.width * (1 - faceBounds.origin.y - faceBounds.size.height / 2),
                                          y: viewSize.height * (faceBounds.origin.x + faceBounds.size.width / 2))
            
            faceLayer?.bounds.size = CGSize(width: faceBounds.size.height * viewSize.width,
                                            height: faceBounds.size.width * viewSize.height)
            print(faceBounds.origin)
            print("###")
            print(faceLayer!.position)
            print("###")
            print(faceLayer!.bounds)
            */
        }else{
            faceObject = nil
        }
    }
}

