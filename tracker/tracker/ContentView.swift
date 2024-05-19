//
//  ContentView.swift
//  tracker
//
//  Created by Michael Lee on 5/19/24.
//

import SwiftUI

struct Activity: Identifiable, Equatable {
    let id: UUID
    let time: String
    let emoji: String
}

struct ContentView: View {
    @State private var activities: [Activity] = []
    
    let emojis = ["💩", "💦", "🍼", "😴", "🛝"]
    
    var body: some View {
        ZStack {
            VStack {
                Text(Date(), style: .date)
                    .font(.system(size: 24, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                
                List {
                    ForEach(activities) { activity in
                        HStack {
                            Text(activity.time)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#818181")) // Updated color
                            Spacer()
                            Text(activity.emoji)
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8) // Adding 8px padding to separate items
                        .background(Color.white) // Ensure each item has a white background
                        .cornerRadius(10)
                        .listRowInsets(EdgeInsets()) // Remove default padding
                        .listRowBackground(Color.clear) // Remove list row background to eliminate lines
                        .transition(.move(edge: .bottom).combined(with: .opacity)) // Adding transition
                    }
                    .onDelete(perform: deleteActivity)
                }
                .listStyle(PlainListStyle()) // Use plain list style to keep the background color consistent
                .animation(.easeIn(duration: 0.2), value: activities) // Adding animation
                
                Spacer()
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            
            VStack {
                Spacer()
                HStack(alignment: .top, spacing: 16) {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 32))
                            .onTapGesture {
                                addActivity(emoji: emoji)
                            }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(100)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .inset(by: 0.5)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .padding(.bottom, 40)
            }
            .edgesIgnoringSafeArea(.bottom) // Ensure the bottom component is 40px from the screen bottom
        }
    }
    
    func addActivity(emoji: String) {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: Date())
        withAnimation {
            activities.append(Activity(id: UUID(), time: timeString, emoji: emoji))
        }
    }
    
    func deleteActivity(at offsets: IndexSet) {
        withAnimation {
            activities.remove(atOffsets: offsets)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8 * 17) & 0xF, (int >> 4 * 17) & 0xF, (int * 17) & 0xF)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
