//
//  BottomPagingTrigger.swift
//  FitSocial
//
//  Created by Dragan Kos on 28. 8. 2025..
//

import SwiftUI

public struct PagingTrigger: View {
    public let onVisible: () -> Void
    public var body: some View {
        Color.clear
            .frame(height: 1)
            .onAppear(perform: onVisible)
    }
}
