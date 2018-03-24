//
//  Extensions.swift
//  Kraving
//
//  Created by Omar Abbasi on 2018-02-24.
//  Copyright © 2018 Omar Abbasi. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    
    var center: CGPoint {
        return CGPoint(x: width/2 + minX, y: height/2 + minY)
    }
}

extension UILabel {
    
    var height: CGFloat {
        
        return self.bounds.size.height
        
    }
    
    var y: CGFloat {
        
        return self.bounds.origin.y
        
    }
    
    var x: CGFloat {
        
        return self.bounds.origin.x
        
    }
    
    var totalY: CGFloat {
        
        return (self.frame.origin.y + self.bounds.size.height)
        
    }
    
    var totalX: CGFloat {
        
        return (self.bounds.origin.y + self.bounds.size.width)
        
    }
    
}

extension Notification.Name {
    static let applicationWillResignActive = Notification.Name(rawValue: "applicationWillResignActive")
}

extension UIBarButtonSystemItem {
    
    func image() -> UIImage? {
        let tempItem = UIBarButtonItem(barButtonSystemItem: self, target: nil, action: nil)
        
        // add to toolbar and render it
        let bar = UIToolbar()
        bar.setItems([tempItem],
                     animated: false)
        bar.snapshotView(afterScreenUpdates: true)
        
        // got image from real uibutton
        let itemView = tempItem.value(forKey: "view") as! UIView
        for view in itemView.subviews {
            if let button = view as? UIButton,
                let image = button.imageView?.image {
                return image.withRenderingMode(.alwaysTemplate)
            }
        }
        
        return nil
    }
}

extension UIView {
    
    func applyGradient(colours: [UIColor]) -> Void {
        self.applyGradient(colours: colours, locations: nil)
    }
    
    func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
    
}

extension NSMutableAttributedString {
    
    func setColorForText(_ textToFind: String, with color: UIColor) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }
    }
    
    func setColorForRange(_ range: NSRange, with color: UIColor) {
        if range.location != NSNotFound {
            addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }
    }
    
    func setBoldForText(_ textToFind: String) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            let attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 19)]
            addAttributes(attrs, range: range)
        }
        
    }
    
    func setSizeForText(_ textToFind: String, with size: CGFloat) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            let attrs = [NSFontAttributeName : UIFont.systemFont(ofSize: size)]
            addAttributes(attrs, range: range)
        }
        
    }
    
}

extension String {
    
    init(htmlEncodedString: String) {
        do {
            let encodedData = htmlEncodedString.data(using: String.Encoding.utf8)!
            let attributedOptions : [String: AnyObject] = [
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType as AnyObject,
                NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue)
            ]
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            self.init(attributedString.string)!
        } catch {
            fatalError("Unhandled error: \(error)")
        }
    }
    
    var first: String {
        return String(self.prefix(1))
    }
    
    var last: String {
        return String(self.suffix(1))
    }
    
    var uppercaseFirst: String {
        return first.uppercased() + String(self.dropFirst())
    }
    
}

extension UIColor {
    
    static let newBlack = UIColor(red:0.20, green:0.20, blue:0.20, alpha:1.0)
    static let newWhite = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
    
}


extension CIImage {
    
    var image: UIImage? {
        let image = UIImage(ciImage: self)
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
}

extension UIImage {
    
    func applying(saturation value: NSNumber) -> UIImage? {
        return CIImage(image: self)?
            .applyingFilter("CIColorControls", withInputParameters: [kCIInputSaturationKey: value])
            .image
    }
    
    var grayscale: UIImage? {
        return applying(saturation: 0)
    }
    
}

extension UIImageView {
    
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFill) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFill) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
    
}
