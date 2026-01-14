import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList(),
      );
});
