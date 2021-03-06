//
//  NSQueue.swift
//  GamingStreamsTVApp
//
//  Created by Olivier Boucher on 2015-09-20.

import Foundation

class Queue<T : Any> {
    fileprivate var array : [T]
    
    init() {
        array = [T]()
    }
    
    func offer(_ element : T) {
        array.append(element)
    }
    
    func poll() -> T? {
        var element : T? = nil
        if array.count > 0 {
            element = array.first
            array.removeFirst()
        }

        return element
    }
}
