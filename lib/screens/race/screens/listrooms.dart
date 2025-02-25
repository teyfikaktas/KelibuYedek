// rooms_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  Stream<List<Map<String, dynamic>>>? _roomsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    // Debug için önce normal sorgu
    Supabase.instance.client
        .from('rooms')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .then((data) {
      print('Debug - Direct query response: $data');
    });

    // Stream'i düzgün şekilde oluşturalım
    _roomsStream = Supabase.instance.client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('created_at', ascending: false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktif Odalar'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          print('Debug - Connection state: ${snapshot.connectionState}');
          print('Debug - Has data: ${snapshot.hasData}');
          print('Debug - Data content: ${snapshot.data}');

          if (snapshot.hasError) {
            print('Stream error: ${snapshot.error}');
            return Center(
              child: Text('Bir hata oluştu: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final List<Room> rooms = [];
          if (snapshot.hasData) {
            print('Data length: ${snapshot.data!.length}');
            for (var item in snapshot.data!) {
              try {
                print('Processing item: $item');
                rooms.add(Room.fromJson(item));
              } catch (e) {
                print('Room parse error: $e');
                print('Failed item data: $item');
              }
            }
          }

          if (rooms.isEmpty) {
            return const Center(
              child: Text('Henüz aktif oda bulunmuyor'),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              print('Rendering room: ${room.roomCode}');
              return RoomCard(room: room);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final response = await Supabase.instance.client
                .from('rooms')
                .insert({
              'room_code': 'TEST${DateTime.now().millisecondsSinceEpoch}',
              'created_by': 12,  // String yerine integer kullanıyoruz
              'status': 'active',
              'player_count': 4,
              'created_at': DateTime.now().toIso8601String(),
            })
                .select()
                .single();

            print('Debug - New room created: $response');

            // Kontrol için tüm odaları listeleyelim
            final allRooms = await Supabase.instance.client
                .from('rooms')
                .select();
            print('Debug - All rooms after insert: $allRooms');

          } catch (e) {
            print('Debug - Room creation error detail: $e');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
class RoomCard extends StatelessWidget {
  final Room room;

  const RoomCard({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purpleAccent.withOpacity(0.2),
          child: Text(
            room.roomCode.substring(0, 1),
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Oda: ${room.roomCode}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Oluşturan: ${room.createdBy}'),
            const SizedBox(height: 2),
            Text(
              '${room.playerCount} Oyuncu',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDate(room.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          // Odaya katılma işlevi buraya gelecek
          print('Odaya katılınıyor: ${room.roomCode}');
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}