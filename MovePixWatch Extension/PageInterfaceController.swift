//
//  PageInterfaceController.swift
//  MovePix
//
//  Created by Mauricio Giraldo on 7/5/16.
//  Copyright © 2016 Mauricio Giraldo Arteaga. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class PageInterfaceController: WKInterfaceController {

    @IBOutlet var animationImage: WKInterfaceImage!
    @IBOutlet var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    
    var name: String!

    var animation: Animation? {
        didSet {
            if let animation = animation where animation.images.count > 0 {
                name = animation.name
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
        if let name = context as? String { self.name = name }
        print("page", name)
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
        print("page hello!")
        if name != nil && WCSession.isSupported() {
            print("page nothing")
            requestFrames()
        }
    }
    
    func requestFrames() {
        session = WCSession.defaultSession()
        session!.sendMessage(["request": name], replyHandler: { (response) -> Void in
            print("page received info!")
//            print(response)
            if let animation = response["animation"] as? NSDictionary, frames = animation["frames"] as? Array<NSData> {
//                print(animation)
                let tmp:Animation = Animation(frames: frames, name: self.name)
                self.animation = tmp
            }
        }, errorHandler: { (error) -> Void in
            print("page Error \(error)")
        })
    }
    
    private func showAnimation() {
        print(animation?.duration, _fps, animation?.images.count)
        if (animation != nil) {
            statusLabel.setHidden(true)
            animationImage.setHidden(false)
            animationImage.stopAnimating()
            animationImage.startAnimatingWithImagesInRange(NSMakeRange(0, animation!.images.count), duration: (animation?.duration)!, repeatCount: 0)
        }
    }
}

extension PageInterfaceController: WCSessionDelegate {
    
}
