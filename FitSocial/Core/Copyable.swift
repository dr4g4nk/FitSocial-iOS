//
//  Copyable.swift
//  FitSocial
//
//  Created by Dragan Kos on 15. 8. 2025..
//

import Foundation

protocol Copyable {}
extension Copyable {
    func copy(_ update: (inout Self) -> Void) -> Self {
        var c = self
        update(&c)
        return c
    }
}
