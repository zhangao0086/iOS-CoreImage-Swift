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
        // 1.创建CISepiaTone滤镜
        let sepiaToneFilter = CIFilter(name: "CISepiaTone")
        sepiaToneFilter.setValue(inputImage, forKey: kCIInputImageKey)
        sepiaToneFilter.setValue(1, forKey: kCIInputIntensityKey)
        // 2.创建白班图滤镜
        let whiteSpecksFilter = CIFilter(name: "CIColorMatrix")
        whiteSpecksFilter.setValue(CIFilter(name: "CIRandomGenerator").outputImage.imageByCroppingToRect(inputImage.extent()), forKey: kCIInputImageKey)
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputRVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputBVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        // 3.把CISepiaTone滤镜和白班图滤镜以源覆盖(source over)的方式先组合起来
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")
        sourceOverCompositingFilter.setValue(whiteSpecksFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        sourceOverCompositingFilter.setValue(sepiaToneFilter.outputImage, forKey: kCIInputImageKey)
        // ---------上面算是完成了一半
        // 4.用CIAffineTransform滤镜先对随机噪点图进行处理
        let affineTransformFilter = CIFilter(name: "CIAffineTransform")
        affineTransformFilter.setValue(CIFilter(name: "CIRandomGenerator").outputImage.imageByCroppingToRect(inputImage.extent()), forKey: kCIInputImageKey)
        affineTransformFilter.setValue(NSValue(CGAffineTransform: CGAffineTransformMakeScale(1.5, 25)), forKey: kCIInputTransformKey)
        // 5.创建蓝绿色磨砂图滤镜
        let darkScratchesFilter = CIFilter(name: "CIColorMatrix")
        darkScratchesFilter.setValue(affineTransformFilter.outputImage, forKey: kCIInputImageKey)
        darkScratchesFilter.setValue(CIVector(x: 4, y: 0, z: 0, w: 0), forKey: "inputRVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 1, z: 1, w: 1), forKey: "inputBiasVector")
        // 6.用CIMinimumComponent滤镜把蓝绿色磨砂图滤镜处理成黑色磨砂图滤镜
        let minimumComponentFilter = CIFilter(name: "CIMinimumComponent")
        minimumComponentFilter.setValue(darkScratchesFilter.outputImage, forKey: kCIInputImageKey)
        // ---------上面算是基本完成了
        // 7.最终组合在一起
        let multiplyCompositingFilter = CIFilter(name: "CIMultiplyCompositing")
        multiplyCompositingFilter.setValue(minimumComponentFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        multiplyCompositingFilter.setValue(sourceOverCompositingFilter.outputImage, forKey: kCIInputImageKey)
        // 8.最后输出
        let outputImage = multiplyCompositingFilter.outputImage
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        imageView.image = UIImage(CGImage: cgImage)
    }
    
    @IBAction func colorInvert() {
        let colorInvertFilter = CIColorInvert()
        colorInvertFilter.inputImage = CIImage(image: imageView.image)
        let outputImage = colorInvertFilter.outputImage
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        imageView.image = UIImage(CGImage: cgImage)
        
    }
    
    @IBAction func showOriginalImage() {
        self.imageView.image = originalImage
    }
    
    @IBAction func showImage2() {
        imageView.image = UIImage(named: "Image2")
    }
    
    @IBAction func replaceBackground() {
        let cubeMap = createCubeMap(60,90)
        let data = NSData(bytesNoCopy: cubeMap.data, length: Int(cubeMap.length), freeWhenDone: true)
        let colorCubeFilter = CIFilter(name: "CIColorCube")
        
        colorCubeFilter.setValue(cubeMap.dimension, forKey: "inputCubeDimension")
        colorCubeFilter.setValue(data, forKey: "inputCubeData")
        colorCubeFilter.setValue(CIImage(image: imageView.image), forKey: kCIInputImageKey)
        var outputImage = colorCubeFilter.outputImage
        
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")
        sourceOverCompositingFilter.setValue(outputImage, forKey: kCIInputImageKey)
        sourceOverCompositingFilter.setValue(CIImage(image: UIImage(named: "background")), forKey: kCIInputBackgroundImageKey)

        outputImage = sourceOverCompositingFilter.outputImage
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        imageView.image = UIImage(CGImage: cgImage)
        
    }
}

