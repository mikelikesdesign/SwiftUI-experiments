//
//  ContentView.swift
//  text animation
//
//  Created by Michael Lee on 1/25/25.
//


import SwiftUI

extension AnyTransition {
    static var vaporize: AnyTransition {
        .modifier(
            active: VaporizeModifier(progress: 1),
            identity: VaporizeModifier(progress: 0)
        )
    }
}

struct VaporizeModifier: ViewModifier {
    let progress: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1 + (progress * 0.5))
            .opacity(1 - progress)
    }
}

struct ContentView: View {
    enum DetailLevel: Double, CaseIterable {
        case simple = 0.5
        case detailed = 1.0
        case advanced = 1.5
    }
    
    @State private var currentDetailLevel: DetailLevel = .detailed
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var isPinching = false
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    private var simpleText = "Prototyping is a quick way to visualize ideas, test their functionality, and gather valuable feedback. It helps refine concepts and ensures the project is on the right track."
    private var detailedText = "Prototyping is essential for turning abstract ideas into concrete, interactive designs. It allows teams to identify potential issues early in the process. By presenting a prototype to users or stakeholders, teams can gather constructive feedback and ensure the product meets expectations. Prototyping also streamlines communication between designers, developers, and stakeholders, providing a shared vision of the project. Ultimately, it saves time and resources by clarifying the direction before diving into full scale development."
    private var advancedText = "Prototyping serves as a critical tool in the design and development lifecycle by offering a tangible representation of ideas. It transforms abstract concepts into interactive designs, making them easier to evaluate and refine. By catching potential design or functional issues in the early stages, prototyping significantly reduces the risk of building ineffective solutions. It also plays an important role in fostering collaboration and communication among teams, as it provides a clear visual reference that everyone can understand. Additionally, prototypes enable user testing and user feedback, ensuring the final product aligns with user needs and expectations. This iterative process not only increases the efficiency of development but also minimizes unnecessary expenses, making prototyping an invaluable step in delivering a successful product."
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    ForEach(DetailLevel.allCases, id: \.self) { level in
                        if level == currentDetailLevel {
                            Text(textForLevel(level))
                                .font(.system(.body, design: .rounded))
                                .padding()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(y: 20)),
                                    removal: .offset(y: -60)
                                        .combined(with: .vaporize)
                                        .combined(with: .opacity)
                                ))
                                .zIndex(level == currentDetailLevel ? 1 : 0)
                        }
                    }
                }
                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.7), value: currentDetailLevel)
                .clipped()
                .frame(maxWidth: .infinity, minHeight: 200, alignment: .top)
             }
             .padding()
            
            // Final indicator version
            VStack {
                Spacer()
                Text(currentDetailLevel.rawValue == 0.5 ? "Basic Overview" :
                     currentDetailLevel.rawValue == 1.0 ? "Detailed Analysis" :
                     "Advanced Analysis")
                    .textCase(.uppercase)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.quaternary, lineWidth: 0.5)
                    )
                    .foregroundStyle(.secondary)
                    .shadow(color: .black.opacity(isPinching ? 0.1 : 0), radius: isPinching ? 6 : 0, x: 0, y: 3)
                    .scaleEffect(isPinching ? 1.2 : 1)
                    .animation(.interpolatingSpring(stiffness: 200, damping: 20), value: isPinching)
                    .padding(.bottom, 24)
            }
        }
        .gesture(magnificationGesture)
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .updating($isPinching) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let clampedScale = min(max(value, 0.4), 1.6)
                let closestLevel = DetailLevel.allCases.min(by: {
                    abs($0.rawValue - clampedScale) < abs($1.rawValue - clampedScale)
                }) ?? .detailed
                
                if closestLevel != currentDetailLevel {
                    feedbackGenerator.impactOccurred()
                    withAnimation(.interactiveSpring) {
                        currentDetailLevel = closestLevel
                    }
                }
            }
    }
    
    private func textForLevel(_ level: DetailLevel) -> String {
        switch level {
        case .simple: return simpleText
        case .detailed: return detailedText
        case .advanced: return advancedText
        }
    }
}

#Preview {
    ContentView()
}
