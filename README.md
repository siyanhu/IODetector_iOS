# IODetector_iOS
To run the project, you may need an Apple developer program access.
## Prerequisite:
		1. iOS developer certificate with following signing & capabilities enabled:
			* Access WiFi information
			* Backgroudn modes
			* HealthKit
		2. iOS version is 7.0 or above
		3. Device Orientation: Protrait only
		4. The iPhone should have sim card
## You should report your profile to server administration before uploading data. Profile should include:
	{
		global longitude, latitude of your home address
		your device ID (Vendor ID of iPhone)
	}
	Once you have reported the device ID, do not delete the app from you phone in case of ID switching.

## iPhone Data List:
	1. Offline:
		* Unique ID: vendor + phone ID
		* Home Address: global longitude + latitude
	2. Online
		* GPS: Apple CoreLocation
		* Network connection category: Cellular/WiFi/No Connection
		* Connected WiFi: 
			a. MAC address: CoreLocation WiFi Info
			b. SSID: CoreLocation WiFi Info
			c. RSSI: estimated value from WiFi signal display on status bar
			d. IP
		* Cellular:
			a. Mobile Network Code: MNC
			b. Mobile Country Code: MCC
			c. RSSI: estimated value from WiFi signal display on status bar
			d. Network Service Provide Name
			e. Country Code
			f. Type: LTE/3G/WCDMA etc.
		* Barometer: CMAltimeter
		* Step Country on daily basis: HealthKit
		* Magneto: CMMotionManager, or CoreLocaton Compass Heading readings

## Tips on background running:
	1. Ableeng Pattern:
		a. Add notification in CoreLocation Delegate functions (e.g. didDetermineState, didUpdateLocations). Location status change (in this case, move > 100m) must be triggered before iOS kill the app. 
		b. Notification response in AppDelegate.m.
		c. Sample code: https://github.com/siyanhu/LBS_Demo_App.git. Branch: Ableeng.
	2. Server sends notification to iPhone, and phone user click the notification to open the app into foreground.

## Sugguestion:
	if you could apply for the access of NEHotspotConfiguration, you won't need to take a look at the above WiFi related part. Just use the NEHotspot API. It can do everything. 


