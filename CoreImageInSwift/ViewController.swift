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
                            
    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.layer.shadowOpacity = 0.8
        self.imageView.layer.shadowColor = UIColor.blackColor().CGColor
        self.imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        self.imageView.image = UIImage(named: "Image")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

