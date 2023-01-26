//
//  BlurView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 20.01.23.
//

import SwiftUI
import UIKit

struct BlurView: UIViewRepresentable{
    func makeUIView(context: Context) -> some UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
