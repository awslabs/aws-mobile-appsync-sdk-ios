//
//  Object+Swizzling.swift
//  AWSAppSync
//
//  Created by Mario Araujo on 11/07/2018.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import Foundation


func setAssociatedObject<T>(object: AnyObject, value: T, associativeKey: UnsafeRawPointer, policy: objc_AssociationPolicy) {
    objc_setAssociatedObject(object, associativeKey, value,  policy)
}

func getAssociatedObject<T>(object: AnyObject, associativeKey: UnsafeRawPointer) -> T? {
    guard let value = objc_getAssociatedObject(object, associativeKey) as? T else {
        return nil
    }
    return value
}

extension NSObject {
    private struct AssociatedKey {
        static var swizzledMethodsRestorations = "swizzledMethodsRestorations"
    }
    
    @objc class var swizzledMethodsRestorations: NSMutableArray? {
        get {
            return getAssociatedObject(object: self, associativeKey: &AssociatedKey.swizzledMethodsRestorations)
        }
        
        set {
            if let value = newValue {
                setAssociatedObject(object: self, value: value, associativeKey: &AssociatedKey.swizzledMethodsRestorations, policy: objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    @objc static func swizzle(selector: Selector, withBlock block: Any) {
        guard let originalMethod = class_getInstanceMethod(self, selector) else {
            return
        }
        
        let swizzledBlock = imp_implementationWithBlock(block)
        
        let newMethod = method_setImplementation(originalMethod, swizzledBlock)
        
        let block: () -> Void = {
            method_setImplementation(originalMethod, newMethod)
        }
        
        if let array = self.swizzledMethodsRestorations {
            array.add(block)
        } else {
            self.swizzledMethodsRestorations = NSMutableArray(array: [block])
        }
    }
    
    @objc static func restoreSwizzledMethods() {
        if let array = self.swizzledMethodsRestorations {
            array.forEach { (object) in
                if let block = object as? () -> Void {
                    block()
                }
            }
            array.removeAllObjects()
        }
    }
}
