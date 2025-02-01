import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/contact.dart';
import 'models/appointment.dart';
import 'widgets/contacts_page.dart';
import 'utils.dart';
import 'package:intl/intl.dart';

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
    _deleteAllAppointments(); // 4testing/debugging
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

    void _deleteAllAppointments() { // 4testing/debugging
    setState(() {
      appointments.clear();
      _saveAppointments();
    });
     print('All appointments deleted');
  }


Future<void> _saveAppointments() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appointments', jsonEncode(appointments.map((a) => a.toJson()).toList()));
    print('Appointments saved successfully');
    //setState(() {});
  } catch (e) {
    print('Failed to save appointments: $e');
  }
}
  // Future<void> _saveAppointments() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('appointments', jsonEncode(appointments.map((a) => a.toJson()).toList()));
  // }


  void _onAppointmentAdded(Appointment appointment) {
    setState(() {
      appointments.add(appointment);
      //_saveAppointments();
    });   
    _saveAppointments();
  }

  void _onAppointmentUpdated(Appointment oldAppointment, Appointment newAppointment) {
    setState(() {
      final index = appointments.indexOf(oldAppointment);
      if (index != -1) {
        appointments[index] = newAppointment;
      }
    });
    _saveAppointments();
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
             print('Appointment added: $newAppointment');
            //setState(() {}); //redundant?
            Navigator.pop(context);
            
          },
        ),
      ),
    );
  }

  void _showEditAppointmentDialog(Appointment appointment) {
  final TextEditingController dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(appointment.startTime));
  final TextEditingController startTimeController = TextEditingController(text: DateFormat('HH:mm').format(appointment.startTime));
  final TextEditingController endTimeController = TextEditingController(text: DateFormat('HH:mm').format(appointment.endTime));

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
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Date (DD/MM/YYYY)'),
              readOnly: true,
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: appointment.startTime,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                  });
                }
              },
            ),
            TextField(
              controller: startTimeController,
              decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
              readOnly: true,
              onTap: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(appointment.startTime),
                );
                if (pickedTime != null) {
                  setState(() {
                    startTimeController.text = pickedTime.format(context);
                  });
                }
              },
            ),
            TextField(
              controller: endTimeController,
              decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
              readOnly: true,
              onTap: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(appointment.endTime),
                );
                if (pickedTime != null) {
                  setState(() {
                    endTimeController.text = pickedTime.format(context);
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
              final DateTime newDate = DateFormat('dd/MM/yyyy').parse(dateController.text);
              final TimeOfDay newStartTime = TimeOfDay(
                hour: int.parse(startTimeController.text.split(':')[0]),
                minute: int.parse(startTimeController.text.split(':')[1]),
              );
              final TimeOfDay newEndTime = TimeOfDay(
                hour: int.parse(endTimeController.text.split(':')[0]),
                minute: int.parse(endTimeController.text.split(':')[1]),
              );

              final DateTime newStartDateTime = DateTime(
                newDate.year,
                newDate.month,
                newDate.day,
                newStartTime.hour,
                newStartTime.minute,
              );
              final DateTime newEndDateTime = DateTime(
                newDate.year,
                newDate.month,
                newDate.day,
                newEndTime.hour,
                newEndTime.minute,
              );

              final Appointment updatedAppointment = Appointment(
                startTime: newStartDateTime,
                endTime: newEndDateTime,
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