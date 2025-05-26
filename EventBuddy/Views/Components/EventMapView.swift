import SwiftUI
import MapKit
import CoreLocation

struct EventMapView: View {
    let event: Event
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var isLoading = true
    @State private var geocodingFailed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Loading map...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else if let coordinate = coordinate {
                // Map with pin
                Map(position: $cameraPosition) {
                    Annotation(
                        event.title,
                        coordinate: coordinate,
                        anchor: .bottom
                    ) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 32, height: 32)
                                )
                        }
                    }
                }
                .frame(height: 200)
                .cornerRadius(12)
                .onTapGesture {
                    openInMaps()
                }
            } else {
                // Fallback when geocoding fails
                VStack {
                    Image(systemName: "map")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("Unable to locate address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Open in Maps") {
                        openInMaps()
                    }
                    .font(.caption)
                    .padding(.top, 4)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .onAppear {
            geocodeLocation()
        }
    }
    
    private func geocodeLocation() {
        let geocoder = CLGeocoder()
        let addressToGeocode = event.address ?? event.location
        geocoder.geocodeAddressString(addressToGeocode) { placemarks, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    self.coordinate = location.coordinate
                    
                    // Update camera position to show the location
                    self.cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                } else {
                    self.geocodingFailed = true
                }
            }
        }
    }
    
    private func openInMaps() {
        if let coordinate = coordinate {
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = event.title
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        } else {
            // Fallback to search by location name
            let geocoder = CLGeocoder()
            let addressToGeocode = event.address ?? event.location
            geocoder.geocodeAddressString(addressToGeocode) { placemarks, error in
                if let placemark = placemarks?.first,
                   let _ = placemark.location {
                    let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                    mapItem.name = event.title
                    mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ])
                }
            }
        }
    }
}

#Preview {
    VStack {
        EventMapView(event: Event.preview)
        
        Spacer()
        
        EventMapView(event: Event(
            title: "Test Event",
            eventDescription: "Test Description",
            location: "Unknown Location",
            startDate: Date(),
            endDate: Date(),
            eventType: EventType.social.rawValue
        ))
    }
    .padding()
} 
