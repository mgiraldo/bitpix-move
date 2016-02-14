//
//  Animation.swift
//  bitpix-move
//
//  Created by Mauricio Giraldo on 13/2/16.
//  Copyright © 2016 Ping Pong Estudio. All rights reserved.
//

import WatchKit
import Foundation

class Animation {
    var images: Array<UIImage>
    var date: NSDate
    var name: String
    var frames: Array<String>
    var duration:Double
    
    class func allAnimations() -> [Animation] {
        var animations = [Animation]()
        if let path = NSBundle.mainBundle().pathForResource("Data", ofType: "plist"), let data = NSDictionary (contentsOfFile: path) {
            do {
                let arr = data["userAnimations"] as? [NSDictionary]
                for dict in arr! {
                    let date = dict["date"] as! NSDate
                    let name = dict["name"] as! String
                    let frames: Array<String> = dict["frames"] as! [String]
                    let animation = Animation(date: date, frames: frames, name: name)
                    animations.append(animation)
                }
            }
        }
        return animations
    }
    
    init(date:NSDate, frames:Array<String>, name:String) {
        self.date = date
        self.frames = frames
        self.name = name
        self.duration = Double(frames.count) / Double(_fps);
        // crazy antics to make _fileSuffix a swift friendly var
        var _swSuffix = _fileSuffix
        let _suffix = withUnsafePointer(&_swSuffix) {
            String.fromCString(UnsafePointer($0))!
        }
        // get them images
        self.images = [UIImage]()
        for (i, frame) in frames.enumerate() {
            let imagePath = String(format: "%@/%@%s%d.png", frame, frame, _suffix, i)
            let fullPath = UserData.dataFilePath(imagePath)
            let image:UIImage = UIImage(contentsOfFile: fullPath)!
            self.images.append(image)
        }
    }
}