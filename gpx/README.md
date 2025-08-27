# GPX Location Testing Files

This folder contains GPX (GPS Exchange Format) files for testing location-based features in the iOS Simulator.

## Files

- **home_to_cafe.gpx**: Simulates a journey from home to a Starbucks cafe
- **cafe_to_grocery.gpx**: Simulates a journey from Starbucks to Whole Foods grocery store

## How to Use in iOS Simulator

### Method 1: Custom Location (Recommended)
1. Open iOS Simulator
2. Go to **Features > Location > Custom Location...**
3. Enter coordinates from any waypoint in the GPX files
4. The simulator will use this as the device's current location

### Method 2: Load GPX File
1. In Xcode, go to your scheme settings
2. Select **Run > Options**
3. Under **Core Location**, choose **GPX File**
4. Select one of the GPX files from this folder
5. Run your app - it will follow the GPX route automatically

## Testing Visit Detection

To trigger visit detection in your app:

1. **Load a GPX file** or set a custom location
2. **Pause at a waypoint** for 5+ minutes (especially at Starbucks or Whole Foods)
3. **Check the app** - you should see:
   - "Visited" events in the location events list
   - Visit records in Core Data
   - Notifications for arrivals
   - Card recommendations (if confidence is high enough)

## Sample Coordinates

- **Home**: 37.7749, -122.4194 (San Francisco)
- **Starbucks**: 37.7849, -122.4094 (Cafe location)
- **Whole Foods**: 37.7949, -122.3994 (Grocery store)

## Tips

- **Stay at waypoints**: The app needs you to remain at a location for several minutes to detect a "visit"
- **Check confidence**: Low confidence visits will show "waiting for dwell" messages
- **Multiple visits**: Return to the same location multiple times to increase confidence scores
- **Time of day**: Visit during meal times (8-10am, 12-2pm, 6-10pm) for bonus confidence points

## Troubleshooting

- If visits aren't detected, ensure location permissions are granted
- Check that Background Modes > Location Updates is enabled in your app
- Verify the server is running on http://127.0.0.1:8000
- Check the console for any error messages
