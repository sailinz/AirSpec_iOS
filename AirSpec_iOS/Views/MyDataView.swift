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

    @State private var showMyDataTimeView = true
    
    var body: some View {
        ZStack{

            NavigationView{
                VStack{
                    ScrollView {
                        MyDataTimeView()
                    }
                }
                .navigationTitle("My data")
  
            }
            

        }
        
    }
}

struct MyDataView_Previews: PreviewProvider {
    static var previews: some View {
        MyDataView()
    }
}
