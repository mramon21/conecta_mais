import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/screens/pages/details_event_page.dart';
import 'package:conecta_mais/service/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyEventsMap extends StatefulWidget {
  const NearbyEventsMap({super.key, required this.events});

  final List<Evento> events;

  @override
  State<NearbyEventsMap> createState() => _NearbyEventsMapState();
}

class _NearbyEventsMapState extends State<NearbyEventsMap> {
  static const double _radiusMeters = 50000;
  Position? _userPosition;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPosition();
  }

  Future<void> _loadUserPosition() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final position = await determineUserPosition();
      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _isLoading = false;
      });
    }
  }

  List<({Evento event, double distance})> _nearbyEvents(Position position) {
    final nearby = <({Evento event, double distance})>[];
    for (final event in widget.events) {
      if (!event.temCoordenadas) continue;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        event.latitude!,
        event.longitude!,
      );
      if (distance <= _radiusMeters) {
        nearby.add((event: event, distance: distance));
      }
    }
    nearby.sort((a, b) => a.distance.compareTo(b.distance));
    return nearby;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final position = _userPosition;
    final nearby = position == null ? const [] : _nearbyEvents(position);
    final mapPoints = position == null
        ? const <LatLng>[]
        : [
            LatLng(position.latitude, position.longitude),
            for (final event in nearby)
              LatLng(event.event.latitude!, event.event.longitude!),
          ];
    final eventsWithoutLocation = widget.events.any(
      (event) => !event.temCoordenadas,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eventos em um raio de 50 km',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : position == null
                  ? _LocationError(
                      message:
                          _error ?? 'Não foi possível obter sua localização.',
                      onRetry: _loadUserPosition,
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          key: ValueKey(
                            '${position.latitude},${position.longitude}',
                          ),
                          options: MapOptions(
                            initialCameraFit: CameraFit.coordinates(
                              coordinates: mapPoints,
                              padding: const EdgeInsets.all(36),
                              maxZoom: 13,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.conecta_mais',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    position.latitude,
                                    position.longitude,
                                  ),
                                  width: 42,
                                  height: 42,
                                  child: Icon(
                                    Icons.my_location,
                                    color: colorScheme.primary,
                                    size: 32,
                                  ),
                                ),
                                for (final nearbyEvent in nearby)
                                  Marker(
                                    point: LatLng(
                                      nearbyEvent.event.latitude!,
                                      nearbyEvent.event.longitude!,
                                    ),
                                    width: 44,
                                    height: 50,
                                    child: IconButton(
                                      tooltip: nearbyEvent.event.nomeEvento,
                                      padding: EdgeInsets.zero,
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailsEventPage(
                                            evento: nearbyEvent.event,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.location_pin,
                                        color: colorScheme.error,
                                        size: 42,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  'OpenStreetMap contributors',
                                  onTap: () => launchUrl(
                                    Uri.parse(
                                      'https://openstreetmap.org/copyright',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                nearby.isEmpty
                                    ? 'Nenhum evento com localização nos próximos 50 km.'
                                          '${eventsWithoutLocation ? ' Eventos sem ponto marcado não aparecem.' : ''}'
                                    : '${nearby.length} evento(s) nos próximos 50 km'
                                          '${eventsWithoutLocation ? ' • eventos sem ponto marcado não aparecem' : ''}',
                                style: TextStyle(color: colorScheme.onSurface),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
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

class _LocationError extends StatelessWidget {
  const _LocationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}
