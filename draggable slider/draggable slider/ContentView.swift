//
//  ContentView.swift
//  draggable slider
//
//  Created by Michael Lee on 5/9/25.
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
    enum DetailLevel: String, CaseIterable {
        case simpleAndCasual = "Simple & Casual"
        case simpleAndFormal = "Simple & Formal"
        case advancedAndCasual = "Advanced & Casual"
        case advancedAndFormal = "Advanced & Formal"
    }
    
    @State private var currentDetailLevel: DetailLevel = .simpleAndCasual
    @State private var showingSlider = false
    @State private var sliderPosition: CGPoint = .zero
    @State private var sliderOffset: CGSize = .zero
    @State private var sliderAccumulatedOffset: CGSize = .zero
    @State private var trackpadRotation: (x: CGFloat, y: CGFloat) = (0, 0)
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let trackpadSize: CGFloat = 240
    private let knobSize: CGFloat = 30
    
    private var simpleAndCasualText = "Think of prototyping like a quick test drive for your ideas. You make a simple version, show it around, and use the feedback to make it better."
    private var simpleAndFormalText = "Prototyping facilitates the early visualization of concepts, enabling testing of functionality and the collection of actionable feedback. This iterative process is essential for refining ideas."
    private var advancedAndCasualText = "Prototyping helps you get your ideas out there fast. You build something, try it out, and get real feedback so you can keep improving your ideas."
    private var advancedAndFormalText = "Prototyping is a fast and helpful way to turn ideas into something you can see and try out. It lets you figure out what works and gather feedback in helping to shape a better design."
    
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
                                .contentShape(Rectangle())
                                .onLongPressGesture(minimumDuration: 0.2) {
                                    feedbackGenerator.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showingSlider = true
                                    }
                                }
                        }
                    }
                }
                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.7), value: currentDetailLevel)
                .clipped()
                .frame(maxWidth: .infinity, minHeight: 200, alignment: .top)
             }
             .padding()
             
            ZStack {
                if showingSlider {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                showingSlider = false
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                sliderOffset = .zero
                                sliderAccumulatedOffset = .zero
                            }
                        }
                    
                    VStack {
                        Spacer()
                        
                        QuadrantSlider(
                            position: $sliderPosition,
                            onPositionChanged: { position in
                                updateDetailLevel(position: position)
                            },
                            trackpadSize: trackpadSize,
                            knobSize: knobSize,
                            topLabel: "Simple",
                            bottomLabel: "Advanced",
                            leftLabel: "Casual",
                            rightLabel: "Formal",
                            currentDetailLevel: $currentDetailLevel
                        )
                        .frame(width: trackpadSize, height: trackpadSize)
                        .offset(x: sliderAccumulatedOffset.width + sliderOffset.width,
                                y: sliderAccumulatedOffset.height + sliderOffset.height)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    sliderOffset = value.translation
                                }
                                .onEnded { value in
                                    sliderAccumulatedOffset = CGSize(
                                        width: sliderAccumulatedOffset.width + value.translation.width,
                                        height: sliderAccumulatedOffset.height + value.translation.height
                                    )
                                    sliderOffset = .zero
                                }
                        )
                    }
                    .padding(.bottom, 50)
                    .transition(.scale(scale: 0.1, anchor: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showingSlider)
                }
            }
        }
    }
    
    private func updateDetailLevel(position: CGPoint) {
        feedbackGenerator.impactOccurred()
    }
    
    private func textForLevel(_ level: DetailLevel) -> String {
        switch level {
        case .simpleAndCasual: return simpleAndCasualText
        case .simpleAndFormal: return simpleAndFormalText
        case .advancedAndCasual: return advancedAndCasualText
        case .advancedAndFormal: return advancedAndFormalText
        }
    }
}

struct QuadrantSlider: View {
    @Binding var position: CGPoint
    var onPositionChanged: (CGPoint) -> Void
    var trackpadSize: CGFloat
    var knobSize: CGFloat
    var topLabel: String
    var bottomLabel: String
    var leftLabel: String
    var rightLabel: String
    @Binding var currentDetailLevel: ContentView.DetailLevel
    
    @State private var isKnobEnlarged: Bool = false
    @State private var tempPosition: CGPoint? = nil
    @State private var knobDragOffset: CGSize = .zero
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    private let topLeftColor = Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.7)
    private let topRightColor = Color(red: 0.6, green: 0.2, blue: 0.8).opacity(0.7)
    private let bottomLeftColor = Color(red: 0.0, green: 0.8, blue: 0.8).opacity(0.7)
    private let bottomRightColor = Color(red: 0.4, green: 0.8, blue: 0.2).opacity(0.7)
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            getColorForPosition((tempPosition ?? position)),
                            Color(UIColor.secondarySystemBackground)
                        ]),
                        center: UnitPoint(
                            x: (tempPosition ?? position).x / trackpadSize,
                            y: (tempPosition ?? position).y / trackpadSize
                        ),
                        startRadius: 0,
                        endRadius: trackpadSize * 0.7
                    )
                    .opacity(0.8)
                    
                    Path { path in
                        path.move(to: CGPoint(x: geo.size.width/2, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width/2, y: geo.size.height))
                        
                        path.move(to: CGPoint(x: 0, y: geo.size.height/2))
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height/2))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    
                    VStack {
                        Text(topLabel)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(currentDetailLevel == .simpleAndCasual || currentDetailLevel == .simpleAndFormal ? .primary : .gray)
                            .padding(.top, 12)
                        Spacer()
                        Text(bottomLabel)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(currentDetailLevel == .advancedAndCasual || currentDetailLevel == .advancedAndFormal ? .primary : .gray)
                            .padding(.bottom, 12)
                    }
                    
                    HStack {
                        RotatedText(text: leftLabel, angle: -90)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(currentDetailLevel == .simpleAndCasual || currentDetailLevel == .advancedAndCasual ? .primary : .gray)
                            .padding(.leading, 12)
                        Spacer()
                        RotatedText(text: rightLabel, angle: 90)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(currentDetailLevel == .simpleAndFormal || currentDetailLevel == .advancedAndFormal ? .primary : .gray)
                            .padding(.trailing, 12)
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .animation(.easeOut(duration: 0.15), value: currentDetailLevel)
            }
            
            .rotation3DEffect(
                .degrees(Double(knobDragOffset.height / 15)),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(Double(-knobDragOffset.width / 15)),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: knobDragOffset)
            
            Circle()
                .fill(Color.white)
                .frame(
                    width: isKnobEnlarged ? knobSize * 1.6 : knobSize,
                    height: isKnobEnlarged ? knobSize * 1.6 : knobSize
                )
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                .position(
                    x: (tempPosition ?? position).x == 0 ? trackpadSize/2 : (tempPosition ?? position).x,
                    y: (tempPosition ?? position).y == 0 ? trackpadSize/2 : (tempPosition ?? position).y
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newPosition = CGPoint(
                                x: min(max(value.location.x, knobSize/2), trackpadSize - knobSize/2),
                                y: min(max(value.location.y, knobSize/2), trackpadSize - knobSize/2)
                            )
                            
                            knobDragOffset = value.translation
                            
                            tempPosition = newPosition
                            updateDetailLevelForPosition(newPosition)
                            
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                isKnobEnlarged = true
                            }
                        }
                        .onEnded { value in
                            if let finalPosition = tempPosition {
                                position = finalPosition
                                onPositionChanged(finalPosition)
                            }
                            tempPosition = nil
                            knobDragOffset = .zero
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isKnobEnlarged = false
                            }
                        }
                )
        }
        .onAppear {
            if position.x == 0 && position.y == 0 {
                initializePositionForDetailLevel()
            }
        }
    }
    
    private func getColorForPosition(_ position: CGPoint) -> Color {
        let normalizedX = position.x / trackpadSize
        let normalizedY = position.y / trackpadSize
        
        let topColor = topLeftColor.interpolated(to: topRightColor, amount: normalizedX)
        let bottomColor = bottomLeftColor.interpolated(to: bottomRightColor, amount: normalizedX)
        let finalColor = topColor.interpolated(to: bottomColor, amount: normalizedY)
        
        return finalColor
    }
    
    private func initializePositionForDetailLevel() {
        let x: CGFloat
        let y: CGFloat
        
        switch currentDetailLevel {
        case .simpleAndCasual:
            x = trackpadSize/4 * 0.8
            y = trackpadSize/4 * 0.8
        case .simpleAndFormal:
            x = trackpadSize/4 * 3.2
            y = trackpadSize/4 * 0.8
        case .advancedAndCasual:
            x = trackpadSize/4 * 0.8
            y = trackpadSize/4 * 3.2
        case .advancedAndFormal:
            x = trackpadSize/4 * 3.2
            y = trackpadSize/4 * 3.2
        }
        
        position = CGPoint(x: x, y: y)
    }
    
    private func updateDetailLevelForPosition(_ position: CGPoint) {
        let normalizedX = position.x / trackpadSize
        let normalizedY = position.y / trackpadSize
        
        let previousLevel = currentDetailLevel
        
        if normalizedY < 0.5 {
            if normalizedX < 0.5 {
                currentDetailLevel = .simpleAndCasual
            } else {
                currentDetailLevel = .simpleAndFormal
            }
        } else {
            if normalizedX < 0.5 {
                currentDetailLevel = .advancedAndCasual
            } else {
                currentDetailLevel = .advancedAndFormal
            }
        }
        
        if previousLevel != currentDetailLevel {
            feedbackGenerator.impactOccurred(intensity: 0.7)
        }
    }
}

extension Color {
    func interpolated(to other: Color, amount: CGFloat) -> Color {
        let bounded = min(max(amount, 0), 1)
        
        return Color.blend(from: self, to: other, amount: bounded)
    }
    
    static func blend(from: Color, to: Color, amount: CGFloat) -> Color {
        let percent = min(max(amount, 0.0), 1.0)
        
        return Color(red:
                     UIColor(from).redComponent * (1.0 - percent) + UIColor(to).redComponent * percent,
                     green:
                     UIColor(from).greenComponent * (1.0 - percent) + UIColor(to).greenComponent * percent,
                     blue:
                     UIColor(from).blueComponent * (1.0 - percent) + UIColor(to).blueComponent * percent,
                     opacity:
                     UIColor(from).alphaComponent * (1.0 - percent) + UIColor(to).alphaComponent * percent)
    }
}

extension UIColor {
    var redComponent: CGFloat {
        var red: CGFloat = 0
        getRed(&red, green: nil, blue: nil, alpha: nil)
        return red
    }
    
    var greenComponent: CGFloat {
        var green: CGFloat = 0
        getRed(nil, green: &green, blue: nil, alpha: nil)
        return green
    }
    
    var blueComponent: CGFloat {
        var blue: CGFloat = 0
        getRed(nil, green: nil, blue: &blue, alpha: nil)
        return blue
    }
    
    var alphaComponent: CGFloat {
        var alpha: CGFloat = 0
        getRed(nil, green: nil, blue: nil, alpha: &alpha)
        return alpha
    }
}

struct RotatedText: View {
    let text: String
    let angle: Double
    
    var body: some View {
        Text(text)
            .rotationEffect(.degrees(angle))
            .fixedSize()
            .frame(width: 20)
    }
}

#Preview {
    ContentView()
}


