//
//  ContentView.swift
//  paper scrub
//
//  Created by Michael Lee on 9/13/24.
//

import SwiftUI
import CoreHaptics

struct ContentView: View {
    @State private var currentPage = 0
    @State private var isDragging = false
    @State private var stepperOpacity: Double = 0 // New state for stepper opacity
    @State private var opacity: Double = 1 // New state for fade effect
    @State private var engine: CHHapticEngine?
    @State private var lastHapticPage = 0
    @State private var lastDragPosition: CGFloat = 0

    let pageCount = 10
    
    let prototypingBenefits = [
        ("Rapid Iteration", "Prototyping allows for quick iterations, enabling teams to test and refine ideas rapidly. This accelerates the development process and leads to more polished final products."),
        ("Cost-Effective", "By identifying issues early, prototyping saves time and resources in the long run. It's much cheaper to fix problems in the prototype stage than after full development."),
        ("User-Centric Design", "Prototypes facilitate early user testing, ensuring that the final product meets user needs and expectations. This user-centric approach leads to better adoption and satisfaction."),
        ("Better Communication", "Prototypes serve as a common reference point for team members, stakeholders, and clients, reducing misunderstandings and aligning everyone's vision."),
        ("Team Inspiration", "Playing with prototypes brings excitement and inspiration to the team. It allows members to visualize the product's potential, sparking creativity and boosting morale throughout the development process."),
        ("Enhanced Creativity", "The prototyping process encourages experimentation and out-of-the-box thinking, often leading to innovative solutions that might not have been considered otherwise."),
        ("Faster Time-to-Market", "Prototyping can significantly reduce development time by validating concepts early and minimizing major revisions later in the process."),
        ("Stakeholder Buy-In", "Tangible prototypes make it easier to secure stakeholder approval and support, as they can see and interact with the proposed solution."),
        ("Feature Prioritization", "Through prototyping, teams can better understand which features are essential, helping to prioritize development efforts and resources."),
        ("Continuous Learning", "The iterative nature of prototyping fosters a culture of continuous learning and improvement within the development team.")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<10) { index in
                    VStack(spacing: 0) {
                        Image("photo_\(index + 1)")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                            .clipped()
                        
                        VStack(alignment: .leading, spacing: 12) { // Changed from 20 to 12
                            Text(prototypingBenefits[index].0)
                                .font(.custom("New York", size: 34))
                                .fontWeight(.bold)
                            
                            Text(prototypingBenefits[index].1)
                                .font(.body)
                                .foregroundColor(Color.gray.opacity(0.9))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .background(Color.white)
                    .opacity(currentPage == index ? opacity : 0)
                }
                
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(0..<10) { index in
                            RoundedRectangle(cornerRadius: 100)
                                .fill(index == currentPage ? Color(hex: 0x0500FF) : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 4)
                        }
                    }
                    .padding(.bottom, 20)
                    .opacity(stepperOpacity) // Use the new state variable for opacity
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let dragDistance = value.translation.width - lastDragPosition
                        let pageChangeThreshold: CGFloat = 50 // Adjust this value to change sensitivity
                        
                        if abs(dragDistance) > pageChangeThreshold {
                            let direction = dragDistance > 0 ? -1 : 1
                            let newPage = max(0, min(currentPage + direction, pageCount - 1))
                            
                            if newPage != currentPage {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentPage = newPage
                                    opacity = 1
                                }
                                
                                complexSuccess() // Trigger haptic feedback for each page change
                                lastDragPosition = value.translation.width
                            }
                        }
                        
                        // Fade in the stepper
                        withAnimation(.easeInOut(duration: 0.3)) {
                            stepperOpacity = 1
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        lastHapticPage = currentPage
                        lastDragPosition = 0
                        
                        // Fade out the stepper
                        withAnimation(.easeInOut(duration: 0.3)) {
                            stepperOpacity = 0
                        }
                    }
            )
        }
        .animation(.easeInOut(duration: 0.1), value: currentPage)
        .edgesIgnoringSafeArea(.top)
        .onAppear(perform: prepareHaptics)
    }

    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }

    func complexSuccess() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

#Preview {
    ContentView()
}
