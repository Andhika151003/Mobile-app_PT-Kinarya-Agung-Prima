import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppFirebase {
  static FirebaseAuth? mockAuth;
  static FirebaseFirestore? mockFirestore;

  static FirebaseAuth get auth => mockAuth ?? FirebaseAuth.instance;
  static FirebaseFirestore get firestore => mockFirestore ?? FirebaseFirestore.instance;

  static bool get isMocked => mockAuth != null;
}
