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
        return UIImage(named: "Image")
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
        let inputImage = CIImage(image: originalImage)
        let detector = CIDetector(ofType: CIDetectorTypeFace,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        var faceFeatures: [CIFaceFeature]!
        if let orientation: AnyObject = inputImage.properties()?[kCGImagePropertyOrientation] {
            faceFeatures = detector.featuresInImage(inputImage, options: [CIDetectorImageOrientation: orientation]) as [CIFaceFeature]
        } else {
            faceFeatures = detector.featuresInImage(inputImage) as [CIFaceFeature]
        }
        
        println(faceFeatures)
        
        // 1.
        let inputImageSize = inputImage.extent().size
        var transform = CGAffineTransformIdentity
        transform = CGAffineTransformScale(transform, 1, -1)
        transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height)

        for faceFeature in faceFeatures {
            var faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform)
            
            // 2.
            var scale = min(imageView.bounds.size.width / inputImageSize.width,
                imageView.bounds.size.height / inputImageSize.height)
            var offsetX = (imageView.bounds.size.width - inputImageSize.width * scale) / 2
            var offsetY = (imageView.bounds.size.height - inputImageSize.height * scale) / 2
            
            faceViewBounds = CGRectApplyAffineTransform(faceViewBounds, CGAffineTransformMakeScale(scale, scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            let faceView = UIView(frame: faceViewBounds)
            faceView.layer.borderColor = UIColor.orangeColor().CGColor
            faceView.layer.borderWidth = 2
            
            imageView.addSubview(faceView)
        }
    }
    
    // 马赛克
    @IBAction func pixellated() {
        // 1.
        var filter = CIFilter(name: "CIPixellate")
        println(filter.attributes())
        let inputImage = CIImage(image: originalImage)
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        // filter.setValue(max(inputImage.extent().size.width, inputImage.extent().size.height) / 60, forKey: kCIInputScaleKey)
        let fullPixellatedImage = filter.outputImage
        // let cgImage = context.createCGImage(fullPixellatedImage, fromRect: fullPixellatedImage.extent())
        // imageView.image = UIImage(CGImage: cgImage)
        // 2.
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: context,
                                  options: nil)
        let faceFeatures = detector.featuresInImage(inputImage)
        // 3.
        var maskImage: CIImage!
        var scale = min(imageView.bounds.size.width / inputImage.extent().size.width,
                        imageView.bounds.size.height / inputImage.extent().size.height)
        for faceFeature in faceFeatures {
            println(faceFeature.bounds)
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
                ])
            println(radialGradient.attributes())
            // 5.
            let radialGradientOutputImage = radialGradient.outputImage.imageByCroppingToRect(inputImage.extent())
            if maskImage == nil {
                maskImage = radialGradientOutputImage
            } else {
                println(radialGradientOutputImage)
                maskImage = CIFilter(name: "CISourceOverCompositing",
                    withInputParameters: [
                        kCIInputImageKey : radialGradientOutputImage,
                        kCIInputBackgroundImageKey : maskImage
                    ]).outputImage
            }
            println(maskImage.extent())
        }
        // 6.
        let blendFilter = CIFilter(name: "CIBlendWithMask")
        blendFilter.setValue(fullPixellatedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        // 7.
        let blendOutputImage = blendFilter.outputImage
        let blendCGImage = context.createCGImage(blendOutputImage, fromRect: blendOutputImage.extent())
        imageView.image = UIImage(CGImage: blendCGImage)
    }
}

