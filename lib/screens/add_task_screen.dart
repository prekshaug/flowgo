import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';





final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class AddTaskScreen extends StatefulWidget {
  final void Function(Task) onAdd;

  const AddTaskScreen({Key? key, required this.onAdd}) : super(key: key);



  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
  }


class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _fromController = TextEditingController();
  final _destinationController = TextEditingController();


  final String _googleApiKey = 'AIzaSyCOMcj1GEpwcZH125EoHGPe4HzGgYTJm8k'; // Replace this

  final GoogleMapsPlaces _places = GoogleMapsPlaces(
      apiKey: 'AIzaSyCOMcj1GEpwcZH125EoHGPe4HzGgYTJm8k');

  List<Prediction> fromPredictions = [];
  List<Prediction> toPredictions = [];

  LatLng? _currentLocation;
  LatLng? _destinationLatLng;
  GoogleMapController? _mapController;
  List<LatLng> _polylinePoints = [];

  String _selectedMood = 'calm';
  DateTime? _selectedDateTime;
  DateTime? _suggestedDateTime;
  String? _routeSummary;
  bool _enableNotification = false;
  String? _etaText;


  Future<void> _detectCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    await _updateFromAddressFromLatLng(); // 🔥 Get and set actual address

    if (_destinationLatLng != null) {
      _getRoutePolyline();
    }
  }


  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
    tz.initializeTimeZones();
  }


  Future<void> _updateFromAddressFromLatLng() async {
    if (_currentLocation == null) return;

    final lat = _currentLocation!.latitude;
    final lng = _currentLocation!.longitude;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleApiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final address = data['results'][0]['formatted_address'];
      setState(() {
        _fromController.text = address;
      });
    }
  }


  Future<void> autoCompleteSearch(String input, bool isFrom) async {
    if (input.isEmpty) {
      setState(() {
        if (isFrom)
          fromPredictions = [];
        else
          toPredictions = [];
      });
      return;
    }

    final response = await _places.autocomplete(
      input,
      language: 'en',
      components: [Component(Component.country, 'in')],
    );

    if (response.isOkay) {
      setState(() {
        if (isFrom) {
          fromPredictions = response.predictions;
        } else {
          toPredictions = response.predictions;
        }
      });
    } else {
      print('Autocomplete error: ${response.errorMessage}');
    }
  }


  Future<void> selectPlace(String placeId, bool isFrom) async {
    final detail = await _places.getDetailsByPlaceId(placeId);
    final location = detail.result.geometry!.location;

    setState(() {
      if (isFrom) {
        _currentLocation = LatLng(location.lat, location.lng);
        _fromController.text = detail.result.name;
        fromPredictions.clear();
      } else {
        _destinationLatLng = LatLng(location.lat, location.lng);
        _destinationController.text = detail.result.name;
        toPredictions.clear();
      }
    });

    if (_currentLocation != null && _destinationLatLng != null) {
      _getRoutePolyline();
    }
  }


  Future<void> _getRoutePolyline({DateTime? time}) async {
    if (_currentLocation == null || _destinationLatLng == null) return;

    final origin = '${_currentLocation!.latitude},${_currentLocation!
        .longitude}';
    final destination = '${_destinationLatLng!.latitude},${_destinationLatLng!
        .longitude}';

    String trafficModel = 'best_guess';
    String avoid = '';

    if (_selectedMood == 'calm') {
      trafficModel = 'pessimistic';
      avoid = '&avoid=tolls|highways|ferries';
    } else if (_selectedMood == 'energized') {
      trafficModel = 'optimistic';
    }
    final departureTime = ((time ?? DateTime.now()).millisecondsSinceEpoch ~/
        1000).toString();


    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&departure_time=$departureTime&traffic_model=$trafficModel$avoid&key=$_googleApiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['routes'].isNotEmpty) {
      final points = data['routes'][0]['overview_polyline']['points'];
      final polylinePoints = PolylinePoints().decodePolyline(points);
      final summary = data['routes'][0]['summary'];
      final durationInTraffic = data['routes'][0]['legs'][0]['duration_in_traffic']['text'];


      setState(() {
        _polylinePoints =
            polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList();
        _routeSummary = summary;
        _etaText = durationInTraffic; // <-- ADD THIS
      });
    } else {
      print('No routes found: ${data['status']}');
    }
  }

  Future<void> _scheduleNotification(DateTime scheduledTime,
      String taskTitle) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'FlowGo Reminder',
      taskTitle, // Fixed: use taskTitle instead of title
      tz.TZDateTime.from(
          scheduledTime.subtract(const Duration(minutes: 5)), tz.local),
      // Fixed: subtract 5 minutes
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flowgo_channel',
          'FlowGo Notifications',
          channelDescription: 'Reminder before task starts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }


  Future<DateTime?> getSuggestedTimeBasedOnMood() async {
    if (_currentLocation == null || _destinationLatLng == null ||
        _selectedDateTime == null) return null;

    DateTime base = _selectedDateTime!;
    DateTime? bestTime;
    int bestDuration = 1 << 30;
    int? fallbackDuration;

    for (int i = -30; i <= 30; i += 10) {
      final checkTime = base.add(Duration(minutes: i));
      final departureTime = (checkTime.millisecondsSinceEpoch ~/ 1000)
          .toString();
      final origin = '${_currentLocation!.latitude},${_currentLocation!
          .longitude}';
      final destination = '${_destinationLatLng!.latitude},${_destinationLatLng!
          .longitude}';

      String trafficModel = 'best_guess';
      String avoid = '';
      if (_selectedMood == 'calm') {
        trafficModel = 'pessimistic';
        avoid = '&avoid=tolls|highways|ferries';
      } else if (_selectedMood == 'energized') {
        trafficModel = 'optimistic';
      }

      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&departure_time=$departureTime&traffic_model=$trafficModel$avoid&key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        final durationInSeconds = data['routes'][0]['legs'][0]['duration_in_traffic']['value'];
        fallbackDuration ??= durationInSeconds; // Store for fallback use

        final arrivalTime = checkTime.add(Duration(seconds: durationInSeconds));
        if (arrivalTime.isBefore(base)) {
          // Only consider if arrival is before preferred
          if (durationInSeconds < bestDuration) {
            bestDuration = durationInSeconds;
            bestTime = checkTime;
          }
        }
      }
    }

    if (bestTime != null) {
      return bestTime;
    } else if (fallbackDuration != null) {
      // fallback: subtract ETA from preferred time
      return base.subtract(Duration(seconds: fallbackDuration));
    } else {
      return null;
    }
  }
  void _finalizeSave() async {
    if (_enableNotification) {
      await _scheduleNotification(_selectedDateTime!, _titleController.text);
    }
    // Create task object
    final newTask = Task(
      id: DateTime.now().toIso8601String(),
      title: _titleController.text,
      startTime: _selectedDateTime!,
      from: _fromController.text,
      to: _destinationController.text,
      mood: _selectedMood,
      needsRoute: true,
      fromLatLng: _currentLocation,
      toLatLng: _destinationLatLng,
    );

    // ✅ Schedule local notification if enabled
    // if (_enableNotification) {
    //   await _scheduleNotification(_selectedDateTime!, _titleController.text);
    //
    // }

    // Return to home screen with new task
    widget.onAdd(newTask);
    Navigator.pop(context, newTask);
  }
  Future<void> _showSaveDialog() async {
    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Do you want to save your plan?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To reach ${_titleController.text} on : ${DateFormat
                    .yMMMd().add_jm().format(_selectedDateTime!)}'),
                if (_suggestedDateTime != null)
                  Text('You may have to leave by: ${DateFormat.yMMMd()
                      .add_jm()
                      .format(_suggestedDateTime!)} as suggested'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Cancel
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _finalizeSave(); // Actual save logic
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  Future<bool> _checkAndRequestAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isGranted) {
      return true;
    }

    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }



  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() async {
    if (_titleController.text.isEmpty ||
        _fromController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _selectedDateTime == null ||
        _currentLocation == null ||
        _destinationLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Ask user if they want to use the suggested time
    if (_suggestedDateTime != null && _suggestedDateTime != _selectedDateTime) {
      final useSuggested = await showDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text('Do you want to save your plan?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To reach ${_titleController.text} on : ${DateFormat
                      .yMMMd().add_jm().format(_selectedDateTime!)}'),
                  if (_suggestedDateTime != null)
                    Text('You may have to leave by: ${DateFormat.yMMMd()
                        .add_jm()
                        .format(_suggestedDateTime!)} as suggested'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), // Cancel / No
                  child: const Text('No'),
                ),
                ElevatedButton(
                  // onPressed: () {
                  //   Navigator.pop(context); // ✅ Close the dialog first
                  //   Future.microtask(() => _submit()); // ✅ Defer _submit to avoid context error
                  // },
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // ✅ Ensure dialog closes immediately
                    Future.delayed(Duration(milliseconds: 200), () {
                      _submit(); // ✅ Run _submit after dialog is closed
                    });
                  },
                  child: const Text('Yes'),
                ),
              ],
            ),

      );

      if (useSuggested == true) {
        _selectedDateTime = _suggestedDateTime;
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Plan Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fromController,
              decoration: InputDecoration(labelText: 'From'),
              onChanged: (val) => autoCompleteSearch(val, true),
            ),
            ...fromPredictions.map((p) => ListTile(
              title: Text(p.description ?? ''),
              onTap: () async {
                await selectPlace(p.placeId!, true); // select and fetch location
                FocusScope.of(context).unfocus(); // hide keyboard
                setState(() {}); // refresh UI to hide list
              },
            )),
            TextButton.icon(
              onPressed: () async {
                await _detectCurrentLocation(); // gets LatLng
                await _updateFromAddressFromLatLng(); // resolves to address
                setState(() {
                  fromPredictions = [];
                });
              },
              icon: const Icon(Icons.my_location),
              label: const Text("Use my current location"),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _destinationController,
              onChanged: (val) => autoCompleteSearch(val, false),
              decoration: const InputDecoration(labelText: 'Destination'),
             ),
             ...toPredictions.map((p) => ListTile(
              title: Text(p.description ?? ''),
              onTap: () async {
                await selectPlace(p.placeId!, false);
                setState(() {
                  _destinationController.text = p.description ?? '';
                  toPredictions = [];
                });
              },
            )),


            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDateTime,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Pick Date & Time',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: _selectedDateTime == null
                        ? ''
                        : DateFormat.yMMMd().add_jm().format(_selectedDateTime!),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMood,
              decoration: const InputDecoration(labelText: 'Mood'),
              items: ['calm', 'focus', 'energized'].map((mood) {
                return DropdownMenuItem(value: mood, child: Text(mood));
              }).toList(),

              onChanged: (val) async {
                setState(() {
                  _selectedMood = val!;
                });
                if (_currentLocation != null && _destinationLatLng != null) {
                  await _getRoutePolyline();
                }
              },
            ),

            const SizedBox(height: 20),
            if (_currentLocation != null && _destinationLatLng != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_routeSummary != null)
                    Text('Best route: $_routeSummary (based on mood: $_selectedMood)'),
                  Container(
                    height: 220,
                    margin: const EdgeInsets.only(top: 10),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentLocation!,
                            zoom: 13,
                          ),
                          myLocationEnabled: true,
                          zoomGesturesEnabled: true,
                          markers: {
                            Marker(
                              markerId: const MarkerId('origin'),
                              position: _currentLocation!,
                              infoWindow: const InfoWindow(title: 'From'),
                            ),
                            Marker(
                              markerId: const MarkerId('destination'),
                              position: _destinationLatLng!,
                              infoWindow: const InfoWindow(title: 'To'),
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
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                        ),

                        // 🟦 ETA overlay in top-right corner
                        if (_etaText != null)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _etaText!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                ],
              ),

            SwitchListTile(
              title: const Text('Enable Reminder Notification'),
              value: _enableNotification,
              onChanged: (value) async {
                if (value) {
                  // Request permission only if turning on
                  final granted = await _checkAndRequestAlarmPermission();

                  if (granted) {
                    setState(() {
                      _enableNotification = true;
                    });
                  } else {
                    // Show info that user must enable manually
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enable alarm permission in settings.')),
                    );
                    setState(() {
                      _enableNotification = false;
                    });
                  }
                } else {
                  // Simply disable
                  setState(() {
                    _enableNotification = false;
                  });
                }
              },
            ),


            TextButton.icon(
              icon: const Icon(Icons.timer_outlined),
              label: const Text("Suggest Best Time"),
              onPressed: () async {
                final suggested = await getSuggestedTimeBasedOnMood();
                if (suggested != null) {
                  setState(() {
                    _suggestedDateTime = suggested;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not fetch suggestions")),
                  );
                }
              },
            ),

            if (_suggestedDateTime != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Suggested time: ${DateFormat.jm().format(_suggestedDateTime!)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),

                    ],
                  ),
                ],
              ),





            const SizedBox(height: 10),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                if (_suggestedDateTime != null) {
                  await _showSaveDialog(); // ✅ show dialog only if suggestion exists
                } else {
                   _submit(); // ✅ fallback to normal submission
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.deepPurple, // ✅ Primary color
                foregroundColor: Colors.white,      // ✅ Text/Icon color
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
  String getMoodBasedSuggestion() {
    if (_selectedMood == 'calm') {
      return 'Early mornings (before 8 AM) offer calmer routes with less traffic.';
    } else if (_selectedMood == 'focus') {
      return 'Midday (10 AM – 2 PM) routes are efficient for focused tasks.';
    } else if (_selectedMood == 'energized') {
      return 'Evening hours (5 PM – 7 PM) offer vibrant routes and views.';
    }
    return '';
  }


}
