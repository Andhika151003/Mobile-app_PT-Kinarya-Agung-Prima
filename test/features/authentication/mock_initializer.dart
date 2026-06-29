import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecommerce/core/firebase_provider.dart';

class MockAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements FirebaseFirestore {}

void initMockFirebase() {
  AppFirebase.mockAuth = MockAuth();
  AppFirebase.mockFirestore = MockFirestore();
}