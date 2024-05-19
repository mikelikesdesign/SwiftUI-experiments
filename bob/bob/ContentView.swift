//
//  ContentView.swift
//  bob
//
//  Created by Michael Lee on 5/11/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var isExpanded = false
    @State private var showContent = false
    @State private var fadeInContent = false
    @State private var position = CGPoint(x: 40, y: 40)  // Start at top left
    @State private var timer: AnyCancellable?
    @State private var showSummary = false

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                if !isExpanded && !showContent && !showSummary {
                    Group {
                        Text("Prototyping is a crucial step in the design process that offers numerous benefits. It allows designers and developers to quickly visualize and test their ideas, gather valuable feedback from users, and iterate on their designs before investing significant time and resources into development.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("One of the key advantages of prototyping is that it enables early validation of design concepts. By creating interactive prototypes, designers can simulate the user experience and identify potential usability issues, design flaws, or areas for improvement.")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(8)
                    .padding(.bottom, 10)
                    
                    Group {
                        Text("Prototyping also facilitates effective communication and collaboration among team members. It provides a tangible artifact that can be shared, discussed, and iterated upon.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Moreover, prototyping saves time and resources in the long run. By identifying and addressing issues early in the design process, teams can avoid costly mistakes and rework later in the development phase.")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(8)
                }
            }
            .padding()
            
            YellowCircleAndBobView(isExpanded: $isExpanded, showContent: $showContent, position: $position, triggerAnimation: triggerAnimation)
            
            if showContent {
                ExpandedView(isExpanded: $isExpanded, showContent: $showContent, fadeInContent: $fadeInContent, onClose: startRandomMovement)
                    .opacity(fadeInContent ? 1 : 0)
                    .transition(.opacity)
            }

            if showSummary {
                SummaryView(isExpanded: $isExpanded, showSummary: $showSummary)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // No random movement initially
        }
        .onDisappear {
            stopRandomMovement()
        }
    }
    
    private func triggerAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.35)) {
            isExpanded.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeIn(duration: 0.2)) {
                showContent = true
                fadeInContent = true
                stopRandomMovement()
            }
        }
    }
    
    private func startRandomMovement() {
        timer?.cancel()
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(Animation.easeInOut(duration: 2.0)) {
                    position = randomPosition()
                }
            }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            timer?.cancel()
            withAnimation(Animation.easeInOut(duration: 0.35)) {
                isExpanded = true
                showSummary = true
            }
        }
    }
    
    private func stopRandomMovement() {
        timer?.cancel()
    }
    
    private func randomPosition() -> CGPoint {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let componentWidth: CGFloat = 20 + 8 + 40 // Circle width + Spacing + "Bob" text width estimate
        let componentHeight: CGFloat = 20 // Circle height

        let x = CGFloat.random(in: componentWidth / 2...(width - componentWidth / 2))
        let y = CGFloat.random(in: componentHeight / 2...(height - componentHeight / 2))
        
        return CGPoint(x: x, y: y)
    }
}

struct YellowCircleAndBobView: View {
    @Binding var isExpanded: Bool
    @Binding var showContent: Bool
    @Binding var position: CGPoint
    var triggerAnimation: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: "FCFF7B"))
                .frame(width: 20, height: 20)
                .onTapGesture {
                    triggerAnimation()
                }
                .overlay(
                    GeometryReader { geometry in
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FCFF7B"))
                                .frame(width: isExpanded ? max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 2 : 0, height: isExpanded ? max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 2 : 0)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                )
            
            if !isExpanded && !showContent {
                Text("Bob")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .onTapGesture {
                        triggerAnimation()
                    }
            }
        }
        .position(position)
    }
}

struct ExpandedView: View {
    @Binding var isExpanded: Bool
    @Binding var showContent: Bool
    @Binding var fadeInContent: Bool
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color(hex: "FCFF7B")
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .center, spacing: 16) {
                Spacer()
                
                Text("Summarize content")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        closeExpandedView()
                    }
                
                Text("Provide related content")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("Share content")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                Image("close component")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .onTapGesture {
                        closeExpandedView()
                    }
            }
            .padding()
        }
    }
    
    private func closeExpandedView() {
        withAnimation(.easeOut(duration: 0.2)) {
            fadeInContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showContent = false
            withAnimation(Animation.easeInOut(duration: 0.35)) {
                isExpanded = false
                onClose()
            }
        }
    }
}

struct SummaryView: View {
    @Binding var isExpanded: Bool
    @Binding var showSummary: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "FCFF7B")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 16) {
                    Spacer()
                    
                    Text("Summary of Content")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 20)
                    
                    Text("Prototyping is a crucial step in the design process that offers numerous benefits. It allows designers and developers to quickly visualize and test their ideas, gather valuable feedback from users, and iterate on their designs before investing significant time and resources into development. One of the key advantages of prototyping is that it enables early validation of design concepts. By creating interactive prototypes, designers can simulate the user experience and identify potential usability issues, design flaws, or areas for improvement.")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 20)
                        .lineSpacing(8)
                    
                    Spacer()
                }
                .padding()
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("close component")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showSummary = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    withAnimation(Animation.easeInOut(duration: 0.35)) {
                                        isExpanded = false
                                    }
                                }
                            }
                        Spacer()
                    }
                    .padding(.bottom, 20) // Adjust the padding as needed
                }
                .frame(height: geometry.size.height)
            }
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
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
