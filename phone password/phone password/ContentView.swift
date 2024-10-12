//
//  ContentView.swift
//  phone password
//
//  Created by Michael Lee on 10/11/24.
//

import SwiftUI

struct ContentView: View {
    @State private var enteredCode = ""
    @State private var isUnlocked = false
    @State private var animationAmount: CGFloat = 1.0
    @State private var isDrawingMode = false
    
    let numbers = (1...9).map { "\($0)" } + ["", "0", ""]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if isUnlocked {
                    ImageListView(isUnlocked: $isUnlocked, enteredCode: $enteredCode, geometry: geometry)
                        .transition(.opacity)
                } else if isDrawingMode {
                    SignatureView(isDrawingMode: $isDrawingMode, isUnlocked: $isUnlocked)
                        .scaleEffect(animationAmount)
                        .animation(.easeInOut(duration: 0.5), value: animationAmount)
                } else {
                    PasswordView(enteredCode: $enteredCode, isUnlocked: $isUnlocked, isDrawingMode: $isDrawingMode)
                        .scaleEffect(animationAmount)
                        .animation(.easeInOut(duration: 0.5), value: animationAmount)
                }
            }
            .onChange(of: isUnlocked) { _, newValue in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationAmount = newValue ? 0.01 : 1.0
                }
            }
        }
    }
}

struct PasswordView: View {
    @Binding var enteredCode: String
    @Binding var isUnlocked: Bool
    @Binding var isDrawingMode: Bool
    
    let numbers = (1...9).map { "\($0)" } + ["", "0", ""]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: 20) {
                    ForEach(0..<5) { index in
                        NumberView(index: index, enteredCode: $enteredCode)
                    }
                }
                .padding(.top, 50)
                
                Spacer()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(numbers, id: \.self) { number in
                        if !number.isEmpty {
                            Button(action: {
                                if enteredCode.count < 5 {
                                    enteredCode += number
                                    if enteredCode.count == 5 {
                                        // Check password here
                                        isUnlocked = true
                                    }
                                }
                            }) {
                                Text(number)
                                    .font(.title)
                                    .frame(width: 80, height: 80)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                                    .foregroundColor(.white)
                            }
                        } else {
                            Color.clear
                                .frame(width: 80, height: 80)
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDrawingMode = true
                        }
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .frame(width: 70, height: 70)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if !enteredCode.isEmpty {
                            enteredCode.removeLast()
                        }
                    }) {
                        Text("Delete")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 70, height: 70)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct SignatureView: View {
    @Binding var isDrawingMode: Bool
    @Binding var isUnlocked: Bool
    @State private var lines: [GradientLine] = []
    @State private var lastDrawingTime = Date()
    @State private var showPlaceholder = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if showPlaceholder {
                    Text("Draw your signature")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                        .transition(.opacity)
                }
                
                Canvas { context, size in
                    for line in lines {
                        var path = Path()
                        path.addLines(line.points)
                        context.stroke(path, with: .linearGradient(
                            line.gradient,
                            startPoint: .zero,
                            endPoint: CGPoint(x: size.width, y: size.height)
                        ), lineWidth: 5)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if showPlaceholder {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showPlaceholder = false
                                }
                            }
                            let newPoint = value.location
                            if let lastLine = lines.last, !lastLine.points.isEmpty {
                                var newLine = lastLine
                                newLine.points.append(newPoint)
                                lines[lines.count - 1] = newLine
                            } else {
                                let newLine = GradientLine(points: [newPoint], gradient: randomBrightGradient())
                                lines.append(newLine)
                            }
                            lastDrawingTime = Date()
                        }
                        .onEnded { _ in
                            lines.append(GradientLine(points: [], gradient: randomBrightGradient()))
                            lastDrawingTime = Date()
                        }
                )
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDrawingMode = false
                            }
                        }) {
                            Image(systemName: "123.rectangle")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .frame(width: 70, height: 70)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            resetSignature()
                        }) {
                            Text("Clear")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Color.clear
                            .frame(width: 70, height: 70)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onChange(of: lastDrawingTime) { _, _ in
            checkForUnlock()
        }
        .onChange(of: isUnlocked) { _, newValue in
            if !newValue {
                resetSignature()
            }
        }
        .onAppear {
            resetSignature()
        }
    }
    
    private func randomBrightGradient() -> Gradient {
        let hue1 = Double.random(in: 0...1)
        let hue2 = (hue1 + Double.random(in: 0.2...0.8)).truncatingRemainder(dividingBy: 1.0)
        let color1 = Color(hue: hue1, saturation: 0.8, brightness: 1)
        let color2 = Color(hue: hue2, saturation: 0.8, brightness: 1)
        return Gradient(colors: [color1, color2, .white])
    }
    
    private func checkForUnlock() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if Date().timeIntervalSince(lastDrawingTime) >= 1.0 && !lines.isEmpty {
                withAnimation {
                    isUnlocked = true
                }
            }
        }
    }
    
    private func resetSignature() {
        lines = []
        showPlaceholder = true
    }
}

struct GradientLine: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    let gradient: Gradient
}

struct ImageListView: View {
    @Binding var isUnlocked: Bool
    @Binding var enteredCode: String
    let imageNames = (1...10).map { "photo_\($0)" }
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(imageNames, id: \.self) { imageName in
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    }
                }
            }
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
            
            lockButton
        }
    }
    
    var lockButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                isUnlocked = false
                enteredCode = ""
            }
        }) {
            Image(systemName: "lock.fill")
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                )
                .blur(radius: 0.5)
        }
        .position(x: geometry.size.width / 2, y: geometry.size.height - 48)
    }
}

struct NumberView: View {
    let index: Int
    @Binding var enteredCode: String
    @State private var displayedNumber = "0"
    @State private var opacity = 1.0
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()  
    
    var body: some View {
        ZStack {
            if index < enteredCode.count {
                Text(displayedNumber)
                    .foregroundColor(.white)
                    .font(.system(size: 36, weight: .bold))
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0.1), value: opacity)
            } else {
                Text("•")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.system(size: 36, weight: .bold))
            }
        }
        .frame(width: 40, height: 40)
        .onReceive(timer) { _ in
            if index < enteredCode.count {
                withAnimation {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    displayedNumber = String(Int.random(in: 0...9))
                    withAnimation {
                        opacity = 1
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
