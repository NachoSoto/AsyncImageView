//
//  FullScreenImageViewController.swift
//  Example
//
//  Created by Nacho Soto on 12/1/18.
//  Copyright © 2018 Nacho Soto. All rights reserved.
//

import UIKit

import AsyncImageView

final class FullScreenImageViewController: UIViewController {
    init(image: FlickrImageData) {
        self.image = image
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = self.customView
    }
    
    // MARK: -
    
    private lazy var customView: View = {
        return View(image: self.image)
    }()
    
    private let image: FlickrImageData
}

private final class View: UIView {
    init(image: FlickrImageData) {
        self.imageView = Photos.createAspectFitView(initialFrame: .zero)
        
        super.init(frame: .zero)

        self.backgroundColor = .black
        self.addSubview(self.imageView)
        
        self.imageView.data = Photos.Data(imageData: image)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.frame = self.bounds
    }
    
    // MARK: -
    
    private let imageView: Photos.ImageView
}
