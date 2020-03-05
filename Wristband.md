# **Steps for SHS Wristband Installation**


## Prerequisite
	1. Mobile phones with Bluetooth turned on;
	2. Wristband with Bluetooth broadcasting functions.


## **Steps for Android**
### Registration
	1. Android users check QRCode on wristband to get reference set Q_ref: {ModelID, major, minor}.
	2. Android phones start scanning nearby BLE devices.
	3. Android phones receive all broadcasting messages and translate them using custom communication protocol.
	4. Algorithm acquires some sets Q_rec {ModelID, major, minor} from broadcasting messges.
	5. Algorithm compares each item in Q_rec with Q_ref to see whether there is one match.


## **Steps for iPhone**
### Registry
	1. Get reference set Q: {ModelID, major and minor} from QRCode/Wristband label;
	2. iPhone scans nearby bluetooth devices with specific signal strength range (e.g. [-30, 0));
	3. Go through all devices captured and translate broadcasting message.
	4. Acquire possible dataset Q_p: {ModelID_p, major_p and minor_p}. Compare Q_p with Q. If all parameters match, the device captured should be the wristband we are looking for.
	5. Save the peripheral device UUID (CBPeripheral.uuid) locally and permanently. Next time, if it is required to check if this device is nearby, you may directly use saved UUID to recognise the specific device among scanning result.
	6. If you have concern on 5., you may need to go through 1~4 every time you need to check device proximity.

###  Content of Specific Peripheral
	1. According to CoreBluetooth library, one can extract peripheral's UUID, broadcasting message, and rssi from function
		---
			- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
		---
	2. Advertisement data include AD1 (HQSS SHS Network Data Specification for Device Partners V0.3.pdf) from with key "kCBAdvDataManufacturerData".
	3. The value got from 2. is of type NSData. It can be directly transfered to Bytes (Bytes *). To analyse the data object, you may use 
		---
		[NSData subdataWithRange:NSMakeRange()].
		---
	4. To get real decimal information, you should transfer Bytes to HEX and then towards decimal numbers. 
	5. Additionally you should pay attention to small endian in CompanyID.
	6. And for RSSI Transfer, pay attention to the transformation between unsigned_int and signed_int.
		---
		uint8_t txByte;
		[txData getBytes:&txByte length:1];
		int32_t txTC = (int8_t)txByte;
		NSString *txNew = [NSString stringWithFormat:@"%d", txTC];
		---
