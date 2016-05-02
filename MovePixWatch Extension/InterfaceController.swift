//
//  InterfaceController.swift
//  MovePixWatch Extension
//
//  Created by Mauricio Giraldo on 20/3/16.
//  Copyright © 2016 Mauricio Giraldo Arteaga. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {

    @IBOutlet var animationImage: WKInterfaceImage!
    @IBOutlet var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!

    var animations = [Animation]()
    
    var animation: Animation? {
        didSet {
            if let animation = animation where animation.images.count > 0 {
                animationImage.setImage(nil)
                let frames = UIImage.animatedImageWithImages(animation.images, duration: animation.duration)
                animationImage.setImage(frames)
                showAnimation()
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
        if let animation = context as? Animation { self.animation = animation }
//        animation = Animation.allAnimations().first
        print(animation)
//        if (animation != nil) {
//            statusGroup.setHidden(true)
//        } else {
//            animationImage.setHidden(true)
//            statusLabel.setText("Use your phone to create an animation")
//        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    override func didAppear() {
        super.didAppear()
        print("hello!")
        if animation == nil && WCSession.isSupported() {
            print("nothing")
            requestAnimations()
        }
    }
    
    func requestAnimations() {
        session = WCSession.defaultSession()
        session!.sendMessage(["name": "ten"], replyHandler: { (response) -> Void in
            print("received info!")
//                            print(response)
            if let animationsData = response["animations"] as? NSArray {
//                                    print(animationsData)
                self.animations = [Animation]()
                for (_, stuff) in animationsData.enumerate() {
                    if let frames = stuff["frames"] as? Array<NSData>, name = stuff["name"] as? String {
                        let tmp:Animation = Animation(frames: frames, name: name)
                        self.animations.append(tmp)
                    }
                }
                print("animations: \(self.animations)")
                self.animation = self.animations[0]
            }
            }, errorHandler: { (error) -> Void in
                print("Error \(error)")
        })
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("received:")
//        print(userInfo)
    }

    private func showAnimation() {
        print(animation?.duration, _fps, animation?.images.count)
        if (animation != nil) {
            statusLabel.setHidden(true)
            animationImage.setHidden(false)
            animationImage.stopAnimating()
            animationImage.startAnimating()
        }
    }

}

extension InterfaceController: WCSessionDelegate {
    
}

