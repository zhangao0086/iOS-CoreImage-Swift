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
        let filterNames = CIFilter.filterNamesInCategory(kCICategoryColorAdjustment)
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
}

