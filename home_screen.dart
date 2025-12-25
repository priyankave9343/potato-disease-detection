import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool isLoading = false;
  String? disease;
  String? confidence;

  final picker = ImagePicker();

  // 🔹 Pick image
  Future<void> pickImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        disease = null;
        confidence = null;
      });
    }
  }

  // 🔹 Predict API call
  Future<void> predictImage() async {
    if (_image == null) return;

    setState(() {
      isLoading = true;
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://127.0.0.1:7000/predict"),
    );

    request.files
        .add(await http.MultipartFile.fromPath('file', _image!.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var result = json.decode(responseData);

    setState(() {
      disease = result['disease'];
      confidence = result['confidence'];
      isLoading = false;
    });
  }

  // 🔹 Reset
  void resetApp() {
    setState(() {
      _image = null;
      disease = null;
      confidence = null;
    });
  }

  Color getResultColor() {
    if (disease == null) return Colors.grey;
    if (disease!.toLowerCase().contains("healthy")) {
      return Colors.green;
    } else if (disease!.toLowerCase().contains("early")) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Potato Disease Detection 🌱"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // IMAGE CARD
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: _image == null
                    ? Column(
                        children: [
                          Icon(Icons.image, size: 80, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No image selected"),
                        ],
                      )
                    : Image.file(
                        _image!,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            SizedBox(height: 20),

            // BUTTONS
            Column(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.upload),
                  label: Text("Upload Image"),
                  onPressed: pickImage,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.science),
                  label: Text("Diagnose"),
                  onPressed: predictImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: Icon(Icons.close),
                  label: Text("Reset"),
                  onPressed: resetApp,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // LOADING
            if (isLoading)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Analyzing leaf..."),
                ],
              ),

            // RESULT CARD
            if (disease != null && !isLoading)
              Card(
                color: getResultColor().withOpacity(0.1),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Result",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Disease: $disease",
                        style: TextStyle(
                            fontSize: 16,
                            color: getResultColor(),
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Confidence: $confidence",
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
