import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_tracker_app/constants.dart';
import 'package:location/location.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => OrderTrackingPageState();
}

class OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation = LatLng(37.33500926, -122.03272188);
  static const LatLng destination = LatLng(37.33429383, -122.06600055);

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  Future<void> getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then((location) {
      currentLocation = location;
    });

    GoogleMapController googleMapController = await _controller.future;

    location.onLocationChanged.listen((newLocation) {
      currentLocation = newLocation;
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 13,
              target: LatLng(newLocation.latitude!, newLocation.longitude!),
            ),
          ),
        );
      setState((){});
    },);
  }

  Future<void> getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleAPIKey,
      request: PolylineRequest(
        origin: PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
        wayPoints: [],
      ),
    );

    if (result.points.isNotEmpty) {
      for (PointLatLng point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      setState((){});
    }
  }

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/Pin_source.png',
    ).then((icon) {
      sourceIcon = icon;
    });

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/Pin_destination.png',
    ).then((icon) {
      destinationIcon = icon;
    });

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/Badge.png',
    ).then((icon) {
      currentLocationIcon = icon;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getCurrentLocation();
      setCustomMarkerIcon();
      await getPolyPoints();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track order",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
        body: currentLocation == null
          ? const Center(child: Text('Loading...'),)
          :  GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
              zoom: 13,
            ),
            polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: primaryColor,
              width: 6,
            ),
            },
            markers: {
              Marker(
                markerId: const MarkerId("currentLocation"),
                icon: currentLocationIcon,
                position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
              ),
              Marker(
                markerId: const MarkerId("source"),
                icon: sourceIcon,
                position: sourceLocation,
              ),
              Marker(
                markerId: const MarkerId("destination"),
                icon: destinationIcon,
                position: destination,
              ),
          },
          onMapCreated: (mapController) {
            _controller.complete(mapController);
          },
        ),
      );
  }
}
