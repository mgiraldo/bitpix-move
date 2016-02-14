//
//  AnimationInterfaceController.swift
//  bitpix-move
//
//  Created by Mauricio Giraldo on 13/2/16.
//  Copyright © 2016 Ping Pong Estudio. All rights reserved.
//

import WatchKit
import Foundation

class AnimationInterfaceController: WKInterfaceController {

    @IBOutlet var animationImage: WKInterfaceImage!
    @IBOutlet var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    
    var animation: Animation? {
        didSet {
            if let animation = animation {
                animationImage.setImage(animation.images[0])
                animationImage.startAnimatingWithImagesInRange(NSRange(location: 0,length: animation.images.count), duration: animation.duration, repeatCount: 0)
            }
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        animation = Animation.allAnimations().first
        print(animation)
        if (animation != nil) {
            statusGroup.setHidden(true)
        } else {
            animationImage.setHidden(true)
            statusLabel.setText("Use your phone to create an animation")
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
