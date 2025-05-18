//
//  ContentView.swift
//  tilt grid
//
//  Created by Michael Lee on 5/18/25.
//

import SwiftUI
import CoreMotion

struct Card: Identifiable {
    let id = UUID()
    let color: Color
}

struct ContentView: View {
    @State private var cards: [Card] = (0..<50).map { _ in
        Card(color: Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        ))
    }
    
    @State private var tiltX: CGFloat = 0
    @State private var tiltY: CGFloat = 0
    @State private var scrollOffset: CGPoint = .zero
    private let motionManager = CMMotionManager()
    private let gridWidth: CGFloat = 5 * 210
    private let gridHeight: CGFloat = 10 * 310
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        
                        Color.clear
                            .frame(width: gridWidth, height: gridHeight)
                        
                        LazyVStack(spacing: 10) {
                            ForEach(0..<10) { row in
                                LazyHStack(spacing: 10) {
                                    ForEach(0..<5) { col in
                                        let index = row * 5 + col
                                        if index < cards.count {
                                            GeometryReader { geometry in
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(cards[index].color)
                                                    .frame(width: 200, height: 300)
                                                    .scaleEffect(scale(for: geometry))
                                            }
                                            .frame(width: 200, height: 300)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .background(Color.black)
                .onAppear {
                    startMotionUpdates(screenSize: geometry.size)
                }
                .onDisappear {
                    stopMotionUpdates()
                }
            }
            .background(Color.black)
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func scale(for geometry: GeometryProxy) -> CGFloat {
        let frame = geometry.frame(in: .global)
        let screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        let distance = sqrt(pow(frame.midX - screenCenter.x, 2) + pow(frame.midY - screenCenter.y, 2))
        let maxDistance: CGFloat = 500
        let scale = 1.0 - min(distance / maxDistance, 0.3)
        return max(0.7, scale)
    }
    
    private func startMotionUpdates(screenSize: CGSize) {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.03
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                guard let data = data, error == nil else { return }
                
                let baseTiltFactorX: CGFloat = 40.0
                let baseTiltFactorY: CGFloat = 60.0
                
                let accelerationX = CGFloat(data.acceleration.x)
                let accelerationY = CGFloat(data.acceleration.y)
                
                let responseCurveX: (CGFloat) -> CGFloat = { input in
                    let sign = input < 0 ? -1.0 : 1.0
                    let absValue = abs(input)
                    
                    if absValue < 0.3 {
                        return sign * pow(absValue * 3.33, 1.5) * baseTiltFactorX
                    } else {
                        return sign * absValue * baseTiltFactorX
                    }
                }
                
                let responseCurveY: (CGFloat) -> CGFloat = { input in
                    let sign = input < 0 ? -1.0 : 1.0
                    let absValue = abs(input)
                    
                    if absValue < 0.2 {
                        return sign * pow(absValue * 5.0, 2.0) * baseTiltFactorY
                    } else if absValue < 0.4 {
                        return sign * pow(absValue * 2.5, 1.7) * baseTiltFactorY
                    } else {
                        return sign * absValue * baseTiltFactorY
                    }
                }
                
                withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                    let newX = -responseCurveX(accelerationX)
                    let newY = responseCurveY(accelerationY)
                    
                    DispatchQueue.main.async {
                        guard let scrollView = findScrollView() else { return }
                        
                        var offset = scrollView.contentOffset
                        
                        offset.x += newX
                        offset.y += newY
                        
                        offset.x = max(0, min(offset.x, scrollView.contentSize.width - scrollView.bounds.width))
                        offset.y = max(0, min(offset.y, scrollView.contentSize.height - scrollView.bounds.height))
                        
                        scrollView.setContentOffset(offset, animated: false)
                    }
                }
            }
        }
    }
    
    private func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
    
    private func findScrollView() -> UIScrollView? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        func findScrollViewInView(_ view: UIView) -> UIScrollView? {
            for subview in view.subviews {
                if let scrollView = subview as? UIScrollView {
                    return scrollView
                }
                if let found = findScrollViewInView(subview) {
                    return found
                }
            }
            return nil
        }
        
        return findScrollViewInView(rootViewController.view)
    }
}

#Preview {
    ContentView()
}

