//
//  ViewController.swift
//  SimpleFilters
//
//  Created by ZhangAo on 14-9-7.
//  Copyright (c) 2014年 zhangao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    lazy var originalImage: UIImage = {
        return UIImage(named: "Image")
    }()
    
    lazy var context: CIContext = {
        return CIContext(options: nil)
    }()
    
    var filter: CIFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.layer.shadowOpacity = 0.8
        self.imageView.layer.shadowColor = UIColor.blackColor().CGColor
        self.imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        self.imageView.image = originalImage
        
        showFiltersInConsole()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -
    func showFiltersInConsole() {
        let filterNames = CIFilter.filterNamesInCategory(kCICategoryColorEffect)
        println(filterNames.count)
        println(filterNames)
        for filterName in filterNames {
            let filter = CIFilter(name: filterName as String)
            let attributes = filter.attributes()
            println(attributes)
        }
    }
    
    @IBAction func showOriginalImage() {
        self.imageView.image = originalImage
    }
    
    func outputImage() {
        println(filter)
        let inputImage = CIImage(image: originalImage)
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        let outputImage =  filter.outputImage
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        self.imageView.image = UIImage(CGImage: cgImage)
    }
    
    // MARK: - 自动改善
    @IBAction func autoAdjust() {
        var inputImage = CIImage(image: originalImage)
        let filters = inputImage.autoAdjustmentFilters() as [CIFilter]
        for filter: CIFilter in filters {
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            inputImage = filter.outputImage
        }
        let cgImage = context.createCGImage(inputImage, fromRect: inputImage.extent())
        self.imageView.image = UIImage(CGImage: cgImage)
    }
    
    // MARK: - 怀旧
    @IBAction func photoEffectInstant() {
        filter = CIFilter(name: "CIPhotoEffectInstant")
        outputImage()
    }
    
    // MARK: - 黑白
    @IBAction func photoEffectNoir() {
        filter = CIFilter(name: "CIPhotoEffectNoir")
        outputImage()
    }
    
    // MARK: - 色调
    @IBAction func photoEffectTonal() {
        filter = CIFilter(name: "CIPhotoEffectTonal")
        outputImage()
    }
    
    // MARK: - 岁月
    @IBAction func photoEffectTransfer() {
        filter = CIFilter(name: "CIPhotoEffectTransfer")
        outputImage()
    }
    
    // MARK: - 单色
    @IBAction func photoEffectMono() {
        filter = CIFilter(name: "CIPhotoEffectMono")
        outputImage()
    }
    
    // MARK: - 褪色
    @IBAction func photoEffectFade() {
        filter = CIFilter(name: "CIPhotoEffectFade")
        outputImage()
    }
    
    // MARK: - 冲印
    @IBAction func photoEffectProcess() {
        filter = CIFilter(name: "CIPhotoEffectProcess")
        outputImage()
    }
    
    // MARK: - 铬黄
    @IBAction func photoEffectChrome() {
        filter = CIFilter(name: "CIPhotoEffectChrome")
        outputImage()
    }
}

