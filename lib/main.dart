import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/contact.dart';
import 'models/appointment.dart';
import 'widgets/contacts_page.dart';
import 'utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iVisit',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Contact> contacts = [];
  List<Appointment> appointments = [];
  String _viewType = 'Daily';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsData = prefs.getString('contacts');
    final appointmentsData = prefs.getString('appointments');

    if (contactsData != null) {
      setState(() {
        contacts = (json.decode(contactsData) as List)
            .map((data) => Contact.fromJson(data))
            .toList();
      });
    }

    if (appointmentsData != null) {
      setState(() {
        appointments = (json.decode(appointmentsData) as List)
            .map((data) => Appointment.fromJson(data))
            .toList();
      });
    }
  }

  Future<void> _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appointments', jsonEncode(appointments.map((a) => a.toJson()).toList()));
  }

  void _onAppointmentAdded(Appointment appointment) {
    setState(() {
      appointments.add(appointment);
      _saveAppointments();
    });
  }

  void _onAppointmentUpdated(Appointment oldAppointment, Appointment newAppointment) {
    setState(() {
      appointments.remove(oldAppointment);
      appointments.add(newAppointment);
      _saveAppointments();
    });
  }

  void _onAppointmentDeleted(Appointment appointment) {
    setState(() {
      appointments.remove(appointment);
      _saveAppointments();
    });
  }

  void _showAddAppointmentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactsPage(
          contacts: contacts,
          onContactSelected: (contact) {
            final DateTime selectedDate = DateTime.now();
            final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0);
            final DateTime endTime = startTime.add(const Duration(hours: 1));
            final Appointment newAppointment = Appointment(
              startTime: startTime,
              endTime: endTime,
              contact: contact,
            );
            _onAppointmentAdded(newAppointment);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showEditAppointmentDialog(Appointment appointment) {
    final TextEditingController startTimeController = TextEditingController(text: appointment.startTime.toString());
    final TextEditingController endTimeController = TextEditingController(text: appointment.endTime.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contact: ${appointment.contact.firstName} ${appointment.contact.lastName}'),
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time'),
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(appointment.startTime),
                  );
                  if (pickedTime != null) {
                    final DateTime newStartTime = DateTime(
                      appointment.startTime.year,
                      appointment.startTime.month,
                      appointment.startTime.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    setState(() {
                      final updatedAppointment = Appointment(
                        startTime: newStartTime,
                        endTime: appointment.endTime,
                        contact: appointment.contact,
                      );
                      _onAppointmentUpdated(appointment, updatedAppointment);
                      startTimeController.text = newStartTime.toString();
                    });
                  }
                },
              ),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(labelText: 'End Time'),
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(appointment.endTime),
                  );
                  if (pickedTime != null) {
                    final DateTime newEndTime = DateTime(
                      appointment.endTime.year,
                      appointment.endTime.month,
                      appointment.endTime.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    setState(() {
                      final updatedAppointment = Appointment(
                        startTime: appointment.startTime,
                        endTime: newEndTime,
                        contact: appointment.contact,
                      );
                      _onAppointmentUpdated(appointment, updatedAppointment);
                      endTimeController.text = newEndTime.toString();
                    });
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final Appointment updatedAppointment = Appointment(
                  startTime: DateTime.parse(startTimeController.text),
                  endTime: DateTime.parse(endTimeController.text),
                  contact: appointment.contact,
                );
                _onAppointmentUpdated(appointment, updatedAppointment);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _onAppointmentDeleted(appointment);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _changeView(String viewType) {
    setState(() {
      _viewType = viewType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iVisit'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeView,
            itemBuilder: (BuildContext context) {
              return {'Daily', 'Weekly', 'Monthly'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _viewType == 'Daily'
          ? ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return ListTile(
                  title: Text('${appointment.contact.firstName} ${appointment.contact.lastName}'),
                  subtitle: Text('${appointment.startTime} - ${appointment.endTime}'),
                  onTap: () => _showEditAppointmentDialog(appointment),
                );
              },
            )
          : _viewType == 'Weekly'
              ? ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final DateTime weekDay = DateTime.now().add(Duration(days: index));
                    final int appointmentCount = appointments.where((appointment) {
                      return appointment.startTime.day == weekDay.day &&
                          appointment.startTime.month == weekDay.month &&
                          appointment.startTime.year == weekDay.year;
                    }).length;
                    return ListTile(
                      title: Text('${weekDay.year}-${weekDay.month}-${weekDay.day}'),
                      subtitle: Text('Appointments: $appointmentCount'),
                      onTap: () {
                        setState(() {
                          _viewType = 'Daily';
                        });
                      },
                    );
                  },
                )
              : ListView.builder(
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final DateTime monthDay = DateTime.now().add(Duration(days: index));
                    final int appointmentCount = appointments.where((appointment) {
                      return appointment.startTime.day == monthDay.day &&
                          appointment.startTime.month == monthDay.month &&
                          appointment.startTime.year == monthDay.year;
                    }).length;
                    return ListTile(
                      title: Text('${monthDay.year}-${monthDay.month}-${monthDay.day}'),
                      subtitle: Text('Appointments: $appointmentCount'),
                      onTap: () {
                        setState(() {
                          _viewType = 'Daily';
                        });
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAppointmentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}








// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:syncfusion_flutter_calendar/calendar.dart' as calendar;
// import 'models/contact.dart';
// import 'models/appointment.dart';
// import 'widgets/calendar_page.dart';
// import 'widgets/contacts_page.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'iVisit',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const HomePage(),
//     );
//   }
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   HomePageState createState() => HomePageState();
// }

// class HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;
//   List<Contact> contacts = [];
//   List<Appointment> appointments = [];
//   late AppointmentDataSource dataSource;

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
//         appointments = (json.decode(appointmentsData) as List)
//             .map((data) => Appointment.fromJson(data))
//             .toList();
//         dataSource = AppointmentDataSource(appointments);
//       });
//     } else {
//       dataSource = AppointmentDataSource([]);
//     }
//   }

//   Future<void> _saveContacts() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('contacts', jsonEncode(contacts.map((c) => c.toJson()).toList()));
//   }

//   Future<void> _saveAppointments() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('appointments', 
//       jsonEncode(appointments.map((a) => a.toJson()).toList()));
//   }

//   void _onAppointmentAdded(Appointment appointment) {
//     setState(() {
//       appointments.add(appointment);
//       _saveAppointments();
//       dataSource = AppointmentDataSource(appointments);
//     });
//   }

//   // void _onContactAdded(Contact contact) {
//   //   setState(() {
//   //     contacts.add(contact);
//   //     _saveContacts();
//   //   });
//   // }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('iVisit')),
//       body: _selectedIndex == 0
//           ? CalendarPage()
//           : _selectedIndex == 1
//               ? ContactsPage(
//                   contacts: contacts,
//                   onContactSelected: (contact) {
//                     // Handle contact selection if needed
//                   },
//                 )
//               : const SettingsPage(),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.calendar_today),
//             label: 'Calendar',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.contacts),
//             label: 'Contacts',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//       ),
//       floatingActionButton: _selectedIndex != 2
//           ? FloatingActionButton(
//               onPressed: () => _selectedIndex == 0
//                   ? _showAddAppointmentDialog()
//                   : _showAddContactDialog(),
//               child: const Icon(Icons.add),
//             )
//           : null,
//     );
//   }

//   void _showAddAppointmentDialog() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ContactsPage(
//           contacts: contacts,
//           onContactSelected: (contact) {
//             final DateTime selectedDate = DateTime.now();
//             final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0);
//             final DateTime endTime = startTime.add(const Duration(hours: 1));
//             final Appointment newAppointment = Appointment(
//               startTime: startTime,
//               endTime: endTime,
//               contact: contact,
//             );
//             _onAppointmentAdded(newAppointment);
//             Navigator.pop(context);
//           },
//         ),
//       ),
//     );
//   }

//   void _showAddContactDialog() {
//     // Implement add contact dialog
//   }
// }

// class AppointmentDataSource extends calendar.CalendarDataSource {
//   AppointmentDataSource(List<Appointment> source) {
//     appointments = source;
//   }
// }

// class SettingsPage extends StatelessWidget {
//   const SettingsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text('Settings Page'),
//     );
//   }
// }