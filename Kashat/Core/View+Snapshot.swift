//
//  View+Snapshot.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 31/01/2026.
//

import SwiftUI

extension View {
    @MainActor
    func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
