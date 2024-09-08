//
//  ContentView.swift
//  map explore
//
//  Created by Michael Lee on 7/17/24.
//

import SwiftUI
import MapKit

struct Restaurant: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let photoName: String
    
    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
        lhs.id == rhs.id
    }
}

class SearchCompleter: NSObject, ObservableObject {
    @Published var currentRestaurant: Restaurant?
    private let completer = MKLocalSearchCompleter()
    private var photoIndex = 1
    
    override init() {
        super.init()
        completer.resultTypes = .pointOfInterest
        
        // Initialize with Noreetuh
        currentRestaurant = Restaurant(
            name: "Noreetuh",
            address: "128 1st Avenue, New York, NY 10009",
            coordinate: CLLocationCoordinate2D(latitude: 40.7268, longitude: -73.9845),
            photoName: "restaurant_1"
        )
    }
    
    func search(for coordinate: CLLocationCoordinate2D) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "restaurant"
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, !response.mapItems.isEmpty else { return }
            
            DispatchQueue.main.async {
                let randomItem = response.mapItems.randomElement()!
                self.photoIndex = (self.photoIndex % 5) + 1
                self.currentRestaurant = Restaurant(
                    name: randomItem.name ?? "Unknown",
                    address: randomItem.placemark.title ?? "Unknown address",
                    coordinate: randomItem.placemark.coordinate,
                    photoName: "restaurant_\(self.photoIndex)"
                )
            }
        }
    }
}

struct ProgressiveBlurView: View {
    let image: Image
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                VStack(spacing: 0) {
                    Color.clear
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                        .frame(height: geometry.size.height / 2)
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var searchCompleter = SearchCompleter()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7268, longitude: -73.9845), // Noreetuh coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var currentPhotoIndex = 1
    @State private var hasPerformedInitialSearch = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top half: Restaurant info and photo
                ZStack {
                    if let restaurant = searchCompleter.currentRestaurant {
                        ProgressiveBlurView(image: Image(restaurant.photoName))
                            .frame(width: geometry.size.width, height: geometry.size.height / 2)
                            .gesture(
                                DragGesture(minimumDistance: 50)
                                    .onEnded { value in
                                        if value.translation.width < 0 {
                                            // Swipe left
                                            currentPhotoIndex = (currentPhotoIndex % 5) + 1
                                        } else if value.translation.width > 0 {
                                            // Swipe right
                                            currentPhotoIndex = (currentPhotoIndex - 2 + 5) % 5 + 1
                                        }
                                    }
                            )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Spacer()
                            Text(restaurant.name)
                                .font(.title)
                                .fontWeight(.bold)
                            Text(restaurant.address)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .foregroundColor(.white)
                    } else {
                        Text("Move the map to find a restaurant")
                            .foregroundColor(.white)
                    }
                }
                .frame(height: geometry.size.height / 2)
                .background(Color.black) // Fallback background color
                .padding(.top, geometry.safeAreaInsets.top)
                
                // Bottom half: Apple Maps
                MapView(region: $region, restaurant: searchCompleter.currentRestaurant, onRegionChangeEnd: { newRegion in
                    if hasPerformedInitialSearch {
                        searchCompleter.search(for: newRegion.center)
                    } else {
                        hasPerformedInitialSearch = true
                    }
                })
                .frame(height: geometry.size.height / 2)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var restaurant: Restaurant?
    var onRegionChangeEnd: (MKCoordinateRegion) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.setRegion(region, animated: true)
        
        // Remove all existing annotations
        view.removeAnnotations(view.annotations)
        
        // Add annotation for the restaurant
        if let restaurant = restaurant {
            let annotation = MKPointAnnotation()
            annotation.coordinate = restaurant.coordinate
            annotation.title = restaurant.name
            view.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var isMoving = false
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isMoving = true
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if isMoving {
                parent.region = mapView.region
                parent.onRegionChangeEnd(mapView.region)
                isMoving = false
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "RestaurantPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            
            annotationView?.markerTintColor = .red
            
            return annotationView
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#Preview {
    ContentView()
}
