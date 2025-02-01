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
      contact: Contact.fromJson(json['contact']), //json['contact'],
    );
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'contact': contact.toJson(),
      };
    } catch (e) {
      print(e);
      return {};
    }
    // return {
    //   'startTime': startTime.toIso8601String(),
    //   'endTime': endTime.toIso8601String(),
    //   'contact': contact.toJson(),
    // };
  }
}

