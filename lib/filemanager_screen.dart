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
  List<Directory> pathHistory = [];
  Directory currentDirectory = Directory("/storage/emulated/0");
  int selectedIndex = 0;
  bool isLoading = false;

  // Tab titles
  final List<String> tabTitles = [
    "All Files",
    "Images",
    "Videos",
    "Documents",
    "Audio"
  ];

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    print("Permission Status: $statuses");

    if (statuses[Permission.storage]!.isGranted) {
      loadFiles(currentDirectory);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Storage permission is required to view files")),
      );
    }
  }

  Future<void> loadFiles(Directory directory) async {
    print("Loading files from: ${directory.path}");

    if (!await directory.exists()) {
      print("Directory does not exist!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Directory does not exist")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<FileSystemEntity> entities = await directory.list().toList();

      print("Found ${entities.length} items in directory");

      // Filter out hidden files and system folders
      entities = entities.where((entity) {
        final name = entity.path.split('/').last;
        return !name.startsWith(".") &&
            !entity.path.contains("/Android/data") &&
            !entity.path.contains("/Android/obb");
      }).toList();

      // Sort: folders first, then files alphabetically
      entities.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      setState(() {
        allFiles = entities;
        currentDirectory = directory;
        isLoading = false;
      });

      print("Filtered to ${entities.length} items");

    } catch (e) {
      print("Error loading files: $e");
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot access this folder: $e")),
      );
    }
  }

  void navigateToFolder(Directory directory) {
    pathHistory.add(currentDirectory);
    loadFiles(directory);
  }

  void navigateBack() {
    if (pathHistory.isNotEmpty) {
      Directory previousDir = pathHistory.removeLast();
      loadFiles(previousDir);
    } else if (currentDirectory.path != "/storage/emulated/0") {
      loadFiles(currentDirectory.parent);
    }
  }

  /// Improved file type classification
  String getFileType(String path) {
    if (path.split('.').length < 2) return "Other";

    String ext = path.split('.').last.toLowerCase();

    // Image extensions
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'svg', 'ico'].contains(ext))
      return "Image";

    // Video extensions
    if (['mp4', 'mkv', 'avi', 'mov', 'flv', 'wmv', '3gp', 'webm', 'm4v', 'ts'].contains(ext))
      return "Video";

    // Audio extensions
    if (['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg', 'wma', 'amr', 'mid', 'midi'].contains(ext))
      return "Audio";

    // Document extensions
    if (['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx', 'csv', 'rtf',
      'odt', 'ods', 'odp', 'epub', 'mobi', 'pages', 'numbers', 'key'].contains(ext))
      return "Document";

    return "Other";
  }

  /// Get files based on selected tab with recursive search for specific file types
  List<FileSystemEntity> getFilteredFiles() {
    if (selectedIndex == 0) {
      // All files - show everything in current directory
      return allFiles;
    }

    // For specific file types, we want to show only files (not folders) of that type
    String targetFileType = "";
    switch (selectedIndex) {
      case 1: targetFileType = "Image"; break;
      case 2: targetFileType = "Video"; break;
      case 3: targetFileType = "Document"; break;
      case 4: targetFileType = "Audio"; break;
    }

    return allFiles.where((entity) {
      // For category tabs, we only want to show files (not directories)
      if (entity is Directory) return false;

      // Check if file matches the target type
      return getFileType(entity.path) == targetFileType;
    }).toList();
  }

  IconData getFileIcon(FileSystemEntity file) {
    if (file is Directory) return Icons.folder;

    String type = getFileType(file.path);
    switch (type) {
      case "Image": return Icons.image;
      case "Video": return Icons.video_library;
      case "Audio": return Icons.audiotrack;
      case "Document": return Icons.description;
      default: return Icons.insert_drive_file;
    }
  }

  Color getFileIconColor(FileSystemEntity file) {
    if (file is Directory) return Colors.amber;

    String type = getFileType(file.path);
    switch (type) {
      case "Image": return Colors.purple;
      case "Video": return Colors.red;
      case "Audio": return Colors.blue;
      case "Document": return Colors.green;
      default: return Colors.grey;
    }
  }

  String formatFileSize(File file) {
    try {
      int sizeInBytes = file.lengthSync();
      if (sizeInBytes < 1024) return "$sizeInBytes B";
      if (sizeInBytes < 1048576) return "${(sizeInBytes / 1024).toStringAsFixed(1)} KB";
      return "${(sizeInBytes / 1048576).toStringAsFixed(1)} MB";
    } catch (e) {
      return "Unknown size";
    }
  }

  String getFileCountText() {
    final filteredFiles = getFilteredFiles();
    final totalCount = filteredFiles.length;

    if (selectedIndex == 0) {
      final fileCount = filteredFiles.where((f) => f is File).length;
      final folderCount = filteredFiles.where((f) => f is Directory).length;
      return "$totalCount items ($fileCount files, $folderCount folders)";
    } else {
      return "$totalCount ${tabTitles[selectedIndex].toLowerCase()}";
    }
  }

  @override
  Widget build(BuildContext context) {
    List<FileSystemEntity> files = getFilteredFiles();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tabTitles[selectedIndex]),
            Text(
              getFileCountText(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: _getAppBarColor(),
        actions: [
          // Show back button only when not in root directory
          if (pathHistory.isNotEmpty || currentDirectory.path != "/storage/emulated/0")
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: navigateBack,
              tooltip: "Go back",
            ),

          // Quick access menu
          PopupMenuButton(
            icon: Icon(Icons.folder_open, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Downloads"),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    loadFiles(Directory("/storage/emulated/0/Download"));
                  });
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.photo, color: Colors.purple),
                    SizedBox(width: 8),
                    Text("Pictures"),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    loadFiles(Directory("/storage/emulated/0/Pictures"));
                  });
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.music_note, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Music"),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    loadFiles(Directory("/storage/emulated/0/Music"));
                  });
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.movie, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Movies"),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    loadFiles(Directory("/storage/emulated/0/Movies"));
                  });
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Documents"),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    loadFiles(Directory("/storage/emulated/0/Documents"));
                  });
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Refresh"),
                  ],
                ),
                onTap: () => loadFiles(currentDirectory),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : files.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(),
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _getEmptyStateText(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            if (selectedIndex > 0)
              TextButton(
                onPressed: () {
                  // Navigate to common folders where these files might be
                  if (selectedIndex == 1) { // Images
                    loadFiles(Directory("/storage/emulated/0/Pictures"));
                  } else if (selectedIndex == 2) { // Videos
                    loadFiles(Directory("/storage/emulated/0/Movies"));
                  } else if (selectedIndex == 3) { // Documents
                    loadFiles(Directory("/storage/emulated/0/Download"));
                  } else if (selectedIndex == 4) { // Audio
                    loadFiles(Directory("/storage/emulated/0/Music"));
                  }
                },
                child: Text("Check common folder"),
              ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          var file = files[index];
          bool isDir = file is Directory;

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Icon(
                getFileIcon(file),
                color: getFileIconColor(file),
                size: 32,
              ),
              title: Text(
                file.path.split('/').last,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isDir ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: isDir
                  ? Text("Folder • ${file.path}")
                  : Text("${getFileType(file.path)} • ${formatFileSize(file as File)}"),
              trailing: isDir ? Icon(Icons.chevron_right) : null,
              onTap: () {
                if (isDir) {
                  navigateToFolder(file as Directory);
                } else {
                  OpenFilex.open(file.path);
                }
              },
              onLongPress: () {
                // Show file options
                _showFileOptions(file);
              },
            ),
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
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: "All",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: "Images",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: "Videos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: "Docs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.audiotrack),
            label: "Audio",
          ),
        ],
      ),
    );
  }

  Color _getAppBarColor() {
    switch (selectedIndex) {
      case 1: return Colors.purple; // Images
      case 2: return Colors.red;    // Videos
      case 3: return Colors.green;  // Documents
      case 4: return Colors.blue;   // Audio
      default: return Colors.green; // All files
    }
  }

  IconData _getEmptyStateIcon() {
    switch (selectedIndex) {
      case 1: return Icons.image;          // Images
      case 2: return Icons.video_library;  // Videos
      case 3: return Icons.description;    // Documents
      case 4: return Icons.audiotrack;     // Audio
      default: return Icons.folder_open;   // All files
    }
  }

  String _getEmptyStateText() {
    switch (selectedIndex) {
      case 1: return "No images found\nin current folder";
      case 2: return "No videos found\nin current folder";
      case 3: return "No documents found\nin current folder";
      case 4: return "No audio files found\nin current folder";
      default: return "No files found\nin current folder";
    }
  }

  void _showFileOptions(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("File Options"),
        content: Text("What would you like to do with '${file.path.split('/').last}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add share functionality here
            },
            child: Text("Share"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add delete functionality here
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}