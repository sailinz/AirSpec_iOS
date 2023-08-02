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
    @Binding var flags: [Bool]
    
    var body: some View {
        ZStack{

            NavigationView{
                VStack{
                    ScrollView {
                        MyDataTimeView(flags: $flags)
                    }
                }
                .navigationTitle("My data")
  
            }
            

        }
        
    }
}

struct MyDataView_Previews: PreviewProvider {
    struct MyDataViewWrapper: View {

            @State var flags : [Bool] = Array(repeating: false, count: 12)
            var body: some View {
                MyDataView(flags: $flags)
            }
        }
    static var previews: some View {
        MyDataViewWrapper()
    }
}
