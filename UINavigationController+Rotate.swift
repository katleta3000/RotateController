//
//  UINavigationController+Rotate.swift
//  FoudCourt
//
//  Created by Evgenii Rtishchev on 09/07/15.
//  Copyright (c) 2015 Evgenii Rtishchev. All rights reserved.
//

import UIKit

enum RotationDirection: Int {
    case Right = 0, Left
}

enum RotationType: Int {
    case Push = 0, Pop
}

class FCBlackBackgroundView: UIView {
    
}

class FCRotateLayer: CALayer {
}

extension UINavigationController {
    
    func pushViewController(controller: UIViewController, rotateDirection: RotationDirection) {
        perform3DRotate(.Push, rotateDirection: rotateDirection, controller: controller)
    }
    
    func popViewController(rotateDirection: RotationDirection) {
        perform3DRotate(.Pop, rotateDirection: rotateDirection, controller: nil)
    }
    
    // MARK: - private
    
    func perform3DRotate(type: RotationType, rotateDirection: RotationDirection, controller: UIViewController?) {
        let layer = rotationLayer()
        let cube = cubeTransform(rotateDirection, layer: layer)
        if type == .Push {
            self.pushViewController(controller!, animated: false)
        }
        else if type == .Pop {
            self.popViewControllerAnimated(false)
        }
        layer.addSublayer(layerFromView(self.view, transform: cube))
        self.view.addSubview(backgroundView(UIColor.whiteColor()))
        self.view.layer.addSublayer(layer)
        layer.addAnimation(rotationAnimation(rotateDirection), forKey: "rotate")
    }
    
    func cubeTransform(rotateDirection: RotationDirection, layer: CALayer) -> CATransform3D {
        var cube = CATransform3DMakeTranslation(0, 0, 0)
        layer.addSublayer(layerFromView(self.view, transform: cube))
        cube = CATransform3DRotate(cube, CGFloat(radians(90)), 0, 1, 0)
        cube = CATransform3DTranslate(cube, cubeSize(), 0, 0)
        if rotateDirection == .Left {
            cube = CATransform3DRotate(cube, CGFloat(radians(90)), 0, 1, 0)
            cube = CATransform3DTranslate(cube, cubeSize(), 0, 0)
            cube = CATransform3DRotate(cube, CGFloat(radians(90)), 0, 1, 0)
            cube = CATransform3DTranslate(cube, cubeSize(), 0, 0)
        }
        return cube
    }
    
    func rotationLayer() -> FCRotateLayer {
        let layer: FCRotateLayer = FCRotateLayer()
        layer.frame = self.view.frame
        layer.anchorPoint = CGPointMake(0.5, 0.5)
        var transform: CATransform3D = CATransform3DIdentity
        transform.m34 = 1.0 / -750
        layer.sublayerTransform = transform
        return layer
    }
    
    func rotationAnimation(direction: RotationDirection) -> CAAnimation {
        CATransaction.flush()
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 0.4
        var rotation: CABasicAnimation!
        var translationX: CABasicAnimation!
        if direction == .Right {
            rotation = CABasicAnimation(keyPath: "sublayerTransform.rotation.y")
            rotation.toValue = NSNumber(float: radians(-90))
            translationX = CABasicAnimation(keyPath: "sublayerTransform.translation.x")
            translationX.toValue = NSNumber(float: Float(-translationForAnimation()))
        }
        else if direction == .Left {
            rotation = CABasicAnimation(keyPath: "sublayerTransform.rotation.y")
            rotation.toValue = NSNumber(float: radians(90))
            translationX = CABasicAnimation(keyPath: "sublayerTransform.translation.x")
            translationX.toValue = NSNumber(float: Float(translationForAnimation()))
        }
        let translationZ = CABasicAnimation(keyPath: "sublayerTransform.translation.z")
        translationZ.toValue = NSNumber(float: Float(-translationForAnimation()))
        animationGroup.animations = [rotation, translationX, translationZ]
        animationGroup.fillMode = kCAFillModeForwards
        animationGroup.removedOnCompletion = false
        animationGroup.delegate = self
        animationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return animationGroup
    }
    
    public override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let layers = self.view.layer.sublayers {
            for layer in layers {
                if layer.isKindOfClass(FCRotateLayer.classForCoder()) {
                    layer.removeFromSuperlayer()
                }
            }
        }
        for view in self.view.subviews {
            if view.isKindOfClass(FCBlackBackgroundView.classForCoder()) {
                view.removeFromSuperview()
            }
        }
    }
    
    func layerFromView(view: UIView) -> CALayer {
        let rect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.frame.size.height)
        let imageLayer = CALayer()
        imageLayer.anchorPoint = CGPointMake(1, 1)
        imageLayer.frame = rect
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, UIScreen.mainScreen().scale)
        if let context = UIGraphicsGetCurrentContext() {
            view.layer.renderInContext(context)
        }
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        imageLayer.contents = image.CGImage
        return imageLayer
    }
    
    func layerFromView(view: UIView, transform: CATransform3D) -> CALayer {
        let layer = layerFromView(view)
        layer.transform = transform
        return layer
    }
    
    func backgroundView(color: UIColor) -> FCBlackBackgroundView {
        let view = FCBlackBackgroundView(frame: self.view.frame)
        view.backgroundColor = color
        return view
    }
    
    func radians(degrees: Float) -> Float {
        return degrees * Float(M_PI) / 180
    }
    
    func translationForAnimation() -> CGFloat {
        return cubeSize() / 2
    }
    
    func cubeSize() -> CGFloat {
        return UIScreen.mainScreen().bounds.width
    }
}
