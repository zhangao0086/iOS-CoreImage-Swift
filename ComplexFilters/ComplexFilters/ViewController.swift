//
//  ViewController.swift
//  ComplexFilters
//
//  Created by ZhangAo on 14-9-7.
//  Copyright (c) 2014年 zhangao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var slider: UISlider!
    lazy var originalImage: UIImage = {
        return UIImage(named: "Image")
    }()
    
    lazy var context: CIContext = {
        return CIContext(options: nil)
    }()
    
    var filter: CIFilter!
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.shadowOpacity = 0.8
        imageView.layer.shadowColor = UIColor.blackColor().CGColor
        imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        slider.maximumValue = Float(M_PI)
        slider.minimumValue = Float(-M_PI)
        slider.value = 0
        slider.addTarget(self, action: "valueChanged", forControlEvents: UIControlEvents.ValueChanged)

        let inputImage = CIImage(image: originalImage)
        filter = CIFilter(name: "CIHueAdjust")
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        slider.sendActionsForControlEvents(UIControlEvents.ValueChanged)
        
        showFiltersInConsole()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: -
    func showFiltersInConsole() {
        let filterNames = CIFilter.filterNamesInCategory(kCICategoryBuiltIn)
        println(filterNames.count)
        println(filterNames)
        for filterName in filterNames {
            let filter = CIFilter(name: filterName as String)
            let attributes = filter.attributes()
            println(attributes)
        }
    }
    
    @IBAction func valueChanged() {
        println(slider.value)
        filter.setValue(slider.value, forKey: kCIInputAngleKey)
        let outputImage = filter.outputImage
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        imageView.image = UIImage(CGImage: cgImage)
    }
    
    @IBAction func oldFilmEffect() {
        let inputImage = CIImage(image: originalImage)
        
        let sepiaToneFilter = CIFilter(name: "CISepiaTone")
        sepiaToneFilter.setValue(inputImage, forKey: kCIInputImageKey)
        sepiaToneFilter.setValue(1, forKey: kCIInputIntensityKey)
        
        let whiteSpecksFilter = CIFilter(name: "CIColorMatrix")
        whiteSpecksFilter.setValue(CIFilter(name: "CIRandomGenerator").outputImage.imageByCroppingToRect(inputImage.extent()), forKey: kCIInputImageKey)
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputRVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputBVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")
        sourceOverCompositingFilter.setValue(whiteSpecksFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        sourceOverCompositingFilter.setValue(sepiaToneFilter.outputImage, forKey: kCIInputImageKey)
        
        
        let affineTransformFilter = CIFilter(name: "CIAffineTransform")
        affineTransformFilter.setValue(CIFilter(name: "CIRandomGenerator").outputImage.imageByCroppingToRect(inputImage.extent()), forKey: kCIInputImageKey)
        affineTransformFilter.setValue(NSValue(CGAffineTransform: CGAffineTransformMakeScale(1.5, 25)), forKey: kCIInputTransformKey)

        let darkScratchesFilter = CIFilter(name: "CIColorMatrix")
        darkScratchesFilter.setValue(affineTransformFilter.outputImage, forKey: kCIInputImageKey)
        darkScratchesFilter.setValue(CIVector(x: 4, y: 0, z: 0, w: 0), forKey: "inputRVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 1, z: 1, w: 1), forKey: "inputBiasVector")
        
        let minimumComponentFilter = CIFilter(name: "CIMinimumComponent")
        minimumComponentFilter.setValue(darkScratchesFilter.outputImage, forKey: kCIInputImageKey)

        
        let multiplyCompositingFilter = CIFilter(name: "CIMultiplyCompositing")
        multiplyCompositingFilter.setValue(sourceOverCompositingFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        multiplyCompositingFilter.setValue(minimumComponentFilter.outputImage, forKey: kCIInputImageKey)
        
        let outputImage = multiplyCompositingFilter.outputImage
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        imageView.image = UIImage(CGImage: cgImage)
    }
}

