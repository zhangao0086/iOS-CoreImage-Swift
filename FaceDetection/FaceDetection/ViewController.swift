//
//  ViewController.swift
//  FaceDetection
//
//  Created by ZhangAo on 14-9-13.
//  Copyright (c) 2014年 zhangao. All rights reserved.
//

import UIKit
import ImageIO

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    lazy var originalImage: UIImage = {
        return UIImage(named: "Image")!
    }()
    lazy var context: CIContext = {
        return CIContext(options: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.imageView.image = originalImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // 人脸检测
    @IBAction func faceDetecing() {
        let inputImage = CIImage(image: originalImage)!
        let detector = CIDetector(ofType: CIDetectorTypeFace,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        var faceFeatures: [CIFaceFeature]!
        if let orientation = inputImage.properties[kCGImagePropertyOrientation as String] {
            faceFeatures = detector?.features(in: inputImage, options: [CIDetectorImageOrientation: orientation]) as! [CIFaceFeature]
        } else {
            faceFeatures = detector?.features(in: inputImage)as! [CIFaceFeature]
        }
        
        print(faceFeatures)
        
        // 1.
        let inputImageSize = inputImage.extent.size
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -inputImageSize.height)

        for faceFeature in faceFeatures {
            var faceViewBounds = faceFeature.bounds.applying(transform)
            
            // 2.
            let scale = min(imageView.bounds.size.width / inputImageSize.width,
                imageView.bounds.size.height / inputImageSize.height)
            let offsetX = (imageView.bounds.size.width - inputImageSize.width * scale) / 2
            let offsetY = (imageView.bounds.size.height - inputImageSize.height * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            let faceView = UIView(frame: faceViewBounds)
            faceView.layer.borderColor = UIColor.orange.cgColor
            faceView.layer.borderWidth = 2
            
            imageView.addSubview(faceView)
        }
    }
    
    // 马赛克
    @available(iOS 8.0, *)
    @IBAction func pixellated() {
        // 1.
        let filter = CIFilter(name: "CIPixellate")!
        print(filter.attributes)
        let inputImage = CIImage(image: originalImage)!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        // filter.setValue(max(inputImage.extent.size.width, inputImage.extent.size.height) / 60, forKey: kCIInputScaleKey)
        let fullPixellatedImage = filter.outputImage
        // let cgImage = context.createCGImage(fullPixellatedImage, fromRect: fullPixellatedImage.extent)
        // imageView.image = UIImage(CGImage: cgImage)
        // 2.
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: context,
                                  options: nil)
        let faceFeatures = detector?.features(in: inputImage)
        // 3.
        var maskImage: CIImage!
        let scale = min(imageView.bounds.size.width / inputImage.extent.size.width,
                        imageView.bounds.size.height / inputImage.extent.size.height)
        for faceFeature in faceFeatures! {
            print(faceFeature.bounds)
            // 4.
            let centerX = faceFeature.bounds.origin.x + faceFeature.bounds.size.width / 2
            let centerY = faceFeature.bounds.origin.y + faceFeature.bounds.size.height / 2
            let radius = min(faceFeature.bounds.size.width, faceFeature.bounds.size.height) * scale
            let radialGradient = CIFilter(name: "CIRadialGradient",
                                          withInputParameters: [
                                            "inputRadius0" : radius,
                                            "inputRadius1" : radius + 1,
                                            "inputColor0" : CIColor(red: 0, green: 1, blue: 0, alpha: 1),
                                            "inputColor1" : CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                                            kCIInputCenterKey : CIVector(x: centerX, y: centerY)
                ])!
			
            print(radialGradient.attributes)
            // 5.
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
            print(maskImage.extent)
        }
        // 6.
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(fullPixellatedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        // 7.
        let blendOutputImage = blendFilter.outputImage!
        if let blendCGImage = context.createCGImage(blendOutputImage, from: blendOutputImage.extent) {
            imageView.image = UIImage(cgImage: blendCGImage)
        }
    }
}

