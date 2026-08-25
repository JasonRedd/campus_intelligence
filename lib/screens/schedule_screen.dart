import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _showWeekly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniVault - Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Interactive Toggle State
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showWeekly ? 'Weekly View' : 'Today\'s View',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                FilterChip(
                  label: Text(_showWeekly ? 'Show Today' : 'Show Weekly'),
                  selected: _showWeekly,
                  onSelected: (bool selected) {
                    setState(() {
                      _showWeekly = selected;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dynamic Schedule Content
            Expanded(
              child: ListView(
                children: _showWeekly
                    ? const [
                        ListTile(
                          leading: Icon(Icons.calendar_today, color: Colors.indigo),
                          title: Text('Monday: DBMS Lab'),
                          subtitle: Text('10:00 AM - Lab 3'),
                        ),
                        ListTile(
                          leading: Icon(Icons.calendar_today, color: Colors.indigo),
                          title: Text('Tuesday: Mathematics'),
                          subtitle: Text('02:00 PM - Room 204'),
                        ),
                        ListTile(
                          leading: Icon(Icons.calendar_today, color: Colors.indigo),
                          title: Text('Wednesday: OS Theory'),
                          subtitle: Text('11:00 AM - Room 102'),
                        ),
                      ]
                    : const [
                        ListTile(
                          leading: Icon(Icons.access_time, color: Colors.indigo),
                          title: Text('DBMS Lab'),
                          subtitle: Text('10:00 AM • Lab 3'),
                        ),
                        ListTile(
                          leading: Icon(Icons.access_time, color: Colors.indigo),
                          title: Text('Mathematics'),
                          subtitle: Text('02:00 PM • Room 204'),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}