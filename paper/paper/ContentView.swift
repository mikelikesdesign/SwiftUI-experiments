//
//  ContentView.swift
//  paper
//
//  Created by Michael Lee on 5/16/24.
//

import SwiftUI

struct ContentView: View {
    @State private var crumpleEffect: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            CrumpledPaperEffect(crumpleEffect: crumpleEffect)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let startLocation = value.startLocation
                    let currentLocation = value.location
                    let dx = currentLocation.x - startLocation.x
                    let dy = currentLocation.y - startLocation.y
                    let distance = sqrt(dx * dx + dy * dy)
                    let pinchScale = distance / 100
                    crumpleEffect = max(0, min(1, pinchScale))
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        crumpleEffect = 0
                    }
                }
        )
    }
}

struct CrumpledPaperEffect: View {
    var crumpleEffect: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.gray]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .rotationEffect(Angle(degrees: 10))
                    .scaleEffect(1 + crumpleEffect)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.gray]),
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .rotationEffect(Angle(degrees: -10))
                    .scaleEffect(1 + crumpleEffect)
            }
        }
    }
}

#Preview {
    ContentView()
}
