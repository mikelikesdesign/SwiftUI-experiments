//
//  ContentView.swift
//  text alignment
//
//  Created by @mikelikesdesign on 11/28/25.
//

import SwiftUI

struct ContentView: View {
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    private let alignmentThreshold: CGFloat = 24
    private let snapThreshold: CGFloat = 2
    private let snapDistance: CGFloat = 8
    
    @State private var textSize: CGSize = .zero
    
    @State private var isAlignedTop: Bool = false
    @State private var isAlignedBottom: Bool = false
    @State private var isAlignedLeft: Bool = false
    @State private var isAlignedRight: Bool = false
    @State private var isAlignedCenter: Bool = false
    @State private var isAlignedMiddle: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let centerX = screenWidth / 2
            let centerY = screenHeight / 2
            
            let textX = centerX + offset.width
            let textY = centerY + offset.height
            
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                Group {
                    let textTopEdge = textY - textSize.height / 2
                    let distTop = abs(textTopEdge - 72)
                    
                    Rectangle()
                        .fill(guideColor(distance: distTop))
                        .frame(height: 1)
                        .position(x: centerX, y: 72)
                        .opacity(guideOpacity(distance: distTop))
                    
                    let textBottomEdge = textY + textSize.height / 2
                    let distBottom = abs(textBottomEdge - (screenHeight - 72))
                    
                    Rectangle()
                        .fill(guideColor(distance: distBottom))
                        .frame(height: 1)
                        .position(x: centerX, y: screenHeight - 72)
                        .opacity(guideOpacity(distance: distBottom))
                    
                    let textLeftEdge = textX - textSize.width / 2
                    let distLeft = abs(textLeftEdge - 24)
                    
                    Rectangle()
                        .fill(guideColor(distance: distLeft))
                        .frame(width: 1)
                        .position(x: 24, y: centerY)
                        .opacity(guideOpacity(distance: distLeft))
                    
                    let textRightEdge = textX + textSize.width / 2
                    let distRight = abs(textRightEdge - (screenWidth - 24))
                    
                    Rectangle()
                        .fill(guideColor(distance: distRight))
                        .frame(width: 1)
                        .position(x: screenWidth - 24, y: centerY)
                        .opacity(guideOpacity(distance: distRight))
                }
                .ignoresSafeArea()
                
                if isDragging || abs(offset.width) < alignmentThreshold {
                    Rectangle()
                        .fill(verticalLineColor)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .opacity(verticalLineOpacity)
                        .animation(.easeOut(duration: 0.3), value: isDragging)
                }
                
                if isDragging || abs(offset.height) < alignmentThreshold {
                    Rectangle()
                        .fill(horizontalLineColor)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .opacity(horizontalLineOpacity)
                        .animation(.easeOut(duration: 0.3), value: isDragging)
                }
                
                Text("design details")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear
                                .onAppear {
                                    textSize = textGeo.size
                                }
                                .onChange(of: textGeo.size) { _, newSize in
                                    textSize = newSize
                                }
                        }
                    )
                    .offset(offset)
                    .sensoryFeedback(.impact(weight: .medium), trigger: isAlignedTop)
                    .sensoryFeedback(.impact(weight: .medium), trigger: isAlignedBottom)
                    .sensoryFeedback(.impact(weight: .medium), trigger: isAlignedLeft)
                    .sensoryFeedback(.impact(weight: .medium), trigger: isAlignedRight)
                    .sensoryFeedback(.impact(weight: .medium), trigger: isAlignedCenter)
                    .sensoryFeedback(.impact(weight: .medium), trigger: isAlignedMiddle)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let baseOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                let snappedOffset = snapOffset(for: baseOffset, screenWidth: screenWidth, screenHeight: screenHeight)
                                
                                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                                    isDragging = true
                                    offset = snappedOffset
                                }
                                
                                let currentTextX = centerX + snappedOffset.width
                                let currentTextY = centerY + snappedOffset.height
                                
                                let topDist = abs((currentTextY - textSize.height / 2) - 72)
                                checkAlignment(distance: topDist, state: &isAlignedTop)
                                
                                let bottomDist = abs((currentTextY + textSize.height / 2) - (screenHeight - 72))
                                checkAlignment(distance: bottomDist, state: &isAlignedBottom)
                                
                                let leftDist = abs((currentTextX - textSize.width / 2) - 24)
                                checkAlignment(distance: leftDist, state: &isAlignedLeft)
                                
                                let rightDist = abs((currentTextX + textSize.width / 2) - (screenWidth - 24))
                                checkAlignment(distance: rightDist, state: &isAlignedRight)
                                
                                let centerDist = abs(snappedOffset.width)
                                checkAlignment(distance: centerDist, state: &isAlignedCenter)
                                
                                let middleDist = abs(snappedOffset.height)
                                checkAlignment(distance: middleDist, state: &isAlignedMiddle)
                            }
                            .onEnded { _ in
                                let snappedOffset = snapOffset(for: offset, screenWidth: screenWidth, screenHeight: screenHeight)
                                
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    isDragging = false
                                    offset = snappedOffset
                                }
                                lastOffset = snappedOffset
                                
                                isAlignedTop = false
                                isAlignedBottom = false
                                isAlignedLeft = false
                                isAlignedRight = false
                                isAlignedCenter = false
                                isAlignedMiddle = false
                            }
                    )
            }
        }
        .ignoresSafeArea()
    }
    
    private func snapOffset(for baseOffset: CGSize, screenWidth: CGFloat, screenHeight: CGFloat) -> CGSize {
        var snappedOffset = baseOffset
        
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2
        
        var widthCandidates: [(distance: CGFloat, snapped: CGFloat)] = [
            (abs(baseOffset.width), 0)
        ]
        var heightCandidates: [(distance: CGFloat, snapped: CGFloat)] = [
            (abs(baseOffset.height), 0)
        ]
        
        if textSize.width > 0 && textSize.height > 0 {
            let textX = centerX + baseOffset.width
            let textY = centerY + baseOffset.height
            
            let leftDist = abs((textX - textSize.width / 2) - 24)
            widthCandidates.append((leftDist, (24 + textSize.width / 2) - centerX))
            
            let rightDist = abs((textX + textSize.width / 2) - (screenWidth - 24))
            widthCandidates.append((rightDist, (screenWidth - 24 - textSize.width / 2) - centerX))
            
            let topDist = abs((textY - textSize.height / 2) - 72)
            heightCandidates.append((topDist, (72 + textSize.height / 2) - centerY))
            
            let bottomDist = abs((textY + textSize.height / 2) - (screenHeight - 72))
            heightCandidates.append((bottomDist, (screenHeight - 72 - textSize.height / 2) - centerY))
        }
        
        if let bestWidth = widthCandidates.filter({ $0.distance < snapDistance }).min(by: { $0.distance < $1.distance }) {
            snappedOffset.width = bestWidth.snapped
        }
        
        if let bestHeight = heightCandidates.filter({ $0.distance < snapDistance }).min(by: { $0.distance < $1.distance }) {
            snappedOffset.height = bestHeight.snapped
        }
        
        return snappedOffset
    }
    
    private func checkAlignment(distance: CGFloat, state: inout Bool) {
        if distance < snapThreshold {
            if !state {
                state = true
            }
        } else {
            state = false
        }
    }
    
    private func guideOpacity(distance: CGFloat) -> Double {
        if !isDragging { return 0 }
        if distance > alignmentThreshold { return 0 }
        return 1 - (distance / alignmentThreshold)
    }
    
    private func guideColor(distance: CGFloat) -> Color {
        distance < snapThreshold ? .blue : .white
    }
    
    private var distanceFromCenterX: CGFloat {
        abs(offset.width)
    }
    
    private var distanceFromCenterY: CGFloat {
        abs(offset.height)
    }
    
    private var isCenteredX: Bool {
        distanceFromCenterX < snapThreshold
    }
    
    private var isCenteredY: Bool {
        distanceFromCenterY < snapThreshold
    }
    
    private var verticalLineColor: Color {
        isCenteredX ? .blue : .white
    }
    
    private var horizontalLineColor: Color {
        isCenteredY ? .blue : .white
    }
    
    private var verticalLineOpacity: Double {
        if !isDragging { return 0 }
        
        if distanceFromCenterX > alignmentThreshold {
            return 0
        }
        
        return 1 - (distanceFromCenterX / alignmentThreshold)
    }
    
    private var horizontalLineOpacity: Double {
        if !isDragging { return 0 }
        
        if distanceFromCenterY > alignmentThreshold {
            return 0
        }
        
        return 1 - (distanceFromCenterY / alignmentThreshold)
    }
}

#Preview {
    ContentView()
}
