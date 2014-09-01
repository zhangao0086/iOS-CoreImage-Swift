//
//  ViewController.swift
//  CoreImageInSwift
//
//  Created by ZhangAo on 14-8-30.
//  Copyright (c) 2014年 zhangao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    lazy var originalImage: UIImage = {
        return UIImage(named: "Image")
    }()
                            
    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.layer.shadowOpacity = 0.8
        self.imageView.layer.shadowColor = UIColor.blackColor().CGColor
        self.imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        self.imageView.image = originalImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

     // MARK: - 怀旧效果
    @IBAction func sepiaTone() {
        let inputImage = CIImage(image: originalImage)
        let sepiaToneFilter = CIFilter(name: "CISepiaTone")
        sepiaToneFilter.setValue(inputImage, forKey: kCIInputImageKey)
        sepiaToneFilter.setValue(0.5, forKey: kCIInputIntensityKey)
        
        let outputImage =  sepiaToneFilter.outputImage
        //ContentMode属性需要根据CGImage来调整
        let cg = CIContext(options: nil).createCGImage(outputImage, fromRect: outputImage.extent())
//        self.imageView.image = UIImage(CIImage: outputImage)
        self.imageView.image = UIImage(CGImage: cg)
    }
    
    @IBAction func showOriginalImage() {
        self.imageView.image = originalImage
    }
}

