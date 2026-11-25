import 'package:conecta_mais/service/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLocationPickerPage extends StatefulWidget {
  const MapLocationPickerPage({super.key, this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  static const _brazilCenter = LatLng(-14.235, -51.9253);
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null &&
        widget.longitude != null &&
        widget.latitude!.isFinite &&
        widget.longitude!.isFinite &&
        widget.latitude! >= -90 &&
        widget.latitude! <= 90 &&
        widget.longitude! >= -180 &&
        widget.longitude! <= 180) {
      _selectedLocation = LatLng(widget.latitude!, widget.longitude!);
    }
  }

  Future<void> _centerOnUser() async {
    try {
      final position = await determineUserPosition();
      if (!mounted) return;
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedLocation ?? _brazilCenter;
    return Scaffold(
      appBar: AppBar(title: const Text('Localização do evento')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Toque no mapa para marcar o local do evento.'),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: _selectedLocation == null ? 4.5 : 15,
                onTap: (_, point) => setState(() => _selectedLocation = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.conecta_mais',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.location_pin,
                          color: Theme.of(context).colorScheme.error,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedLocation != null)
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                      '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                    )
                  else
                    const Text('Nenhum ponto selecionado'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _centerOnUser,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Minha localização'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _selectedLocation == null
                              ? null
                              : () => Navigator.pop(context, _selectedLocation),
                          child: const Text('Usar este local'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
