//
//  ContentView.swift
//  photo bubbles
//
//  Created by Michael Lee on 9/7/24.
//


import SwiftUI

struct ContentView: View {
    @State private var showPhoto = false
    @State private var photoSize: CGFloat = 0
    @State private var currentPhotoIndex = 0
    @State private var photoPosition: CGPoint = .zero
    @State private var isExpanding = false
    @State private var isFullScreen = false

    let photos = ["photo_1", "photo_2", "photo_3", "photo_4", "photo_5"]
    let expansionDuration: TimeInterval = 0.5 // Faster expansion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if showPhoto {
                    Image(photos[currentPhotoIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: photoSize, height: photoSize)
                        .position(photoPosition)
                        .clipped() // This ensures the image doesn't expand beyond its frame
                }

                VStack {
                    Spacer()
                    if isFullScreen {
                        Button(action: closePhoto) {
                            ZStack {
                                Circle()
                                    .fill(Color(uiColor: UIColor(hex: 0x333333)))
                                    .frame(width: 46, height: 46)
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.bottom, 32) // Increased from default 16 to 32
                        .padding(.trailing) // Keep horizontal padding
                    }
                }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !showPhoto {
                            showSmallPhoto(at: value.location, in: geometry.size)
                            expandPhoto(in: geometry.size)
                        }
                    }
                    .onEnded { _ in
                        if isExpanding {
                            cancelExpansion()
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }

    func showSmallPhoto(at position: CGPoint, in size: CGSize) {
        let photoSize: CGFloat = 100
        let halfSize = photoSize / 2
        
        let x = min(max(position.x, halfSize), size.width - halfSize)
        let y = min(max(position.y, halfSize), size.height - halfSize)
        
        showPhoto = true
        photoPosition = CGPoint(x: x, y: y)
        self.photoSize = photoSize
        currentPhotoIndex = (currentPhotoIndex + 1) % photos.count
        isFullScreen = false
    }

    func expandPhoto(in size: CGSize) {
        isExpanding = true
        let largerSize = max(size.width, size.height) // Use screen size instead of making it larger
        withAnimation(.easeInOut(duration: expansionDuration)) {
            photoSize = largerSize
            photoPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + expansionDuration) {
            if self.isExpanding {
                self.isExpanding = false
                self.isFullScreen = true
            }
        }
    }

    func cancelExpansion() {
        isExpanding = false
        withAnimation(.easeOut(duration: 0.2)) {
            photoSize = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPhoto = false
            isFullScreen = false
        }
    }

    func closePhoto() {
        isFullScreen = false
        isExpanding = false
        withAnimation(.easeOut(duration: 0.2)) {
            photoSize = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPhoto = false
        }
    }
}

#Preview {
    ContentView()
}

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
