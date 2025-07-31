import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  GoogleMapController? _mapController;
  List<LatLng> _polylinePoints = [];
  final String _googleApiKey = 'AIzaSyCOMcj1GEpwcZH125EoHGPe4HzGgYTJm8k';

  @override
  void initState() {
    super.initState();
    if (widget.task.fromLatLng != null && widget.task.toLatLng != null) {
      _getRoutePolyline();
    }

  }

  Future<void> _getRoutePolyline() async {
    final from = widget.task.fromLatLng;
    final to = widget.task.toLatLng;

    if (from == null || to == null) return;

    final origin = '${from.latitude},${from.longitude}';
    final destination = '${to.latitude},${to.longitude}';

    final url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin&destination=$destination&key=$_googleApiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['routes'].isNotEmpty) {
      final points = data['routes'][0]['overview_polyline']['points'];
      final polylinePoints = PolylinePoints().decodePolyline(points);

      setState(() {
        _polylinePoints = polylinePoints
            .map((e) => LatLng(e.latitude, e.longitude))
            .toList();
      });
    }
  }

  Future<void> _launchNavigation() async {
    final from = widget.task.fromLatLng;
    final to = widget.task.toLatLng;

    if (from == null || to == null) return;

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&origin=${from.latitude},${from.longitude}'
          '&destination=${to.latitude},${to.longitude}'
          '&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('From: ${task.from}'),
            Text('To: ${task.to}'),
            Text('Mood: ${task.mood}'),
            Text('Start: ${task.startTime}'),
            const SizedBox(height: 16),
            if (task.fromLatLng != null && task.toLatLng != null) ...[
              SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: task.fromLatLng!,
                    zoom: 12,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('from'),
                      position: task.fromLatLng!,
                    ),
                    Marker(
                      markerId: const MarkerId('to'),
                      position: task.toLatLng!,
                    ),
                  },
                  polylines: {
                    if (_polylinePoints.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('route'),
                        color: Colors.blue,
                        width: 5,
                        points: _polylinePoints,
                      ),
                  },
                  onMapCreated: (controller) => _mapController = controller,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _launchNavigation,
                icon: const Icon(Icons.directions),
                label: const Text('Navigate with Google Maps'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
