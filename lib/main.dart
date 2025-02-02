import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'models/contact.dart';
import 'models/appointment.dart';
import 'widgets/contacts_page.dart';
import 'widgets/settings_page.dart';
import 'widgets/calendar_page.dart';
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
  int _selectedIndex = 0;
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appointments', jsonEncode(appointments.map((a) => a.toJson()).toList()));
      print('Appointments saved successfully');
    } catch (e) {
      print('Failed to save appointments: $e');
    }
  }

  void _onAppointmentAdded(Appointment appointment) {
    setState(() {
      appointments.add(appointment);
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

  void _deleteAllAppointments() {
    setState(() {
      appointments.clear();
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
            final TextEditingController dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
            final TextEditingController startTimeController = TextEditingController(text: DateFormat('HH:mm').format(DateTime.now()));
            final TextEditingController endTimeController = TextEditingController(text: DateFormat('HH:mm').format(DateTime.now().add(Duration(hours: 1))));

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Add Appointment'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: dateController,
                        decoration: const InputDecoration(labelText: 'Date (DD/MM/YYYY)'),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
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
                            initialTime: TimeOfDay.now(),
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
                            initialTime: TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1),
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
                          minute: int.parse((startTimeController.text.replaceAll(RegExp(r'am|pm', caseSensitive: false), '').trim()).split(':')[1]),

                        );
                        final TimeOfDay newEndTime = TimeOfDay(
                          hour: int.parse(endTimeController.text.split(':')[0]),
                          minute: int.parse((startTimeController.text.replaceAll(RegExp(r'am|pm', caseSensitive: false), '').trim()).split(':')[1]),

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

                        final Appointment newAppointment = Appointment(
                          startTime: newStartDateTime,
                          endTime: newEndDateTime,
                          contact: contact,
                        );

                        _onAppointmentAdded(newAppointment);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
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
                  minute: int.parse((startTimeController.text.replaceAll(RegExp(r'am|pm', caseSensitive: false), '').trim()).split(':')[1]),
                );
                final TimeOfDay newEndTime = TimeOfDay(
                  hour: int.parse(endTimeController.text.split(':')[0]),
                  minute: int.parse((startTimeController.text.replaceAll(RegExp(r'am|pm', caseSensitive: false), '').trim()).split(':')[1]),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = <Widget>[
      CalendarPage(),
      ContactsPage(
        contacts: contacts,
        onContactSelected: (contact) {},
      ),
      SettingsPage(),
    ];

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
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteAllAppointments,
          ),
        ],
      ),
      body: _viewType == 'Daily'
          ? _buildDailyView()
          : _viewType == 'Weekly'
              ? _buildWeeklyView()
              : _buildMonthlyView(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddAppointmentDialog,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDailyView() {
    Map<String, List<Appointment>> groupedAppointments = {};
    for (var appointment in appointments) {
      String date = DateFormat('dd/MM/yyyy').format(appointment.startTime);
      if (groupedAppointments[date] == null) {
        groupedAppointments[date] = [];
      }
      groupedAppointments[date]!.add(appointment);
    }

    List<String> sortedDates = groupedAppointments.keys.toList()..sort((a, b) => DateFormat('dd/MM/yyyy').parse(a).compareTo(DateFormat('dd/MM/yyyy').parse(b)));
    int todayIndex = sortedDates.indexWhere((date) => date == DateFormat('dd/MM/yyyy').format(DateTime.now()));

    return ListView.builder(
      itemCount: sortedDates.length,
      controller: ScrollController(initialScrollOffset: todayIndex * 365.0), // Adjust the offset as needed
      itemBuilder: (context, index) {
        String date = sortedDates[index];
        List<Appointment> dailyAppointments = groupedAppointments[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.blue,
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  DateFormat('EEE d MMM yyyy').format(dailyAppointments.first.startTime),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ...dailyAppointments.map((appointment) {
              return ListTile(
                title: Text(
                  '${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)} ${appointment.contact.firstName} ${appointment.contact.lastName}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditAppointmentDialog(appointment),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {
                        // Add phone call logic here
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () {
                        // Add message logic here
                      },
                    ),
                  ],
                ),
                onTap: () => _showEditAppointmentDialog(appointment),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  

  Widget _buildWeeklyView() {
    return ListView.builder(
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
    );
  }

  Widget _buildMonthlyView() {
    return ListView.builder(
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
    );
  }
}