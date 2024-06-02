//
//  ContentView.swift
//  video circles
//
//  Created by Michael Lee on 5/28/24.
//

import SwiftUI

struct ContentView: View {
    let minSize: CGFloat = 58
    let maxSize: CGFloat = 124
    let minSpeed: Double = 2.0
    let maxSpeed: Double = 6.0
    
    @State private var circlePositions: [CGPoint] = []
    @State private var circleColors: [Color] = []
    @State private var circleWidths: [CGFloat] = []
    @State private var circleSpeeds: [Double] = []
    @State private var touchLocation: CGPoint = .zero
    @State private var isTouching = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                ForEach(0..<circleColors.count, id: \.self) { index in
                    let circleSize = circleWidths[index]
                    let color = circleColors[index]
                    let speed = circleSpeeds[index]
                    
                    Circle()
                        .fill(color)
                        .frame(width: circleSize, height: circleSize)
                        .offset(x: circlePositions[index].x - geometry.size.width / 2, y: 0)
                        .animation(
                            Animation.linear(duration: speed)
                                .repeatForever(autoreverses: false),
                            value: circlePositions[index]
                        )
                        .position(isTouching ? touchLocation : CGPoint(x: geometry.size.width / 2, y: circlePositions[index].y))
                        .animation(.easeInOut(duration: 0.5), value: isTouching)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                touchLocation = location
                isTouching = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTouching = false
                }
            }
            .onAppear {
                setupCirclePositions(in: geometry.size)
                setupCircleColors()
                setupCircleWidths()
                setupCircleSpeeds()
                startAnimation(in: geometry.size)
            }
        }
    }
    
    private func setupCirclePositions(in size: CGSize) {
        circlePositions = (0..<10).map { _ in
            let x = -size.width / 2
            let y = CGFloat.random(in: 0...size.height)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func setupCircleColors() {
        circleColors = (0..<10).map { _ in
            Color(
                red: Double.random(in: 0...1),
                green: Double.random(in: 0...1),
                blue: Double.random(in: 0...1)
            )
        }
    }
    
    private func setupCircleWidths() {
        circleWidths = (0..<10).map { _ in
            CGFloat.random(in: minSize...maxSize)
        }
    }
    
    private func setupCircleSpeeds() {
        circleSpeeds = (0..<10).map { _ in
            Double.random(in: minSpeed...maxSpeed)
        }
    }
    
    private func startAnimation(in size: CGSize) {
        for index in 0..<circlePositions.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                withAnimation(Animation.linear(duration: circleSpeeds[index]).repeatForever(autoreverses: false)) {
                    circlePositions[index].x = size.width * 1.5
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
