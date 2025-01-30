import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as calendar;
import 'package:ivisit/models/appointment.dart';



String formatDate(DateTime date) {
  return '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}';
}

Map<String, dynamic> aptToJson(calendar.Appointment appointment) {
    return {
      'startTime': appointment.startTime.toIso8601String(), 
      'endTime': appointment.endTime.toIso8601String(),
      'subject': appointment.subject,
      'color': appointment.color.value,
      'notes': appointment.notes,
    };
}


calendar.Appointment jsonToApt(Map<String, dynamic> json) {
    return calendar.Appointment(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      subject: json['subject'], 
      color: Color(json['color']) ?? Colors.blue,
      notes: json['note'] ?? '',
    );
}


calendar.Appointment customAppointment(Appointment appointment) => 
  calendar.Appointment(startTime: appointment.startTime, endTime: appointment.endTime, subject: '${appointment.contact.firstName} ${appointment.contact.lastName}');


Map<String, dynamic> appointmentToJson(calendar.Appointment appointment) {
  return {
    'startTime': appointment.startTime.toIso8601String(),
    'endTime': appointment.endTime.toIso8601String(),
    'subject': appointment.subject,
    'color': appointment.color.value,
    'notes': appointment.notes,
  };
}