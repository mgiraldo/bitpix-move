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

    @IBOutlet var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    @IBOutlet var helpButton: WKInterfaceButton!
    
    var name: String!
    var truncated: NSNumber = 0

    var animation: Animation? {
        didSet {
            if let animation = animation where animation.images.count > 0 {
                name = animation.name
                statusGroup.setBackgroundImage(nil)
                let frames = UIImage.animatedImageWithImages(animation.images, duration: animation.duration)
                statusGroup.setBackgroundImage(frames)
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

    @IBAction func onHelpTapped() {
        print("help")
        let action = WKAlertAction(title: "OK", style: .Default){}
        presentAlertControllerWithTitle(nil, message: "Animation is too long for the watch. Displaying first \(_watchFrameLimit) frames only", preferredStyle: .Alert, actions: [action])
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        helpButton.setHidden(true)
        if let name = context as? String { self.name = name }
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
        if name != nil && WCSession.isSupported() {
            print("page", name)
            requestFrames()
        }
    }
    
    func requestFrames() {
        session = WCSession.defaultSession()
        session!.sendMessage(["request": name], replyHandler: { (response) -> Void in
            print("page received info!")
//            print(response)
            if let animation = response["animation"] as? NSDictionary, frames = animation["frames"] as? Array<NSData>, truncated = animation["truncated"] as? NSNumber {
//                print(animation)
                let tmp:Animation = Animation(frames: frames, name: self.name)
                self.truncated = truncated
                self.animation = tmp
            }
        }, errorHandler: { (error) -> Void in
            print("page Error \(error)")
        })
    }
    
    private func showAnimation() {
        print(name, animation?.duration, animation?.images.count, truncated)
        statusLabel.setHidden(false)
        if (truncated == 1) {
            helpButton.setHidden(false)
            helpButton.setTitle("First \(_watchFrameLimit) frames")
        } else {
            helpButton.setHidden(true)
        }
        if (animation != nil) {
            statusLabel.setHidden(true)
            statusGroup.startAnimatingWithImagesInRange(NSMakeRange(0, animation!.images.count), duration: (animation?.duration)!, repeatCount: 0)
        }
    }
}

extension PageInterfaceController: WCSessionDelegate {
    
}
