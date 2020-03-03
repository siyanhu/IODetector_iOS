# IODetector_iOS
To run the project, you may need an Apple developer program access.
## Server API Documentation:
    https://quarloc.docs.apiary.io/#reference/0/server-api
    
## How to use the app
    1. open the app
    2. click submit profile
    3. when "start edititng" shows, click start editing
    4. when "query" shows, click query
    5. end editing when you want.

## Prerequisite:
		1. iOS developer certificate with following signing & capabilities enabled:
			* Access WiFi information
			* Backgroudn modes
			* HealthKit
		2. iOS version is 7.0 or above
		3. Device Orientation: Protrait only
		4. The iPhone should have sim card
## You should report your profile to server administration at the first time of  uploading data. Profile should include:
	{
		global longitude, latitude of your home address
		your device ID (Vendor ID of iPhone)
          your user id
	}
	Once you have reported the device ID, do not delete the app from you phone in case of ID switching. Details please check code (function anme: submitprofile).

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

## Tips on BLE Device Scanning
	1. Use CoreBluetooth
	2. According to specifications "HQSS SHS Network Data Specification for Device Partners V0.3", there are two sets of data in each package, AD0 and AD1. iOS cannot detect AD0 but can very well detect AD1.
	3. Sample code: DataCollector -> "didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI".
	4. Developer should pay attention that though it is the same Beacon, CoreBluetooth and CoreLocation will scan with different UUIDs. CoreLocation shall use ProximityUUID, while CoreBluetooth shall use UUID.
	5. txPower: Byte to two complements.
	6. Company ID: small endian.


