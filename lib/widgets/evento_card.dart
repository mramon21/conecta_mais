import 'package:cached_network_image/cached_network_image.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/screens/pages/details_event_page.dart';
import 'package:flutter/material.dart';

class EventoCard extends StatelessWidget {
  const EventoCard({super.key, required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.only(right: 12),
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsEventPage(evento: evento)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 135,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventImage(url: evento.imagemEvento),
                if (!evento.temVagas)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          'ESGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.nomeEvento,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  evento.localEvento,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  evento.dataHoraFormatada,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class EventImage extends StatelessWidget {
  const EventImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    if (!url!.startsWith('http')) return _fallback();
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      useOldImageOnUrlChange: true,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Container(
    color: Colors.grey.shade300,
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: Colors.grey,
      size: 42,
    ),
  );
}
