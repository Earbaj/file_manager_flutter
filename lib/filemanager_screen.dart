import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class FileManagerScreen extends StatefulWidget {
  @override
  _FileManagerScreenState createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<FileSystemEntity> allFiles = [];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    if (await Permission.storage.request().isGranted) {
      loadFiles();
    }
  }

  void loadFiles() {
    Directory root = Directory("/storage/emulated/0");

    setState(() {
      allFiles = root.listSync(recursive: false, followLinks: false)
          .where((f) {
        String name = f.path.split('/').last;
        return name != "Android"; // skip restricted folder
      }).toList();
    });
  }

  /// Classify file types
  String getFileType(String path) {
    String ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return "Image";
    if (['mp4', 'mkv', 'avi', 'mov'].contains(ext)) return "Video";
    if (['mp3', 'wav', 'aac'].contains(ext)) return "Audio";
    if (['pdf', 'doc', 'docx', 'txt', 'ppt', 'xls'].contains(ext)) return "Document";
    return "Other";
  }

  /// Filter files based on selected tab
  List<FileSystemEntity> getFilteredFiles() {
    if (selectedIndex == 0) return allFiles; // All
    if (selectedIndex == 1) {
      return allFiles.where((f) => f is File && getFileType(f.path) == "Image").toList();
    }
    if (selectedIndex == 2) {
      return allFiles.where((f) => f is File && getFileType(f.path) == "Video").toList();
    }
    if (selectedIndex == 3) {
      return allFiles.where((f) => f is File && getFileType(f.path) == "Document").toList();
    }
    if (selectedIndex == 4) {
      return allFiles.where((f) => f is File && getFileType(f.path) == "Audio").toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    List<FileSystemEntity> files = getFilteredFiles();

    return Scaffold(
      appBar: AppBar(
        title: Text("File Manager"),
        backgroundColor: Colors.green,
      ),
      body: files.isEmpty
          ? Center(child: Text("No files found"))
          : ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          var file = files[index];
          bool isDir = file is Directory;
          return ListTile(
            leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file,
                color: isDir ? Colors.amber : Colors.grey),
            title: Text(file.path.split('/').last),
            subtitle: isDir ? Text("Folder") : Text(getFileType(file.path)),
            onTap: () {
              if (file is File) {
                OpenFilex.open(file.path); // open file
              }
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        selectedItemColor: Colors.black,   // selected label color
        unselectedItemColor: Colors.black, // unselected label color
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.storage,color: Colors.black,),
              label: "All",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.image,color: Colors.black,), label: "Images"),
          BottomNavigationBarItem(icon: Icon(Icons.video_library,color: Colors.black,), label: "Videos"),
          BottomNavigationBarItem(icon: Icon(Icons.description,color: Colors.black,), label: "Docs"),
          BottomNavigationBarItem(icon: Icon(Icons.audiotrack,color: Colors.black,), label: "Audio"),
        ],
      ),
    );
  }
}
