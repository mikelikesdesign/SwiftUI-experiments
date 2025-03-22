//
//  ContentView.swift
//  photo slingshot
//
//  Created by Michael Lee on 5/8/24.
//

import SwiftUI

struct ContentView: View {
    let mainImage = "image_1"
    let avatarImages = ["avatar_1", "avatar_2", "avatar_3"]
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var imageOpacity = 1.0

    var body: some View {
        ZStack {
            Image(mainImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 172, height: 194)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 0)
                .opacity(imageOpacity)
                .scaleEffect(isDragging ? 0.85 : 1.0)
                .offset(isDragging ? dragOffset : .zero)
                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: isDragging)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragOffset = value.translation
                            isDragging = true
                        }
                        .onEnded { _ in
                            let screenHeight = UIScreen.main.bounds.height
                            let dragThreshold = screenHeight * 0.3
                            
                            if dragOffset.height > dragThreshold {
                                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                                    dragOffset = CGSize(width: dragOffset.width, height: -screenHeight)
                                    imageOpacity = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    // Reset position while image is invisible
                                    dragOffset = .zero
                                    isDragging = false
                                    
                                    // Small delay before fading in the new image
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        // Fade in the new image
                                        withAnimation(.easeIn(duration: 0.8)) {
                                            imageOpacity = 1.0
                                        }
                                    }
                                }
                            } else {
                                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                                    dragOffset = .zero
                                }
                                isDragging = false
                            }
                        }
                )
            
            HStack(spacing: 16) {
                ForEach(0..<avatarImages.count) { index in
                    Image(avatarImages[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 92, height: 92)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 4)
                                .opacity(isDragging && dragOffset.width > CGFloat(index) * 92 - 46 && dragOffset.width < CGFloat(index) * 92 + 46 ? 1 : 0)
                        )
                        .offset(y: isDragging ? min(max(dragOffset.height - 100, 0), 64) : -200)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 16)
            .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: isDragging)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
