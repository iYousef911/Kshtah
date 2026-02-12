---
name: map-expert
description: Specialized guidance for enhancing and maintaining Kashat's MapKit features, including real-time convoy tracking and weather overlays.
---

# Map-Expert Skill

This skill provides expert patterns for working with the complex mapping features in the Kashat application.

## Core Concepts

### 1. MapKit 2023+ (SwiftUI)
Always use the modern `Map` and `Annotation` APIs. Avoid `MapMarker` or legacy `MKMapView` wrappers unless strictly necessary for backward compatibility.

### 2. Environment Object Provisioning
**CRITICAL**: Annotations in SwiftUI's Map closure often lose their environment object inheritance. Always explicitly pass required objects to subviews inside annotations.
```swift
Annotation(spot.name, coordinate: spot.coordinate) {
    SpotMarkerView(spot: spot)
        .environmentObject(store) // ESSENTIAL
}
```

### 3. Feature Integrations

#### Convoy Tracking
- Use `ConvoyManager` to fetch active members.
- Display members using `Annotation` with a distinct `car.fill` icon.
- Ensure the "القافلة" filter chip is respected in the `filteredSpots` logic or map display.

#### Weather Overlays
- Integrate with `WeatherManager.shared.getWeather`.
- Use `WeatherCapsule` for center-coordinate weather data.
- Listen for `SevereWeatherAlert` notifications to trigger the floating alert banner.

## Best Practices
- **Performance**: Batch map updates and avoid excessive re-renders by optimizing the `filteredSpots` computed property.
- **Visuals**: Use `.ultraThinMaterial` for overlays to maintain a premium "Glass" aesthetic.
- **RTL Support**: Ensure labels and icons are mirrored correctly for Arabic users where appropriate.
