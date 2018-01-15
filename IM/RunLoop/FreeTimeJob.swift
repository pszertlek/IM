//
//  FreeTimeJob.swift
//  IM
//
//  Created by apple on 2018/1/15.
//  Copyright © 2018年 Pszertlek. All rights reserved.
//

import Foundation

class FreeTimeJob {
    private static var set = NSMutableSet()
    private static var onceToken = 0
    private static var runloop = setup()
    private class func setup() -> CFRunLoop  {
        let runloop = CFRunLoopGetMain()
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue, true, 0xffffff) { (observer, activity) in
            guard set.count != 0 else {
                return
            }
            let currentSet = set
            set = NSMutableSet()
            currentSet.enumerateObjects({ (object, stop) in
                if let job = object as? FreeTimeJob {
                   job.target?.perform(job.selector)
                }
            })
        }
        return runloop!
    }
    private weak var target: NSObject?
    private let selector: Selector
    init(target: NSObject, selector: Selector) {
        self.target = target
        self.selector = selector
    }
    
    func commit() {
        FreeTimeJob.setup()
        FreeTimeJob.set.add(self)
    }
}
