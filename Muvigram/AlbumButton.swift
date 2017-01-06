//
//  AlbumButton.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 6..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit

//@IBDesignable
class AlbumButton: UIButton {

    var albumImage: UIImage? {
        didSet{
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(1.0)
        
        if let image = albumImage {
            image.circle?.draw(in: rect)
            
        } else {
            let defaultWidthAndHeight: CGFloat = rect.size.width
            let defaultRectangle = CGRect(x: frame.size.width / 2 - defaultWidthAndHeight/2,
                                          y: frame.size.height / 2 - defaultWidthAndHeight/2,
                                          width: defaultWidthAndHeight,
                                          height: defaultWidthAndHeight)
            let defaultColor = UIColor(red: CGFloat(0.090), green: CGFloat(0.090), blue: CGFloat(0.090), alpha: CGFloat(1.0)).cgColor
            
            
            context?.setStrokeColor(defaultColor)
            context?.setFillColor(defaultColor)
            context?.addEllipse(in: defaultRectangle)
            context?.fillPath()
        }
        
        context?.setLineWidth(1.0)
        
        let outerColor = UIColor(red: CGFloat(0.090), green: CGFloat(0.090), blue: CGFloat(0.090), alpha: CGFloat(0.7)).cgColor
        
        context?.setStrokeColor(outerColor)
        context?.setFillColor(outerColor)
        
        let outerWidthAndHeight: CGFloat = 15.0
        
        let outerRectangle = CGRect(x: frame.size.width / 2 - outerWidthAndHeight/2,
                                    y: frame.size.height / 2 - outerWidthAndHeight/2,
                                    width: outerWidthAndHeight,
                                    height: outerWidthAndHeight)
        context?.addEllipse(in: outerRectangle)
        context?.fillPath()
        
        context?.setStrokeColor(UIColor.yellow.cgColor)
        context?.setFillColor(UIColor.yellow.cgColor)
        
        let innerWidthAndHeight: CGFloat!
        
        if let _ = albumImage {
            innerWidthAndHeight = 7.0
        } else {
            innerWidthAndHeight = 14.0
        }
        
        let innerRectangle = CGRect(x: frame.size.width / 2 - innerWidthAndHeight/2,
                                    y: frame.size.height / 2 - innerWidthAndHeight/2,
                                    width: innerWidthAndHeight,
                                    height: innerWidthAndHeight)
        context?.addEllipse(in: innerRectangle)
        context?.fillPath()
    }

}

extension UIImage {
    var circle: UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
