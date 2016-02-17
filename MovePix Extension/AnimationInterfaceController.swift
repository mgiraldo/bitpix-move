//
//  AnimationInterfaceController.swift
//  bitpix-move
//
//  Created by Mauricio Giraldo on 13/2/16.
//  Copyright © 2016 Ping Pong Estudio. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class AnimationInterfaceController: WKInterfaceController {

    @IBOutlet var animationImage: WKInterfaceImage!
    @IBOutlet var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    
    var animation: Animation? {
        didSet {
            if let animation = animation {
                if animation.images.count > 0 {
                    animationImage.setImage(animation.images[0])
                    animationImage.startAnimatingWithImagesInRange(NSRange(location: 0,length: animation.images.count), duration: animation.duration, repeatCount: 0)
                }
            }
        }
    }
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
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

    override func didAppear() {
        super.didAppear()
        // 1
        if let animation = animation where animation.images.count == 0 && WCSession.isSupported() {
            // 2
            session = WCSession.defaultSession()
            // 3
            session!.sendMessage(["name": animation.name], replyHandler: { (response) -> Void in
                // 4
//                if let boardingPassData = response["imagesData"] as? NSData, boardingPass = UIImage(data: imagesData) {
//                    // 5
//                    animation.images = imagesData
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        self.showBoardingPass()
//                    })
//                }
                }, errorHandler: { (error) -> Void in
                    // 6
                    print(error)
            })
        }
    }
    
    private func showAnimation() {
        animationImage.stopAnimating()
        animationImage.setWidth(100)
        animationImage.setHeight(100)
        animationImage.setImage(animation?.images[0])
        animationImage.startAnimating()
    }

}

extension AnimationInterfaceController: WCSessionDelegate {
    
}
