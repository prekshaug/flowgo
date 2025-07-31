import 'package:google_maps_flutter/google_maps_flutter.dart';

class Task {
  final String id;
  final String title;
  final DateTime startTime;
  final String from;
  final String to;
  final String mood; // calm, focus, etc.
  final bool needsRoute;
  final LatLng? fromLatLng;
  final LatLng? toLatLng;

  Task({
    required this.id,
    required this.title,
    required this.startTime,
    required this.from,
    required this.to,
    required this.mood,
    required this.needsRoute,
    this.fromLatLng,
    this.toLatLng,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'from': from,
      'to': to,
      'mood': mood,
      'needsRoute': needsRoute,
      'fromLat': fromLatLng?.latitude,
      'fromLng': fromLatLng?.longitude,
      'toLat': toLatLng?.latitude,
      'toLng': toLatLng?.longitude,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      startTime: DateTime.parse(map['startTime']),
      from: map['from'],
      to: map['to'],
      mood: map['mood'],
      needsRoute: map['needsRoute'],
      fromLatLng: (map['fromLat'] != null && map['fromLng'] != null)
          ? LatLng(map['fromLat'], map['fromLng'])
          : null,
      toLatLng: (map['toLat'] != null && map['toLng'] != null)
          ? LatLng(map['toLat'], map['toLng'])
          : null,
    );
  }
}
