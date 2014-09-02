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
    @IBOutlet var intensitySlider: UISlider!
    
    lazy var originalImage: UIImage = {
        return UIImage(named: "Image")
    }()
    
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
    
    // MARK: - 怀旧
    @IBAction func sepiaTone() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CISepiaTone")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(intensitySlider.value, forKey: kCIInputIntensityKey)
        outputImage()
    }
    
    // MARK: - 黑白
    @IBAction func monochrome() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIColorMonochrome")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(intensitySlider.value, forKey: kCIInputIntensityKey)
        outputImage()
    }
    
    @IBAction func posterize() {
        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIColorPosterize")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        intensitySlider.minimumValue = 2
        intensitySlider.maximumValue = 30
        filter.setValue(20, forKey: "inputLevels")
        outputImage()
    }
    
    @IBAction func test() {
        posterize()
        outputImage()
    }
}

