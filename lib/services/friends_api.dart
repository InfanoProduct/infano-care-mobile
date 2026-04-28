import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import '../models/friend_profile.dart';

class FriendsApi {
  final Dio _dio;

  FriendsApi(this._dio);

  Future<FriendProfile?> getProfile() async {
    final response = await _dio.get('/friends/profile');
    if (response.data != null && response.data.toString().isNotEmpty && response.data['id'] != null) {
      return FriendProfile.fromJson(response.data);
    }
    return null;
  }

  Future<void> optInAndSetupProfile(Map<String, dynamic> profileData) async {
    // Permission was already requested and granted on the Location Privacy step.
    // Just get the current position directly.
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    // Geohash generation
    final geoHasher = GeoHasher();
    final geohash = geoHasher.encode(position.longitude, position.latitude, precision: 5);

    // Send to API
    final payload = {
      'isActive': true,
      'geohash': geohash,
      ...profileData,
    };

    await _dio.post('/friends/profile', data: payload);
  }

  Future<List<FriendProfile>> discoverProfiles({int batchSize = 20, String radius = 'city'}) async {
    final response = await _dio.get('/friends/discover', queryParameters: {
      'batch_size': batchSize,
      'radius': radius,
    });
    if (response.data != null && response.data['profiles'] is List) {
      return (response.data['profiles'] as List).map((e) => FriendProfile.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<FriendProfile>> getSavedProfiles() async {
    final response = await _dio.get('/friends/saved');
    if (response.data != null && response.data['saved_profiles'] is List) {
      return (response.data['saved_profiles'] as List).map((e) => FriendProfile.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> swipeFriend(String targetId, String action) async {
    final response = await _dio.post('/friends/swipe', data: {
      'targetId': targetId,
      'action': action,
    });
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getMatches({String? status}) async {
    final response = await _dio.get('/friends/matches', queryParameters: {
      if (status != null) 'status': status,
    });
    if (response.data != null && response.data['matches'] is List) {
      return List<Map<String, dynamic>>.from(response.data['matches']);
    }
    return [];
  }

  Future<bool> unmatch(String matchId) async {
    final response = await _dio.delete('/friends/matches/$matchId');
    return response.data['unmatched'] == true;
  }

  Future<Map<String, dynamic>> getChatMessages(String matchId, {int page = 1}) async {
    final response = await _dio.get('/friends/chats/$matchId/messages', queryParameters: {
      'page': page,
    });
    return response.data;
  }

  Future<void> reportMatch(String matchId, String reason, {String? note}) async {
    await _dio.post('/friends/chats/$matchId/report', data: {
      'reason': reason,
      'note': note,
    });
  }

  Future<void> blockMatch(String matchId) async {
    await _dio.post('/friends/chats/$matchId/block');
  }

  Future<void> toggleDiscovery(bool isActive) async {
    await _dio.put('/friends/profile/toggle-discovery', data: {'isActive': isActive});
  }

  Future<void> deleteProfile() async {
    await _dio.delete('/friends/profile');
  }
}
