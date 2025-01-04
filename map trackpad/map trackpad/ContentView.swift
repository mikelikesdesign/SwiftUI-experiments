//
//  ContentView.swift
//  map trackpad
//
//  Created by Michael Lee on 11/10/24.
//

import SwiftUI
import MapKit
import CoreLocation

class LocalSearchService {
    func searchRestaurants(cuisine: String, in region: MKCoordinateRegion, completion: @escaping (MKMapItem?) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(cuisine) restaurant"
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, let randomResult = response.mapItems.randomElement() else {
                completion(nil)
                return
            }
            completion(randomResult)
        }
    }
}

struct ContentView: View {
    @State private var sliderPosition: CGPoint = .zero
    @State private var selectedRestaurant: String = "Select a cuisine type"
    @State private var fontSize: CGFloat = 40
    @State private var isKnobEnlarged: Bool = false
    @State private var trackpadRotation: (x: CGFloat, y: CGFloat) = (0, 0)
    @State private var isTrackpadExpanded: Bool = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchService = LocalSearchService()
    @State private var selectedRestaurantName: String = ""

    let screenHeight = UIScreen.main.bounds.height
    let trackpadHeight: CGFloat = UIScreen.main.bounds.height * 0.4
    let knobSize: CGFloat = 40
    let knobEnlargementFactor: CGFloat = 1.5
    let gridLines = 10
    let maxRotation: CGFloat = 2

    var body: some View {
        ZStack {
            // Full screen map
            Map(coordinateRegion: $region)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Trackpad section
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "121212"))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    if isTrackpadExpanded {
                        // Grid
                        Path { path in
                            for i in 1..<gridLines {
                                let x = CGFloat(i) * UIScreen.main.bounds.width / CGFloat(gridLines)
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: trackpadHeight))
                                
                                let y = CGFloat(i) * trackpadHeight / CGFloat(gridLines)
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: y))
                            }
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        
                        // Perimeter labels
                        ForEach(0..<8, id: \.self) { index in
                            let angle = Double(index) * .pi / 4
                            let radius = min((UIScreen.main.bounds.width - 64)/2 - 40, trackpadHeight/2 - 40)
                            let x = cos(angle) * radius + (UIScreen.main.bounds.width - 32)/2
                            let y = sin(angle) * radius + trackpadHeight/2
                            
                            Text(cuisineLabel(for: index))
                                .foregroundColor(.white)
                                .opacity(labelOpacity(for: index, position: sliderPosition))
                                .position(x: x, y: y)
                        }
                        
                        // Knob
                        Circle()
                            .fill(Color.white)
                            .frame(width: isKnobEnlarged ? knobSize * knobEnlargementFactor : knobSize,
                                   height: isKnobEnlarged ? knobSize * knobEnlargementFactor : knobSize)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            .position(sliderPosition)
                    } else {
                        ZStack {
                            Path { path in
                                for i in 1..<gridLines {
                                    let x = CGFloat(i) * 80 / CGFloat(gridLines)
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: 80))
                                    
                                    let y = CGFloat(i) * 80 / CGFloat(gridLines)
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: 80, y: y))
                                }
                            }
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray.opacity(0.8))
                                .font(.system(size: 20, weight: .medium))
                        }
                    }
                }
                .frame(
                    width: isTrackpadExpanded ? UIScreen.main.bounds.width - 32 : 80,
                    height: isTrackpadExpanded ? trackpadHeight : 80
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            withAnimation(.spring(response: 0.3)) {
                                isTrackpadExpanded = true
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3)) {
                                isTrackpadExpanded = false
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            guard isTrackpadExpanded else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                updateSliderPosition(value, in: UIScreen.main.bounds.size)
                                isKnobEnlarged = true
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isKnobEnlarged = false
                                updateText()
                            }
                        }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .rotation3DEffect(
                    .degrees(trackpadRotation.x),
                    axis: (x: 1, y: 0, z: 0)
                )
                .rotation3DEffect(
                    .degrees(trackpadRotation.y),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
        }
        .onAppear {
            // Center the knob
            sliderPosition = CGPoint(
                x: (UIScreen.main.bounds.width - 32) / 2,
                y: trackpadHeight / 2
            )
            updateText()
        }
    }
    
    private func normalizedPosition(for size: CGSize) -> CGPoint {
        return CGPoint(
            x: sliderPosition.x / size.width,
            y: sliderPosition.y / trackpadHeight
        )
    }
    
    private func updateSliderPosition(_ value: DragGesture.Value, in size: CGSize) {
        let newPosition = value.location
        sliderPosition = limitPositionToTrackpad(newPosition, in: size)
        
        // Calculate rotation based on knob position
        let normalizedX = (sliderPosition.x / size.width) * 2 - 1
        let normalizedY = (sliderPosition.y / trackpadHeight) * 2 - 1
        trackpadRotation.y = normalizedX * maxRotation
        trackpadRotation.x = -normalizedY * maxRotation
    }
    
    private func limitPositionToTrackpad(_ position: CGPoint, in size: CGSize) -> CGPoint {
        return CGPoint(
            x: min(max(position.x, knobSize/2), size.width - knobSize/2),
            y: min(max(position.y, knobSize/2), trackpadHeight - knobSize/2)
        )
    }
    
    private func updateText() {
        let normalizedPosition = normalizedPosition(for: UIScreen.main.bounds.size)
        let centerX = 0.5
        let centerY = 0.5
        let distance = sqrt(pow(normalizedPosition.x - centerX, 2) + pow(normalizedPosition.y - centerY, 2))
        
        if distance < 0.15 { // If near center
            // Don't do anything, just let it collapse
            return
        }
        
        // Rest of the existing restaurant recommendation logic
        let angle = atan2(normalizedPosition.y - 0.5, normalizedPosition.x - 0.5)
        let pi = Double.pi
        
        let cuisine: String
        switch angle {
        case -pi/8...pi/8:
            cuisine = "Chinese"
        case pi/8...3*pi/8:
            cuisine = "Japanese"
        case 3*pi/8...5*pi/8:
            cuisine = "French"
        case 5*pi/8...7*pi/8:
            cuisine = "Vietnamese"
        case 7*pi/8...pi, -pi...(-7*pi/8):
            cuisine = "Italian"
        case -7*pi/8...(-5*pi/8):
            cuisine = "Korean"
        case -5*pi/8...(-3*pi/8):
            cuisine = "American"
        default:
            cuisine = "Mexican"
        }
        
        searchService.searchRestaurants(cuisine: cuisine, in: region) { mapItem in
            guard let mapItem = mapItem else { return }
            
            DispatchQueue.main.async {
                selectedRestaurant = "Recommended: \(mapItem.name ?? "Unknown Restaurant")"
                updateRegion(
                    latitude: mapItem.placemark.coordinate.latitude,
                    longitude: mapItem.placemark.coordinate.longitude,
                    zoomLevel: 0.0005
                )
            }
        }
    }
    
    private func updateRegion(latitude: Double, longitude: Double, zoomLevel: Double = 0.1) {
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: zoomLevel, longitudeDelta: zoomLevel)
            )
        }
    }

    private func cuisineLabel(for index: Int) -> String {
        switch index {
        case 0: return "Chinese"     // Right
        case 1: return "Japanese"    // Bottom right
        case 2: return "French"      // Bottom
        case 3: return "Vietnamese"  // Bottom left
        case 4: return "Italian"     // Left
        case 5: return "Korean"      // Top left
        case 6: return "American"    // Top
        case 7: return "Mexican"     // Top right
        default: return ""
        }
    }

    private func labelOpacity(for index: Int, position: CGPoint) -> Double {
        let angle = Double(index) * .pi / 4
        let radius = min((UIScreen.main.bounds.width - 64)/2 - 40, trackpadHeight/2 - 40)
        let labelX = cos(angle) * radius + (UIScreen.main.bounds.width - 32)/2
        let labelY = sin(angle) * radius + trackpadHeight/2
        
        let distance = sqrt(pow(position.x - labelX, 2) + pow(position.y - labelY, 2))
        let maxDistance = radius
        
        // Calculate opacity: 0.3 when far, 1.0 when close
        return min(1.0, max(0.3, 1.0 - (distance / maxDistance)))
    }
}

#Preview {
    ContentView()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
