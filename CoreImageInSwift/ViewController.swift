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
    
    @IBOutlet var intensitySlider: UISlider!
    var filter: CIFilter!
    lazy var context: CIContext = {
        return CIContext(options: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.layer.shadowOpacity = 0.8
        self.imageView.layer.shadowColor = UIColor.blackColor().CGColor
        self.imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        self.imageView.image = originalImage

        showFiltersInConsole()
    }
    
    func showFiltersInConsole() {
        let filterNames = CIFilter.filterNamesInCategory(kCICategoryColorEffect)
        println(filterNames)
        for filterName in filterNames {
            let filter = CIFilter(name: filterName as String)
            let attributes = filter.attributes()
            println(attributes)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -
    
    @IBAction func onValueChanged() {
        filter.setValue(intensitySlider.value, forKey: kCIInputIntensityKey)
        let outputImage =  filter.outputImage
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        self.imageView.image = UIImage(CGImage: cgImage)
    }

    @IBAction func showOriginalImage() {
        self.imageView.image = originalImage
    }
    
    func outputImage() {
        println(filter)
        let outputImage =  filter.outputImage
        //ContentMode属性需要根据CGImage来调整
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
//        self.imageView.image = UIImage(CIImage: outputImage)
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
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIPhotoEffectInstant")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
//        filter.setValue(intensitySlider.value, forKey: kCIInputIntensityKey)
        outputImage()
    }
    
    // MARK: - 黑白
    @IBAction func photoEffectNoir() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIPhotoEffectNoir")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
//        filter.setValue(intensitySlider.value, forKey: kCIInputIntensityKey)
        outputImage()
    }
    
    // MARK: - 色调
    @IBAction func photoEffectTonal() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIPhotoEffectTonal")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
//        intensitySlider.minimumValue = 2
//        intensitySlider.maximumValue = 30
//        filter.setValue(20, forKey: "inputLevels")
        outputImage()
    }
    
    // MARK: - 岁月
    @IBAction func photoEffectTransfer() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIPhotoEffectTransfer")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        outputImage()
    }
    
    // MARK: - 单色
    @IBAction func photoEffectMono() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIPhotoEffectMono")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        outputImage()
    }
    
    // MARK: - 褪色
    @IBAction func photoEffectFade() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIPhotoEffectFade")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        outputImage()
    }

    // MARK: - 冲印
    @IBAction func photoEffectProcess() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIPhotoEffectProcess")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        outputImage()
    }
    
    // MARK: - 铬黄
    @IBAction func photoEffectChrome() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIPhotoEffectChrome")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        outputImage()
    }
}

