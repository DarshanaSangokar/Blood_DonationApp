import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_ese/algorithm/halgorithm.dart';

Future<List<Map<String, dynamic>>> fetchNearbyDonors(
    double userLat, double userLon, double radiusKm) async {
  final donorsSnapshot =
      await FirebaseFirestore.instance.collection('donors').get();
  List<Map<String, dynamic>> nearbyDonors = [];

  for (var doc in donorsSnapshot.docs) {
    final data = doc.data();
    if (data['location'] != null) {
      final location = data['location'].split(','); // Format: "lat,lon"
      final donorLat = double.parse(location[0]);
      final donorLon = double.parse(location[1]);
      final distance = calculateDistance(userLat, userLon, donorLat, donorLon);

      if (distance <= radiusKm) {
        nearbyDonors.add(data);
      }
    }
  }

  return nearbyDonors;
}
