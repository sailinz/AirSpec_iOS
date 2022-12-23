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

    @State private var showMyDataTimeView = false
    var body: some View {
        NavigationView{
            ZStack{
                VStack{
                    HStack{
                        Text("Place")
                            .font(.system(.subheadline) .weight(.semibold))
                        /// Toggle credit: https://toddhamilton.medium.com/prototype-a-custom-toggle-in-swiftui-d324941dac40
                        ZStack {
                            Capsule()
                                .frame(width:66,height:30)
                                .foregroundColor(Color(showMyDataTimeView ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1028798084) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6039008336)))
                            ZStack{
                                Circle()
                                    .frame(width:26, height:26)
                                    .foregroundColor(.white)
                                Image(systemName: showMyDataTimeView ? "timer" : "location.circle")
                            }
                            .shadow(color: .black.opacity(0.14), radius: 4, x: 0, y: 2)
                            .offset(x:showMyDataTimeView ? 18 : -18)
                            .padding(24)
                            .animation(.spring())
                        }
                        .onTapGesture {
                            self.showMyDataTimeView.toggle()
                        }
                        Text("Time")
                            .font(.system(.subheadline) .weight(.semibold))
                    }
//                    .padding()
//                    .offset(y:500)
                    
                    

                    switch showMyDataTimeView {
                        case true:
                            ScrollView{
                                MyDataTimeView()
                            }
                        case false:
                            ScrollView{
                                MyDataPlaceView()
                            }
                    }
                }
                
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
