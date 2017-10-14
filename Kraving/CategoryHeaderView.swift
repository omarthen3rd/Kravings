//
//  CategoryHeaderView.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-10-09.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit

class CategoryHeaderView: UIView {
    
    var imageView: UIImageView!
    var colorView: UIView!
    var bgBlur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    var closeBtn: UIButton!

    init(frame: CGRect, image: UIImage?) {
        if let imageView = imageView {
            imageView.image = image
        }
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        
        self.backgroundColor = UIColor.clear
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        bgBlur.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(bgBlur)
        
        let constraints:[NSLayoutConstraint] = [
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            bgBlur.topAnchor.constraint(equalTo: self.topAnchor),
            bgBlur.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bgBlur.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bgBlur.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        if let close = closeBtn {
            
            let btnImg = #imageLiteral(resourceName: "btn_closeView").withRenderingMode(.alwaysTemplate)
            close.setImage(btnImg, for: .normal)
            // closeBtn.addTarget(self, action: #selector(self.hero_dismissViewController), for: .touchUpInside)
            
            let btnConstraints: [NSLayoutConstraint] = [close.centerXAnchor.constraint(equalTo: self.centerXAnchor), close.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 6), close.widthAnchor.constraint(equalToConstant: 40), close.heightAnchor.constraint(equalToConstant: 40)]
            
            NSLayoutConstraint.activate(btnConstraints)
            
        }
        
    }
    
}
