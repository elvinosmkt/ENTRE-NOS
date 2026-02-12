//
//  EntreNosWidget.swift
//  Runner
//
//  Created by EntreNós on 2024.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), image: UIImage(systemName: "heart.fill"), text: "Amor")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), image: UIImage(systemName: "heart.fill"), text: "Snapshot")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Fetch data from App Group
        let userDefaults = UserDefaults(suiteName: "group.com.entrenos.app")
        let text = userDefaults?.string(forKey: "text") ?? "No message"
        
        // In a real app, we would load the image from the shared container URL
        // let imagePath = ...
        // let image = UIImage(contentsOfFile: imagePath)
        
        let entry = SimpleEntry(date: Date(), image: nil, text: text)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let text: String
}

struct EntreNosWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Background
            Color.white // Use white background for the clean look
            
            // Subtle Gradient Blob
            GeometryReader { geo in
                Circle()
                    .fill(Color(red: 1.0, green: 0.3, blue: 0.64).opacity(0.1))
                    .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.1)
            }
            
            if let uiImage = entry.image {
                 Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(ContainerRelativeShape())
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.64)) // Primary Pink
                        .shadow(color: Color(red: 1.0, green: 0.3, blue: 0.64).opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    Text(entry.text)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            
            // Branding (Optional)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "heart.circle.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.64).opacity(0.5))
                        .font(.system(size: 10))
                }
            }
            .padding(8)
        }
    }
}

@main
struct EntreNosWidget: Widget {
    let kind: String = "EntreNosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EntreNosWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("EntreNós")
        .description("Sua conexão diária.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
