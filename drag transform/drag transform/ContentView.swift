//
//  ContentView.swift
//  retro computer color picker
//
//  Created by https://github.com/mikelikesdesign
//

import SwiftUI

struct DraggableShape: View {
    @State private var position = CGPoint(x: 150, y: 150)
    @State private var isDragging = false
    @State private var dockedEdge: Edge? = .bottom

    let iconNames = ["icon_1", "icon_2", "icon_3", "icon_4"]

    var body: some View {
        GeometryReader { geometry in
            Image("bg")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            let dockedSize = CGSize(width: dockedEdge == .bottom ? 345 : 82, height: dockedEdge == .bottom ? 82 : 345)
            let draggingSize = CGSize(width: 96, height: 96)
            let targetSize = isDragging ? draggingSize : dockedSize
            let cornerRadius: CGFloat = isDragging ? 48 : 40 // Adjusted radius for smaller circle

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .frame(width: targetSize.width, height: targetSize.height)
                    .foregroundColor(.clear)
                    .background(BlurBackground(darken: true, additionalOpacity: 0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: isDragging ? .gray : .clear, radius: isDragging ? 10 : 0)

                // App icons layout
                iconLayout(for: geometry.size)
            }
            .position(isDragging ? position : dockedPosition(for: geometry.size, offset: 8))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        self.isDragging = true
                        self.position = gesture.location
                    }
                    .onEnded { gesture in
                        self.isDragging = false
                        self.dockedEdge = self.closestEdge(for: gesture.location, in: geometry.size)
                    }
            )
        }
        .edgesIgnoringSafeArea(dockedEdge != nil ? .all : [])
    }

    private func iconLayout(for size: CGSize) -> some View {
        Group {
            if isDragging {
                ZStack {
                    ForEach(iconNames, id: \.self) { iconName in
                        Image(iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isDragging)
            } else {
                layoutForDockedState()
            }
        }
    }

    private func layoutForDockedState() -> some View {
        Group {
            if dockedEdge == .bottom {
                HStack(spacing: 20) {
                    iconViews()
                }
            } else {
                VStack(spacing: 20) {
                    iconViews()
                }
            }
        }
    }

    private func iconViews() -> some View {
        ForEach(iconNames, id: \.self) { iconName in
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
        }
    }

    private func closestEdge(for location: CGPoint, in size: CGSize) -> Edge? {
        let distances = [
            Edge.bottom: size.height - location.y,
            Edge.leading: location.x,
            Edge.trailing: size.width - location.x
        ]

        let closest = distances.min { $0.value < $1.value }
        return closest?.key
    }

    private func dockedPosition(for size: CGSize, offset: CGFloat) -> CGPoint {
        switch dockedEdge {
        case .bottom:
            // Adjusted for 16px offset from the bottom
            return CGPoint(x: size.width / 2, y: size.height - offset - 41 - 16)
        case .leading:
            return CGPoint(x: offset + 41, y: size.height / 2)
        case .trailing:
            return CGPoint(x: size.width - offset - 41, y: size.height / 2)
        default:
            return position
        }
    }
}

struct BlurBackground: UIViewRepresentable {
    var darken: Bool
    var additionalOpacity: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.backgroundColor = UIColor(white: darken ? 0.0 : 1.0, alpha: additionalOpacity)
        blurView.layer.cornerRadius = 40
        blurView.layer.masksToBounds = true
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

enum Edge {
    case bottom, leading, trailing
}

struct ContentView: View {
    var body: some View {
        DraggableShape()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
