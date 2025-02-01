import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsData = prefs.getString('appointments');

    if (appointmentsData != null) {
      setState(() {
        _appointments = (json.decode(appointmentsData) as List)
            .map((data) => Appointment.fromJson(data))
            .toList();
      });
    }
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDate = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: _buildAppointmentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, daysInMonth);
    final firstWeekday = firstDayOfMonth.weekday;
    final lastWeekday = lastDayOfMonth.weekday;

    List<Widget> dayWidgets = [];

    // Add empty widgets for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    // Add day widgets for each day of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDay = DateTime(_selectedDate.year, _selectedDate.month, day);
      dayWidgets.add(
        GestureDetector(
          onTap: () => _onDaySelected(currentDay),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: _selectedDate.day == day ? Colors.blue : Colors.white,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: _selectedDate.day == day ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add empty widgets for days after the last day of the month
    for (int i = lastWeekday; i < 7; i++) {
      dayWidgets.add(Container());
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      children: dayWidgets,
    );
  }

  Widget _buildAppointmentList() {
    final selectedDateAppointments = _appointments.where((appointment) {
      return appointment.startTime.year == _selectedDate.year &&
          appointment.startTime.month == _selectedDate.month &&
          appointment.startTime.day == _selectedDate.day;
    }).toList();

    return ListView.builder(
      itemCount: selectedDateAppointments.length,
      itemBuilder: (context, index) {
        final appointment = selectedDateAppointments[index];
        return ListTile(
          title: Text('${appointment.contact.firstName} ${appointment.contact.lastName}'),
          subtitle: Text('${appointment.startTime} - ${appointment.endTime}'),
        );
      },
    );
  }
}










// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_calendar/calendar.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import '../models/contact.dart';
// import '../models/appointment.dart' as apt;
// import '../widgets/contacts_page.dart';
// import '../utils.dart' as utils;

// class CalendarPage extends StatefulWidget {
//   const CalendarPage({super.key});

//   @override
//   CalendarPageState createState() => CalendarPageState();
// }

// class CalendarPageState extends State<CalendarPage> {
//   List<Appointment> appointments = [];
//   List<Contact> contacts = [];
//   CalendarDataSource _dataSource = AppointmentDataSource([]);

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final contactsData = prefs.getString('contacts');
//     final appointmentsData = prefs.getString('appointments');

//     if (contactsData != null) {
//       setState(() {
//         contacts = (json.decode(contactsData) as List)
//             .map((data) => Contact.fromJson(data))
//             .toList();
//       });
//     }

//     if (appointmentsData != null) {
//       setState(() {
//         final List<apt.Appointment> loadedAppointments = (json.decode(appointmentsData) as List)
//             .map((data) => apt.Appointment.fromJson(data))
//             .toList();
//         appointments = loadedAppointments.map((apt.Appointment appointment) {
//           return Appointment(
//             startTime: appointment.startTime,
//             endTime: appointment.endTime,
//             subject: '${appointment.contact.firstName} ${appointment.contact.lastName}',
//             //notes: appointment.contact.phoneNumber,
//           );
//         }).toList();
//         _dataSource = AppointmentDataSource(appointments);
//       });
//     } else {
//       _dataSource = AppointmentDataSource([]);
//     }
//   }

//   Future<void> _saveAppointments() async {
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setString('appointments', json.encode(appointments.map((appointment) => utils.appointmentToJson(appointment)).toList()));
//   }

//   void _handleAppointmentAdded(apt.Appointment appointment) {
//     setState(() {
//       appointments.add(utils.customAppointment(appointment));
//       _saveAppointments();
//       _dataSource = AppointmentDataSource(appointments);
//     });
//   }

//   void _handleAppointmentUpdated(Appointment oldAppointment, Appointment newAppointment) {
//     setState(() {
//       appointments.remove(oldAppointment);
//       appointments.add(newAppointment);
//       _saveAppointments();
//       _dataSource = AppointmentDataSource(appointments);
//     });
//   }

//   void _handleAppointmentDeleted(Appointment appointment) {
//     setState(() {
//       appointments.remove(appointment);
//       _saveAppointments();
//       _dataSource = AppointmentDataSource(appointments);
//     });
//   }

//   void _showAddAppointmentDialog(DateTime selectedDate) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ContactsPage(
//           contacts: contacts,
//           onContactSelected: (contact) {
//             final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0);
//             final DateTime endTime = startTime.add(const Duration(hours: 1));
//             final apt.Appointment newAppointment = apt.Appointment(
//               startTime: startTime,
//               endTime: endTime,
//               contact: contact,
//             );
//             _handleAppointmentAdded(newAppointment);
//             Navigator.pop(context);
//           },
//         ),
//       ),
//     );
//   }

//   void _showEditAppointmentDialog(Appointment appointment) {
//     final TextEditingController startTimeController = TextEditingController(text: appointment.startTime.toString());
//     final TextEditingController endTimeController = TextEditingController(text: appointment.endTime.toString());

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Edit Appointment'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Contact: ${appointment.subject}'),
//               TextField(
//                 controller: startTimeController,
//                 decoration: const InputDecoration(labelText: 'Start Time'),
//                 readOnly: true,
//                 onTap: () async {
//                   final TimeOfDay? pickedTime = await showTimePicker(
//                     context: context,
//                     initialTime: TimeOfDay.fromDateTime(appointment.startTime),
//                   );
//                   if (pickedTime != null) {
//                     final DateTime newStartTime = DateTime(
//                       appointment.startTime.year,
//                       appointment.startTime.month,
//                       appointment.startTime.day,
//                       pickedTime.hour,
//                       pickedTime.minute,
//                     );
//                     setState(() {
//                       appointment.startTime = newStartTime;
//                       startTimeController.text = newStartTime.toString();
//                     });
//                   }
//                 },
//               ),
//               TextField(
//                 controller: endTimeController,
//                 decoration: const InputDecoration(labelText: 'End Time'),
//                 readOnly: true,
//                 onTap: () async {
//                   final TimeOfDay? pickedTime = await showTimePicker(
//                     context: context,
//                     initialTime: TimeOfDay.fromDateTime(appointment.endTime),
//                   );
//                   if (pickedTime != null) {
//                     final DateTime newEndTime = DateTime(
//                       appointment.endTime.year,
//                       appointment.endTime.month,
//                       appointment.endTime.day,
//                       pickedTime.hour,
//                       pickedTime.minute,
//                     );
//                     setState(() {
//                       appointment.endTime = newEndTime;
//                       endTimeController.text = newEndTime.toString();
//                     });
//                   }
//                 },
//               ),
//             ],
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Save'),
//               onPressed: () {
//                 final Appointment updatedAppointment = Appointment(
//                   startTime: DateTime.parse(startTimeController.text),
//                   endTime: DateTime.parse(endTimeController.text),
//                   subject: appointment.subject,
//                 );
//                 _handleAppointmentUpdated(appointment, updatedAppointment);
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Delete'),
//               onPressed: () {
//                 _handleAppointmentDeleted(appointment);
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Calendar'),
//       ),
//       body: SfCalendar(
//         view: CalendarView.month,
//         allowedViews: const [
//           CalendarView.day,
//           CalendarView.week,
//           CalendarView.workWeek,
//           CalendarView.month,
//         ],
//         dataSource: _dataSource,
//         onTap: (details) {
//           if (details.targetElement == CalendarElement.appointment) {
//             final Appointment appointment = details.appointments!.first;
//             _showEditAppointmentDialog(appointment);
//           } else if (details.targetElement == CalendarElement.calendarCell) {
//             _showAddAppointmentDialog(details.date!);
//           }
//         },
//       ),
//     );
//   }
// }

// class AppointmentDataSource extends CalendarDataSource {
//   AppointmentDataSource(List<Appointment> source) {
//     appointments = source;
//   }
// }