//import 'package:flutter/material.dart';
//mport 'package:shared_preferences/shared_preferences.dart';
//import 'package:syncfusion_flutter_calendar/calendar.dart' as calendar;
import 'package:ivisit/models/appointment.dart';
//import 'widgets/contacts_page.dart';


String formatDate(DateTime date) {
  return '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}';
}


Map<String, dynamic> aptToJson(Appointment appointment) {
    return {
      'startTime': appointment.startTime.toIso8601String(), 
      'endTime': appointment.endTime.toIso8601String(),
      'contact': appointment.contact
    };
}


Appointment jsonToApt(Map<String, dynamic> json) {
    return Appointment(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      contact: json['contact'],
    );
}


Appointment customAppointment(Appointment appointment) => 
  Appointment(startTime: appointment.startTime, endTime: appointment.endTime, contact: appointment.contact);


Map<String, dynamic> appointmentToJson(Appointment appointment) {
  return {
    'startTime': appointment.startTime.toIso8601String(),
    'endTime': appointment.endTime.toIso8601String(),
    'contact': appointment.contact
  };
}

