////
////  PieChart.swift
////  AirSpec_iOS
////
////  Created by ZHONG Sailin on 22.12.22.
////
//
//struct PieChart: View {
//    var data: [(value: Double, color: Color)]
//
//    var body: some View {
//        ZStack {
//            ForEach(0..<data.count) { index in
//                Capsule()
//                    .fill(self.data[index].color)
//                    .frame(width: 15, height: 15)
//                    .offset(x: -75, y: -60 + 20 * index)
//            }
//
//            PieChartShape(data: data)
//                .fill(Color.white)
//                .frame(width: 150, height: 150)
//                .offset(x: -75, y: -75)
//        }
//    }
//}
//
//struct PieChartShape: Shape {
//    var data: [(value: Double, color: Color)]
//
//    func path(in rect: CGRect) -> Path {
//        let total = data.reduce(0) { $0 + $1.value }
//        var start: Double = 0
//
//        var path = Path()
//        for slice in data {
//            let end = start + slice.value / total * 360
//            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
//                        radius: rect.width / 2,
//                        startAngle: Angle(degrees: start),
//                        endAngle: Angle(degrees: end),
//                        clockwise: false)
//            start = end
//        }
//
//        return path
//    }
//}
