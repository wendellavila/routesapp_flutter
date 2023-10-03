import 'dart:async' show Timer;
import 'dart:convert' show jsonEncode;
import 'dart:math' as math show cos, sqrt, asin, pi;

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:searchable_paginated_dropdown/searchable_paginated_dropdown.dart';
import 'package:flutter_polyline_no_xmlhttperror/flutter_polyline_no_xmlhttperror.dart';

import 'package:routesapp/ui/widgets/appbar.dart';
import 'package:routesapp/services/json_handler.dart' as json_handler;
import 'package:routesapp/services/geolocation.dart' as geolocation;

const String _googleAPIKey = "";

class MapViewer extends StatefulWidget {
  const MapViewer({super.key});

  @override
  State<MapViewer> createState() => _MapViewerState();
}

class _MapViewerState extends State<MapViewer> {
  late GoogleMapController _mapController;
  bool _isMapScrollable = true;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Map<int, Map> _destinations = {};
  final Map<int, Map> _origins = {
    0: {
      'name': "Posição Atual",
      'address': "",
      'city': "",
      'state': "",
      'address2': "",
      'postalcode': "",
      'country': "",
      'lat': -21.3064013,
      'lng': -46.7106383
    },
    1: {
      'name': "Praça da Saudade",
      'address': "Praça da Saudade",
      'city': "Guaxupé",
      'state': "MG",
      'address2': "Centro",
      'postalcode': "37800-000",
      'country': "Brazil",
      'lat': -21.3064013,
      'lng': -46.7106383
    },
  };

  int? _originId;
  int? _destinationId;
  double? _distance;
  Timer? _periodicLocationUpdater;
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern("pt-Br");

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (_periodicLocationUpdater != null) {
      _periodicLocationUpdater!.cancel();
    }
  }

  Future<bool> _updateCurrentLocation() async {
    try {
      Position currentPosition = await geolocation.getPosition();
      _origins[0]!['lat'] = currentPosition.latitude;
      _origins[0]!['lng'] = currentPosition.longitude;
      return true;
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> _loadDestinations(
      {String url = "", String filename = "destinations.json"}) async {
    //try to get from url
    //http://intranet/wendell/fornecedores_lat_lng/gera_json.php

    Map jsonMap = await json_handler.postFromUrl(url);

    //if unavailable, try to get from local storage on mobile/desktop
    if (jsonMap.isEmpty && !kIsWeb) {
      if (await json_handler.localFileExists(filename)) {
        jsonMap = await json_handler.readFromLocalPath(filename);
      }
    }

    //if unavailable, get from assets
    if (jsonMap.isEmpty) {
      jsonMap = await json_handler.readFromAssets("assets/json/$filename");
    }
    //write to local storage on mobile/desktop
    if (!kIsWeb) {
      json_handler.writeToLocalPath(filename, jsonEncode(jsonMap));
    }

    jsonMap = Map.fromEntries(jsonMap.entries.toList()
      ..sort((e1, e2) => e1.value['name'].compareTo(e2.value['name'])));

    jsonMap.forEach((key, value) {
      try {
        value['lat'] = double.parse(value['lat'].toString());
        value['lng'] = double.parse(value['lng'].toString());
      } on FormatException {
        value['lat'] = 0.0;
        value['lng'] = 0.0;
      }
      _destinations[int.parse(key.toString())] = value;
    });
  }

  Future<List<SearchableDropdownMenuItem<int>>>
      _populateDestinationsDropdown() async {
    List<SearchableDropdownMenuItem<int>> destinationsEntryList = [];

    await _loadDestinations();

    _destinations.forEach((k, v) {
      destinationsEntryList.add(SearchableDropdownMenuItem(
          value: k,
          label:
              "${v['name']} - ${v['address']}, ${v['address2']}, ${v['city']} - ${v['state']}",
          child: Text(
            "${v['name']} - ${v['address']}, ${v['address2']}, ${v['city']} - ${v['state']}",
          )));
    });
    return destinationsEntryList;
  }

  Future<List<SearchableDropdownMenuItem<int>>>
      _populateOriginsDropdown() async {
    List<SearchableDropdownMenuItem<int>> originsEntryList = [];

    _origins.forEach((k, v) {
      SearchableDropdownMenuItem<int> item;
      if (k == 0) {
        item = SearchableDropdownMenuItem(
            value: k,
            label: "${v['name']}",
            child: Text(
              "${v['name']}",
            ));
      } else {
        item = SearchableDropdownMenuItem(
            value: k,
            label:
                "${v['name']} - ${v['address']}, ${v['address2']}, ${v['city']} - ${v['state']}",
            child: Text(
              "${v['name']} - ${v['address']}, ${v['address2']}, ${v['city']} - ${v['state']}",
            ));
      }
      originsEntryList.add(item);
    });
    return originsEntryList;
  }

  bool _isDestinationValid() {
    return _destinations.containsKey(_destinationId) &&
        _destinations[_destinationId]!['lat'] != null &&
        _destinations[_destinationId]!['lng'] != null;
  }

  bool _isOriginValid() {
    return _origins.containsKey(_originId) &&
        _origins[_originId]!['lat'] != null &&
        _origins[_originId]!['lng'] != null;
  }

  void _createOriginMarker() async {
    if (_isOriginValid()) {
      String snippet = "";
      if (_originId! > 0) {
        if (kIsWeb) {
          snippet += "${_origins[_originId]!['address']} - ";
          snippet += "${_origins[_originId]!['address2']}<br>";
          snippet += "${_origins[_originId]!['city']} - ";
          snippet += "${_origins[_originId]!['state']}<br>";
          snippet += "${_origins[_originId]!['postalcode']}<br>";
          snippet += "${_origins[_originId]!['country']}<br>";
        } else {
          snippet += "${_origins[_originId]!['address']} - ";
          snippet += "${_origins[_originId]!['address2']}\n";
          snippet += "${_origins[_originId]!['city']} - ";
          snippet += "${_origins[_originId]!['state']}\n";
          snippet += "${_origins[_originId]!['postalcode']}\n";
          snippet += "${_origins[_originId]!['country']}\n";
        }
      }
      if (kIsWeb) {
        snippet += '<a target="_blank" href="https://google.com/maps/search/';
        snippet +=
            '${_origins[_originId]!['lat']},${_origins[_originId]!['lng']}';
        snippet += '">Visualize no Google Maps</a>';
      }
      setState(() {
        _markers.add(Marker(
            markerId: const MarkerId("origin"),
            position: LatLng(
                _origins[_originId]!['lat'], _origins[_originId]!['lng']),
            infoWindow: InfoWindow(
                title: _origins[_originId]!['name'], snippet: snippet)));
      });
    }
  }

  void _createMarkers() {
    _markers.clear();
    _createOriginMarker();
    if (_isDestinationValid()) {
      String snippet = "";
      if (kIsWeb) {
        snippet += "${_destinations[_destinationId]!['address']} - ";
        snippet += "${_destinations[_destinationId]!['address2']}<br>";
        snippet += "${_destinations[_destinationId]!['city']} - ";
        snippet += "${_destinations[_destinationId]!['state']}<br>";
        snippet += "${_destinations[_destinationId]!['postalcode']}<br>";
        snippet += "${_destinations[_destinationId]!['country']}<br>";
        snippet += '<a target="_blank" href="https://google.com/maps/search/';
        snippet +=
            '${_destinations[_destinationId]!['lat']},${_destinations[_destinationId]!['lng']}';
        snippet += '">Visualize no Google Maps</a>';
      } else {
        snippet += "${_destinations[_destinationId]!['address']} - ";
        snippet += "${_destinations[_destinationId]!['address2']}\n";
        snippet += "${_destinations[_destinationId]!['city']} - ";
        snippet += "${_destinations[_destinationId]!['state']}\n";
        snippet += "${_destinations[_destinationId]!['postalcode']}\n";
        snippet += "${_destinations[_destinationId]!['country']}\n";
      }
      setState(() {
        _markers.add(Marker(
            markerId: const MarkerId("destination"),
            position: LatLng(_destinations[_destinationId]!['lat'],
                _destinations[_destinationId]!['lng']),
            infoWindow: InfoWindow(
                title: _destinations[_destinationId]!['name'],
                snippet: snippet)));
      });
    }
  }

  void _focusCameraOnRoute() {
    // https://blog.codemagic.io/creating-a-route-calculator-using-google-maps/#placing-markers
    double startLatitude = _origins[_originId]!['lat'];
    double startLongitude = _origins[_originId]!['lng'];
    double destinationLatitude = _destinations[_destinationId]!['lat'];
    double destinationLongitude = _destinations[_destinationId]!['lng'];

    double miny = (startLatitude <= destinationLatitude)
        ? startLatitude
        : destinationLatitude;
    double minx = (startLongitude <= destinationLongitude)
        ? startLongitude
        : destinationLongitude;
    double maxy = (startLatitude <= destinationLatitude)
        ? destinationLatitude
        : startLatitude;
    double maxx = (startLongitude <= destinationLongitude)
        ? destinationLongitude
        : startLongitude;

    double southWestLatitude = miny;
    double southWestLongitude = minx;

    double northEastLatitude = maxy;
    double northEastLongitude = maxx;

    // Accommodate the two locations within the
    // camera view of the map
    setState(() {
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );
    });
  }

  void _focusCameraOnOrigin() {
    if (_isOriginValid()) {
      setState(() {
        _mapController.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(_origins[_originId]!['lat'], _origins[_originId]!['lng']),
            12));
      });
    }
  }

  void _focusCameraOnDestination() {
    if (_isDestinationValid()) {
      setState(() {
        _mapController.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(_destinations[_destinationId]!['lat'],
                _destinations[_destinationId]!['lng']),
            12));
      });
    }
  }

  void _animateCamera() {
    if (_isOriginValid() && _isDestinationValid()) {
      _focusCameraOnRoute();
    } else if (_isOriginValid()) {
      _focusCameraOnOrigin();
    } else if (_isDestinationValid()) {
      _focusCameraOnDestination();
    }
  }

  void _createRoute() async {
    _polylines.clear();

    if (_isOriginValid() && _isDestinationValid()) {
      LatLng origin =
          LatLng(_origins[_originId]!['lat'], _origins[_originId]!['lng']);
      LatLng destination = LatLng(_destinations[_destinationId]!['lat'],
          _destinations[_destinationId]!['lng']);

      PolylinePoints polylineGenerator = PolylinePoints(_googleAPIKey);
      List<LatLng> polylineCoordinates = await polylineGenerator
          .getRouteBetweenCoordinates(origin, destination);

      setState(() {
        _polylines.add(Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            points: polylineCoordinates,
            width: 4));
        _distance = _getRouteDistanceInKm(polylineCoordinates);
      });
    } else {
      _distance = null;
    }
  }

  double _getRouteDistanceInKm(List<LatLng> polylineCoordinates) {
    // Haversine formula calculated over each point pair in polyline
    // https://stackoverflow.com/questions/27928/calculate-distance-between-two-latitude-longitude-points-haversine-formula#21623206

    const r = 6371; // Radius of the earth in km (Volumetric mean radius)
    const p = math.pi / 180;
    double distance = 0.0;

    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      final LatLng origin = polylineCoordinates[i];
      final LatLng destination = polylineCoordinates[i + 1];

      final a = 0.5 -
          math.cos((destination.latitude - origin.latitude) * p) / 2 +
          math.cos(origin.latitude * p) *
              math.cos(destination.latitude * p) *
              (1 - math.cos((destination.longitude - origin.longitude) * p)) /
              2;

      distance += (2 * r * math.asin(math.sqrt(a)));
    }
    return distance;
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    _populateOriginsDropdown();
  }

  Widget _originsDropdown(bool isWide) {
    return SearchableDropdown<int>.future(
      width: isWide ? null : MediaQuery.of(context).size.width * 0.48,
      backgroundDecoration: (child) => DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.secondary),
        child: child,
      ),
      margin: const EdgeInsets.all(10),
      searchHintText: "Pesquise por nome ou endereço",
      hintText: const Text('Origem'),
      noRecordText: const Text("Nenhum endereço disponível"),
      leadingIcon: const Padding(
        padding: EdgeInsets.only(right: 10),
        child: Icon(Icons.search),
      ),
      futureRequest: _populateOriginsDropdown,
      onChanged: (int? value) async {
        if (value == 0) {
          bool updateSuccess =
              await _updateCurrentLocation().catchError((error) {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    icon: Icon(
                      Icons.wrong_location,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                    title: const Text(
                      "Não foi possível acessar a localização atual",
                    ),
                    content: Text(
                      error,
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          'FECHAR',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onError),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  );
                });
            return false;
          });
          if (updateSuccess) {
            if (_periodicLocationUpdater == null ||
                !_periodicLocationUpdater!.isActive) {
              _periodicLocationUpdater =
                  Timer.periodic(const Duration(seconds: 15), (timer) {
                _updateCurrentLocation().then((_) => setState(() {}));
              });
            }
          }
        } else {
          if (_periodicLocationUpdater != null) {
            _periodicLocationUpdater?.cancel();
          }
        }
        _originId = value;
        _createMarkers();
        _animateCamera();
        _createRoute();
      },
      onShowDropdown: () {
        setState(() {
          _isMapScrollable = false;
        });
      },
      onDismissDropdown: () {
        setState(() {
          _isMapScrollable = true;
        });
      },
    );
  }

  Widget _destinationsDropdown(bool isWide) {
    return SearchableDropdown<int>.future(
      width: isWide ? null : MediaQuery.of(context).size.width * 0.48,
      backgroundDecoration: (child) => DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.secondary),
        child: child,
      ),
      margin: const EdgeInsets.all(10),
      searchHintText: "Pesquise por nome ou endereço",
      hintText: const Text('Destino'),
      noRecordText: const Text("Nenhum endereço disponível"),
      leadingIcon: const Padding(
        padding: EdgeInsets.only(right: 10),
        child: Icon(Icons.search),
      ),
      futureRequest: _populateDestinationsDropdown,
      onChanged: (int? value) {
        _destinationId = value;
        _createMarkers();
        _animateCamera();
        _createRoute();
      },
      onShowDropdown: () {
        setState(() {
          _isMapScrollable = false;
        });
      },
      onDismissDropdown: () {
        setState(() {
          _isMapScrollable = true;
        });
      },
    );
  }

  Widget _mapViewerBody() {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Selecione as localizações desejadas:",
                style: TextStyle(fontSize: 16),
              ),
            ),
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return Column(
                  children: [
                    _originsDropdown(true),
                    const SizedBox(
                      height: 5,
                    ),
                    _destinationsDropdown(true),
                  ],
                );
              } else {
                return Row(
                  children: [
                    _originsDropdown(false),
                    const Spacer(),
                    _destinationsDropdown(false),
                  ],
                );
              }
            }),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: GoogleMap(
                  mapToolbarEnabled: true,
                  scrollGesturesEnabled: _isMapScrollable,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                      target: LatLng(_origins[0]!['lat'], _origins[0]!['lng']),
                      zoom: 12),
                  markers: _markers,
                  polylines: _polylines,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            if (_distance != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(
                        Icons.directions,
                        color: Color(0XFF5491f5),
                        size: 22,
                      ),
                    ),
                    Text(
                      "Distância: ${_numberFormatter.format(_distance)} Km",
                      style: const TextStyle(fontSize: 18),
                    )
                  ],
                ),
              ),
            ElevatedButton.icon(
              icon: Icon(
                Icons.pin_drop,
                color: (_isOriginValid() && _isDestinationValid())
                    ? const Color(0XFFFFFFFF)
                    : const Color(0XFF898682),
              ),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                child: Text(
                  "Ver rota no Google Maps",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              onPressed: (_isOriginValid() && _isDestinationValid())
                  ? () async {
                      String url = "https://www.google.com/maps/dir/";
                      url +=
                          "'${_origins[_originId]!['lat']},${_origins[_originId]!['lng']}'/";
                      url +=
                          "'${_destinations[_destinationId]!['lat']},${_destinations[_destinationId]!['lng']}'/";
                      Uri uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  : null /* Button Disabled */,
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                  backgroundColor: Theme.of(context).colorScheme.tertiary),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: _mapViewerBody(),
    );
  }
}
