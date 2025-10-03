//
//  PreviewView.swift
//  BasicAVCamera
//
//  Created by Itsuki on 2024/05/19.
//

import SwiftUI

struct PreviewView: View {
    @Environment(CameraModel.self) var model: CameraModel
    @State private var isRecording: Bool = false

    private let footerHeight: CGFloat = 110.0

    var body: some View {
        
        ImageView(image: model.previewImage )
            .padding(.bottom, footerHeight)
            .padding(.top, 40)
            .background(Color.black)

    }
}

#Preview {
    @Previewable @State var model = CameraModel()
//    model.photoToken = Image(systemName: "checkmark")

//    CameraView()
    PreviewView()
        .environment(model)
}
