//
//  ContentView.swift
//  drag to delete
//
//  Created by Michael Lee on 5/26/24.
//

import SwiftUI

struct ContentView: View {
    @State private var imageSize: CGFloat = 320
    @State private var showCircle = false
    @State private var circleSize: CGFloat = 64
    @State private var showImage = true
    @State private var initialCircleGrowth = false
    @State private var dragPosition = CGPoint.zero
    @State private var shrinkCircle = false
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                if showCircle {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: circleSize, height: circleSize)
                            .scaleEffect(initialCircleGrowth ? 0 : 1)
                            .scaleEffect(shrinkCircle ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: initialCircleGrowth)
                            .animation(.easeInOut(duration: 0.5), value: shrinkCircle)
                        
                        Image("trash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            
            VStack {
                if showImage {
                    Image("colors")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageSize, height: imageSize)
                        .position(dragPosition)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    self.dragPosition = value.location
                                    
                                    if !self.showCircle {
                                        self.showCircle = true
                                        self.initialCircleGrowth = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            self.initialCircleGrowth = false
                                        }
                                    }
                                    
                                    let dragDistance = value.location.y
                                    let circleDistance = UIScreen.main.bounds.height - 92
                                    let distance = circleDistance - dragDistance
                                    
                                    if distance > 0 {
                                        let proportion = min(1, max(0, distance / circleDistance))
                                        self.circleSize = 64 + (28 * (1 - proportion))
                                        self.imageSize = 32 + (128 * proportion)
                                    } else {
                                        self.circleSize = 92
                                        self.imageSize = 32
                                    }
                                }
                                .onEnded { _ in
                                    if self.circleSize > 80 {
                                        self.showImage = false
                                        self.shrinkCircle = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            withAnimation {
                                                self.showCircle = false
                                            }
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            self.resetImage()
                                        }
                                    } else {
                                        self.resetImage()
                                    }
                                }
                        )
                }
                
                Spacer()
            }
            .padding(.top, 72)
        }
    }
    
    private func resetImage() {
        self.imageSize = 320
        self.showCircle = false
        self.circleSize = 64
        self.showImage = true
        self.initialCircleGrowth = false
        self.shrinkCircle = false
        self.dragPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: 72 + 160)
    }
}

#Preview {
    ContentView()
}
