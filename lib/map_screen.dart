import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {

  GoogleMapController? _controller;
  Position? _currentPosition;
  List<LatLng> _polylines = [];
  @override
  void initState() {
    super.initState();
    goToCurrentLocation();
    
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Real-Time Location Tracker'),
        backgroundColor: Colors.blue,
        
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(23.79, 90.371),
          zoom: 16,
          
        ),
        polylines: <Polyline>{
          Polyline(
            polylineId: PolylineId("route"),
            points: _currentPosition != null
                ? _polylines
                : [],
            color: Colors.blue,
            width: 5,
          ),
        },
        markers: _currentPosition != null
            ? {
                Marker(
                  markerId: MarkerId("current_location"),
                  position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  infoWindow: InfoWindow(title: "My Current Location",snippet: "${_currentPosition!.latitude}, ${_currentPosition!.longitude}"),
                ),
              }
            : {},
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
            log("Map Created");
          },
          myLocationButtonEnabled: true,
          compassEnabled: true,
      ),
    );
  }
  Future<void> goToCurrentLocation() async {
    bool hasPermission = await hasLocationPermission();
    if (!hasPermission) {
      bool permissionStatus = await requestLocationPermission();
      if (!permissionStatus) {
        log("Location permission denied");
        return;
      }
    }
    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      Geolocator.openLocationSettings();
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _polylines.add(LatLng(position.latitude, position.longitude));
      log(_polylines.length.toString());
      _currentPosition = position;
    });
    try {
      await FirebaseFirestore.instance.collection('userData').add({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      log("Error saving location to Firestore: $e");
    }
    _controller?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
    log("Current Location: ${position.latitude}, ${position.longitude}");
    
    Future.delayed(Duration(seconds: 10), () {
      goToCurrentLocation();
    });
  }

  Future<bool> hasLocationPermission()async{
    LocationPermission permission = await Geolocator.checkPermission();
    return permission== .always || permission == .whileInUse ;
  }
  Future<bool> requestLocationPermission()async{
    LocationPermission permission = await Geolocator.requestPermission();
    return permission== .always || permission == .whileInUse ;
  }

}