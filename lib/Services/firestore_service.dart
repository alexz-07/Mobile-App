import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> AddUser(User user) async{
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> UpdateUserInfo(User user, String role, String name, int age) async{
    await _firestore.collection('users').doc(user.uid).update({
      'role': role,
      'name': name,
      'age': age,
    });
  }

  Future<void> GetStudents(User teacher) async{
    await _firestore.collection('users').where('teacher', isEqualTo: teacher.uid).snapshots();
  }

  Future<String?> GetUserRole(User user) async{
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['role'];
  }

  Future<void> saveLearningLesson(
      String subject,
      String topic,
      String content,
      List<String>? images,
      bool isVisualLearner,
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('lesson_plans').add({
        'uid': user.uid,
        'subject': subject,
        'topic': topic,
        'content': content,
        'images': images ?? [],
        'isVisualLearner': isVisualLearner,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}