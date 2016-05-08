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
    var images = [UIImage]()
    var name: String
    var duration:Double
    
    init(frames:Array<NSData>, name:String) {
        self.name = name
        self.images = [UIImage]()
        self.duration = Double(frames.count) / Double(_fps)
        for (_, frame) in frames.enumerate() {
            let image:UIImage = UIImage(data: frame)!
            self.images.append(image)
        }
    }

}