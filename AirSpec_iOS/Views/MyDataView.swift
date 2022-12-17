//
//  MyDataView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 08.12.22.
//

//import SwiftUI
//
//struct MyDataView: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
//
//struct MyDataView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyDataView()
//    }
//}

import SwiftUI

struct MyDataView: View {
    var body: some View {
        NavigationView{
            ZStack{
                Text("my data placeholder")
//                Rectangle()
//                    .fill(Gradient(colors: [.black, .indigo]))
//                    .ignoresSafeArea()
                
            }
            .navigationTitle("My data")
        }
    }
}

struct MyDataView_Previews: PreviewProvider {
    static var previews: some View {
        MyDataView()
    }
}
