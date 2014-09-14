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
    
    @IBAction func faceDetecing() {
        let inputImage = CIImage(image: originalImage)
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let faceFeatures = detector.featuresInImage(inputImage) as [CIFaceFeature]

        println(faceFeatures)
        
        let inputImageSize = inputImage.extent().size
        var transform = CGAffineTransformIdentity
        transform = CGAffineTransformScale(transform, 1, -1)
        transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height)
        
        for faceFeature in faceFeatures {
//            var faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform)
        
            var scale = min(imageView.bounds.size.width / inputImageSize.width,
                            imageView.bounds.size.height / inputImageSize.height)
            var offsetX = (imageView.bounds.size.width - inputImageSize.width * scale) / 2
            var offsetY = (imageView.bounds.size.height - inputImageSize.height * scale) / 2
            transform = CGAffineTransformScale(transform, scale, scale)
            var faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform)
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            println(faceViewBounds)
            
            let faceView = UIView(frame: faceViewBounds)
            faceView.layer.borderColor = UIColor.orangeColor().CGColor
            faceView.layer.borderWidth = 2
            
            imageView.addSubview(faceView)
        }
    }
}

