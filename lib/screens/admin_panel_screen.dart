import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF23243A),
      appBar: AppBar(
        title: Text("Admin Panel"),
        backgroundColor: Color(0xFF18192A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bus Management",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Bus List').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final buses = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: buses.length,
                    itemBuilder: (context, index) {
                      final bus = buses[index];
                      return Card(
                        color: Color(0xFF18192A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          title: Text(bus['Name'] ?? '', style: TextStyle(color: Colors.white)),
                          subtitle: Text('Number: 	${bus['Bus Number']} | GPS: 	${bus['Gps code']}\nDepartment: 	${bus['Department'] ?? ''}', style: TextStyle(color: Colors.white70)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.cyanAccent),
                                onPressed: () {
                                  // TODO: Implement edit bus dialog
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('Bus List').doc(bus.id).delete();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(Icons.add),
                label: Text("Add Bus", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddBusDialog(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddBusDialog extends StatefulWidget {
  @override
  State<AddBusDialog> createState() => _AddBusDialogState();
}

class _AddBusDialogState extends State<AddBusDialog> {
  final nameController = TextEditingController();
  final numberController = TextEditingController();
  final gpsController = TextEditingController();
  final departmentController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> addBus() async {
    setState(() { loading = true; error = null; });
    try {
      await FirebaseFirestore.instance.collection('Bus List').add({
        'Name': nameController.text.trim(),
        'Bus Number': numberController.text.trim(),
        'Gps code': gpsController.text.trim(),
        'Department': departmentController.text.trim(),
      });
      Navigator.pop(context);
    } catch (e) {
      setState(() { error = e.toString(); });
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF18192A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Add Bus", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Bus Name",
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF23243A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: numberController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Bus Number",
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF23243A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: gpsController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "GPS Code (e.g. [10°N,108°E])",
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF23243A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: departmentController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Department",
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF23243A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          if (error != null) ...[
            SizedBox(height: 8),
            Text(error!, style: TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: loading ? null : addBus,
          child: loading ? CircularProgressIndicator() : Text("Add"),
        ),
      ],
    );
  }
} 