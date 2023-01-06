//
//  PopUpView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 05.01.23.
//

import Foundation
import SwiftUI

struct PopUpView: View {
    @Binding var isPresenting: Bool

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)){
            VStack(spacing:25){
                Image("cozie_216")
                    .cornerRadius(5)
                
                Text("Answer Cozie survey on your Apple watch")
                
                Button(action:{
                    withAnimation{
                        isPresenting.toggle()
                    }
                }){
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.pink)
                }
                
                
            }
        }
    }
}


