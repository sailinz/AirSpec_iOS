//
//  AirSpec_iOS_Watch_Complication.swift
//  AirSpec_iOS Watch Complication
//
//  Created by ZHONG Sailin on 09.01.23.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
        return [
            IntentRecommendation(intent: ConfigurationIntent(), description: "AirSpec")
        ]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct AirSpec_iOS_Watch_ComplicationEntryView : View {
    var entry: Provider.Entry

    var body: some View {
//        Text(entry.date, style: .time)
        ZStack {
            Color.white
            
//            Image("Icon_64px")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 40, height: 40)
            Text("AirSpec")
                .font(.system(.footnote))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .scaledToFit()
        }
        
//        Image("Icon_64px")
//            .resizable()
//            .scaledToFit()
//            .frame(width: 50, height: 50)

            
//            .frame(width:50, height:50)
    }
}

@main
struct AirSpec_iOS_Watch_Complication: Widget {
    let kind: String = "AirSpec_iOS_Watch_Complication"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            AirSpec_iOS_Watch_ComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("AirSpec")
        .description("Open AirSpec")
    }
}

struct AirSpec_iOS_Watch_Complication_Previews: PreviewProvider {
    static var previews: some View {
        AirSpec_iOS_Watch_ComplicationEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
