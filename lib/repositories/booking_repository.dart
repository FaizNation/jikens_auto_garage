import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a new booking using FieldValue.serverTimestamp() 
  /// to ensure strict FCFS ordering based on Google's servers.
  Future<void> createBooking(BookingModel booking) async {
    final docRef = _firestore.collection('bookings').doc();
    
    final data = booking.toJson();
    // CRITICAL: Inject the server timestamp for strict FCFS logic
    data['created_at'] = FieldValue.serverTimestamp();

    await docRef.set(data);
  }

  /// Admin view: Streams all bookings ordered strictly by created_at (FCFS logic).
  Stream<List<BookingModel>> streamAdminQueue() {
    return _firestore
        .collection('bookings')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  /// User view: Streams the active booking for a specific user to monitor their status.
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data(), doc.id))
          .toList();
      
      // Sort locally to avoid needing a Firestore Composite Index
      bookings.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1; // Put nulls (pending server timestamp) at top
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!); // descending order
      });
      
      return bookings;
    });
  }
  
  /// Update booking status (used by admin)
  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': newStatus.name,
    });
  }
}
