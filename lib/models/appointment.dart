import 'contact.dart';


class Appointment {
  final DateTime startTime;
  final DateTime endTime;
  final Contact contact;

  Appointment({required this.startTime, required this.endTime, required this.contact});

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      contact: json['contact'] != null ? Contact.fromJson(json['contact']) : Contact(firstName: 'na', lastName: 'na') //throw ArgumentError('Contact cannot be null'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'contact': contact.toJson(),
    };
  }
}

