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

    @IBOutlet var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!

    var animations: [String]?
    
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
        if animations == nil && WCSession.isSupported() {
            print("nothing")
            requestAnimations()
        }
    }
    
    func requestAnimations() {
        session = WCSession.defaultSession()
        session!.sendMessage(["request": ["action": "few"]], replyHandler: { (response) -> Void in
            print("received info!")
//            print(response)
            if let total = response["total"] as? NSInteger, uuids = response["uuids"] as? [String] {
                if (total > 0) {
                    self.statusGroup.setHidden(true)
                    self.animations = uuids
                    var pages = [String]()
                    for (_, _) in uuids.enumerate() {
                        pages.append("Page")
                    }
                    WKInterfaceController.reloadRootControllersWithNames(pages, contexts: uuids)
//                    print(pages, uuids)
                } else {
                    self.statusLabel.setText("Use your phone to create an animation")
                }
            }
        }, errorHandler: { (error) -> Void in
            print("Error \(error)")
        })
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("received:")
//        print(userInfo)
    }

//    private func showAnimation() {
//        print(animation?.duration, _fps, animation?.images.count)
//        if (animation != nil) {
//            statusLabel.setHidden(true)
//            animationImage.setHidden(false)
//            animationImage.stopAnimating()
//            animationImage.startAnimatingWithImagesInRange(NSMakeRange(0, animation!.images.count), duration: (animation?.duration)!, repeatCount: 0)
//        }
//    }

}

extension InterfaceController: WCSessionDelegate {
    
}

