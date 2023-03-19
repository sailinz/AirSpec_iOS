# AirSpec_iOS
This repository stores the source code for a SwiftUI-based AirSpec iOS and associated watchOS app which works with open-source smart glasses for environmental and physiological sensing: AirSpecs: https://github.com/pchwalek/env_glasses. The app composes interfaces that display real-time data received via Bluetooth offline and protobuf-based packet formatting to transmit data to an AWS server periodically when the app is connected to the internet. 

The app is equipped with survey logic modified from on Cozie (an app that allows building occupants to provide feedback in real time): https://github.com/cozie-app/cozie-apple 

## WatchOS app

Tap the 4 IEQ dimensions to detailed data. 

**Home tab** receive data from the iOS app via WatchConnectivity
<img src="https://user-images.githubusercontent.com/16971026/226205618-9dd81064-af3b-451e-a811-06b35b526fb2.jpg" width="150">

**Sensor data tabs** display data from the iOS app via WatchConnectivity

<img src="https://user-images.githubusercontent.com/16971026/226205428-89b640c1-235c-4189-818c-1792759e4ce7.jpg" width="150">

**Survey tabs** Comfort survey modified from Cozie app
<img src="https://user-images.githubusercontent.com/16971026/226205534-a22dd9d5-c6b8-4c70-8345-85fa2bdd09da.jpg" width="150">

<img src="https://user-images.githubusercontent.com/16971026/226205445-e00f2b90-8333-475e-a48e-1b9f5697563b.jpg" width="150">

**Eye blink calibration** Eye exercise to match with high resolution blink data from the glasses to understand eye movement behaviours
<img src="https://user-images.githubusercontent.com/16971026/226205456-8fc00eb7-5b12-4929-931d-02e1e7874b59.jpg" width="150">

## iOS app

**Home tab** updated with sensor data got from the glasses

<img src="https://user-images.githubusercontent.com/16971026/226205477-71badcc0-5075-4de6-adb7-58bcd493c70c.PNG" width="250">

**My data tab** Show daily/weekly data records in charts

<img src="https://user-images.githubusercontent.com/16971026/226205578-b86327b1-cd0e-49bf-bdea-66b7b63611a4.PNG" width="250">

**Survey** Survey (iOS version)

<img src="https://user-images.githubusercontent.com/16971026/226205606-1077bec8-64b5-4d1a-9383-5ddb4bcbff11.PNG" width="250">
<img src="https://user-images.githubusercontent.com/16971026/226205610-05ee9c3f-d942-4904-900f-f392f349e143.PNG" width="250">


**Setting tab** allows to input a random user id to connect to the glasses 

<img src="https://user-images.githubusercontent.com/16971026/209242839-7cd3dfa8-5906-4381-b0b6-aac8e6b63b81.PNG" width="250">
