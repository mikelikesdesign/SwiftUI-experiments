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
    @State private var showBanner = false
    @State private var bannerOffset = UIScreen.main.bounds.height // Initially out of view

    var body: some View {
        ZStack {
            Image(mainImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 172, height: 194)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 0)
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
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isDragging = false
                                    dragOffset = .zero
                                    bannerOffset = UIScreen.main.bounds.height  // Reset banner position
                                    showBanner = true  // Ensure banner is shown
                                    withAnimation(.easeInOut) {
                                        bannerOffset = 0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            bannerOffset = UIScreen.main.bounds.height  // Slide out of view
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
            
            if isDragging {
                Image(mainImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 172, height: 194)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 0)
                    .opacity(0.65)
                    .offset(dragOffset)
            }
            
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
        .overlay(
            VStack {
                Spacer()
                if showBanner {
                    Text("Message sent to Claire")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 274, height: 52)
                        .background(Color.black)
                        .cornerRadius(100)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 0)
                        .offset(y: bannerOffset)
                }
            }
            .padding(.bottom, 48)
            .animation(.easeInOut(duration: 0.5), value: bannerOffset)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
