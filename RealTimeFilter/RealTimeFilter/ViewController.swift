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
    var captureSession: AVCaptureSession!
    var previewLayer: CALayer!
    var filter: CIFilter!
    lazy var context: CIContext = {
        let eaglContext = EAGLContext(api: .openGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(eaglContext: eaglContext!, options: options)
    }()
    lazy var filterNames: [String] = {
        return ["CIColorInvert", "CIPhotoEffectMono", "CIPhotoEffectInstant", "CIPhotoEffectTransfer"]
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer = CALayer()
        // previewLayer.bounds = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)
        // previewLayer.position = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0)
        // previewLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0)))
        previewLayer.anchorPoint = CGPoint.zero
        previewLayer.bounds = view.bounds
        
        filterButtonsContainer.isHidden = true
        
        self.view.layer.insertSublayer(previewLayer, at: 0)
        
        if TARGET_OS_SIMULATOR != 0 {
            let alert = UIAlertController(title: "提示", message: "不支持模拟器", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        } else {
            setupCaptureSession()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        previewLayer.bounds.size = size
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = .high
		
        let captureDevice = AVCaptureDevice.default(for: .video)
		
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
		if captureSession.canAddInput(deviceInput) {
			captureSession.addInput(deviceInput)
		}
		
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        
        // 为了检测人脸
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            print(metadataOutput.availableMetadataObjectTypes)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
        }
        
        captureSession.commitConfiguration()
    }

    @IBAction func openCamera(sender: UIButton) {
        sender.isEnabled = false
        captureSession.startRunning()
        self.filterButtonsContainer.isHidden = false
    }
    
    @IBAction func applyFilter(sender: UIButton) {
        let filterName = filterNames[sender.tag]
        filter = CIFilter(name: filterName)
    }
    
    @IBAction func takePicture(sender: UIButton) {
        if ciImage == nil || isWriting {
            return
        }
        sender.isEnabled = false
        captureSession.stopRunning()

        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        ALAssetsLibrary().writeImage(toSavedPhotosAlbum: cgImage, metadata: ciImage.properties) { (url, error) in
            if error == nil {
                print("保存成功")
                print(url!)
            } else {
                let alert = UIAlertController(title: "错误", message: error?.localizedDescription, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            }
            self.captureSession.startRunning()
            sender.isEnabled = true
        }
    }
    
    // MARK: - Video Records
    @IBAction func record() {
        if isWriting {
            self.isWriting = false
            assetWriterPixelBufferInput = nil
            recordsButton.isEnabled = false
            assetWriter?.finishWriting(completionHandler: {[unowned self] () -> Void in
                print("录制完成")
                self.recordsButton.setTitle("处理中...", for: .normal)
                self.saveMovieToCameraRoll()
            })
        } else {
            createWriter()
            recordsButton.setTitle("停止录制...", for: .normal)
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: currentSampleTime!)
            isWriting = true
        }
    }
    
    func saveMovieToCameraRoll() {
        ALAssetsLibrary().writeVideoAtPath(toSavedPhotosAlbum: movieURL() as URL!) { (url, error) in
            if let errorDescription = error?.localizedDescription {
                print("写入视频错误：\(errorDescription)")
            } else {
                self.checkForAndDeleteFile()
                print("写入视频成功")
            }
            
            DispatchQueue.main.async {
                self.recordsButton.isEnabled = true
                self.recordsButton.setTitle("开始录制", for: .normal)
            }
        }
    }
    
    func movieURL() -> NSURL {
        let tempDir = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: tempDir).appendingPathComponent("tmpMov.mov")
        return url! as NSURL
    }
    
    func checkForAndDeleteFile() {
        let fm = FileManager.default
        let url = movieURL()
        let exist = fm.fileExists(atPath: url.path!)
		
        if exist {
			print("删除之前的临时文件")
			do {
                try fm.removeItem(at: url as URL)
			} catch let error as NSError {
				print(error.localizedDescription)
			}
        }
    }
    
    func createWriter() {
        self.checkForAndDeleteFile()
		
		do {
            assetWriter = try AVAssetWriter(outputURL: movieURL() as URL, fileType: AVFileType.mov)
		} catch let error as NSError {
			print("创建writer失败")
			print(error.localizedDescription)
			return
		}

        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : Int(currentVideoDimensions!.width),
            AVVideoHeightKey : Int(currentVideoDimensions!.height)
            ] as [String : Any]
		
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
		
		let sourcePixelBufferAttributesDictionary = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
            String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height),
            String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
        ] as [String : Any]
		
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if assetWriter!.canAdd(assetWriterVideoInput) {
            assetWriter!.add(assetWriterVideoInput)
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

        let radialGradientOutputImage = radialGradient.outputImage!.cropped(to: inputImage.extent)
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
            var outputImage = CIImage(cvImageBuffer: imageBuffer)
            
            if self.filter != nil {
                self.filter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = self.filter.outputImage!
            }
            if self.faceObject != nil {
                outputImage = self.makeFaceWithCIImage(inputImage: outputImage, faceObject: self.faceObject!)
            }
            
            // 录制视频的处理
            if self.isWriting {
                if self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true {
                    var newPixelBuffer: CVPixelBuffer? = nil
					
                    CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)
                    
                    self.context.render(outputImage, to: newPixelBuffer!, bounds: outputImage.extent, colorSpace: nil)
                    
                    let success = self.assetWriterPixelBufferInput?.append(newPixelBuffer!, withPresentationTime: self.currentSampleTime!)
                    
                    if success == false {
                        print("Pixel Buffer没有附加成功")
                    }
                }
            }
            
            let orientation = UIDevice.current.orientation
            var t: CGAffineTransform!
            if orientation == UIDeviceOrientation.portrait {
                t = CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0)
            } else if orientation == UIDeviceOrientation.portraitUpsideDown {
                t = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
            } else if (orientation == UIDeviceOrientation.landscapeRight) {
                t = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                t = CGAffineTransform(rotationAngle: 0)
            }
            outputImage = outputImage.transformed(by: t)
            
            let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent)
            self.ciImage = outputImage
            
            DispatchQueue.main.async {
                self.previewLayer.contents = cgImage
            }
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
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
        }
    }
}

