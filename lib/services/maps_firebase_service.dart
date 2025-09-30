import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/route_model.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class MapsFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  CollectionReference get _routesCollection => _firestore.collection('routes');
  CollectionReference get _favoritesCollection => _firestore.collection('favorites');
  CollectionReference get _navigationHistoryCollection => _firestore.collection('navigation_history');
  
  // Save route to history
  Future<void> saveRouteToHistory(RouteInfo route) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Convert route to map
    Map<String, dynamic> routeMap = {
      'userId': user.uid,
      'startLocation': {
        'latitude': route.startLocation.latitude,
        'longitude': route.startLocation.longitude,
      },
      'endLocation': {
        'latitude': route.endLocation.latitude,
        'longitude': route.endLocation.longitude,
      },
      'totalDistance': route.totalDistance,
      'estimatedTotalTime': route.estimatedTotalTime.inSeconds,
      'routeType': route.routeType.toString().split('.').last,
      'trafficCondition': route.trafficCondition.toString().split('.').last,
      'safetyScore': route.safetyScore,
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    // Save to Firestore
    await _navigationHistoryCollection.add(routeMap);
  }
  
  // Get navigation history
  Future<List<Map<String, dynamic>>> getNavigationHistory() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    QuerySnapshot snapshot = await _navigationHistoryCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
  
  // Save favorite location
  Future<void> saveFavoriteLocation(String name, LatLng location, String icon) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    Map<String, dynamic> favoriteMap = {
      'userId': user.uid,
      'name': name,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'icon': icon,
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    await _favoritesCollection.add(favoriteMap);
  }
  
  // Get favorite locations
  Future<List<Map<String, dynamic>>> getFavoriteLocations() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    QuerySnapshot snapshot = await _favoritesCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
  
  // Delete favorite location
  Future<void> deleteFavoriteLocation(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    DocumentSnapshot doc = await _favoritesCollection.doc(id).get();
    if (!doc.exists) {
      throw Exception('Favorite location not found');
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != user.uid) {
      throw Exception('Not authorized to delete this favorite location');
    }
    
    await _favoritesCollection.doc(id).delete();
  }
  
  // Save custom route
  Future<String> saveCustomRoute(RouteInfo route, String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Convert polyline points to list of maps
    List<Map<String, double>> points = route.polylinePoints.map((point) {
      return {
        'latitude': point.latitude,
        'longitude': point.longitude,
      };
    }).toList();
    
    Map<String, dynamic> routeMap = {
      'userId': user.uid,
      'name': name,
      'startLocation': {
        'latitude': route.startLocation.latitude,
        'longitude': route.startLocation.longitude,
      },
      'endLocation': {
        'latitude': route.endLocation.latitude,
        'longitude': route.endLocation.longitude,
      },
      'polylinePoints': points,
      'totalDistance': route.totalDistance,
      'estimatedTotalTime': route.estimatedTotalTime.inSeconds,
      'routeType': route.routeType.toString().split('.').last,
      'safetyScore': route.safetyScore,
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    // Save to Firestore
    DocumentReference docRef = await _routesCollection.add(routeMap);
    return docRef.id;
  }
  
  // Get saved routes
  Future<List<Map<String, dynamic>>> getSavedRoutes() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    QuerySnapshot snapshot = await _routesCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
  
  // Delete saved route
  Future<void> deleteSavedRoute(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    DocumentSnapshot doc = await _routesCollection.doc(id).get();
    if (!doc.exists) {
      throw Exception('Route not found');
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != user.uid) {
      throw Exception('Not authorized to delete this route');
    }
    
    await _routesCollection.doc(id).delete();
  }
  
  // Update user's current location
  Future<void> updateUserLocation(LatLng location) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    await _firestore.collection('users').doc(user.uid).update({
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }
    });
  }
}