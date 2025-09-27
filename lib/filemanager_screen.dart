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
  List<FileSystemEntity> categorizedFiles = [];
  List<Directory> pathHistory = [];
  Directory currentDirectory = Directory("/storage/emulated/0");
  int selectedIndex = 0;
  bool isLoading = false;
  bool isScanning = false;
  String currentScanType = ""; // Track what type we're currently scanning for

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
        // Reset categorized files when browsing normally
        if (selectedIndex == 0) {
          categorizedFiles = [];
          currentScanType = "";
        }
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

  /// Recursively scan entire storage for specific file types
  Future<void> scanEntireStorageForFileType(String fileType) async {
    setState(() {
      isScanning = true;
      categorizedFiles = [];
      currentScanType = fileType;
    });

    List<FileSystemEntity> foundFiles = [];
    int scannedFolders = 0;

    try {
      // Start scanning from root directory
      await _scanDirectoryRecursive(Directory("/storage/emulated/0"), fileType, foundFiles, (foldersScanned) {
        scannedFolders = foldersScanned;
      });

      setState(() {
        categorizedFiles = foundFiles;
        isScanning = false;
      });

      print("Scan complete: Found ${foundFiles.length} $fileType files in $scannedFolders folders");

    } catch (e) {
      print("Error during scanning: $e");
      setState(() {
        isScanning = false;
        currentScanType = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error scanning files: $e")),
      );
    }
  }

  Future<void> _scanDirectoryRecursive(
      Directory directory,
      String targetFileType,
      List<FileSystemEntity> results,
      Function(int) onProgressUpdate) async {

    int foldersScanned = 0;

    try {
      if (!await directory.exists()) return;

      final List<FileSystemEntity> entities = await directory.list().toList();
      foldersScanned++;

      for (var entity in entities) {
        // Skip hidden files and restricted folders
        final name = entity.path.split('/').last;
        if (name.startsWith(".") ||
            entity.path.contains("/Android/data") ||
            entity.path.contains("/Android/obb")) {
          continue;
        }

        if (entity is File) {
          // Check if file matches the target type
          if (getFileType(entity.path) == targetFileType) {
            results.add(entity);
          }
        } else if (entity is Directory) {
          // Recursively scan subdirectories
          await _scanDirectoryRecursive(entity, targetFileType, results, onProgressUpdate);
        }
      }

      onProgressUpdate(foldersScanned);

    } catch (e) {
      print("Skipping directory ${directory.path} due to error: $e");
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

  /// File type classification
  String getFileType(String path) {
    if (path.split('.').length < 2) return "Other";

    String ext = path.split('.').last.toLowerCase();

    // Image extensions
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'svg', 'ico', 'raw', 'cr2', 'nef'].contains(ext))
      return "Image";

    // Video extensions
    if (['mp4', 'mkv', 'avi', 'mov', 'flv', 'wmv', '3gp', 'webm', 'm4v', 'ts', 'mpeg', 'mpg'].contains(ext))
      return "Video";

    // Audio extensions
    if (['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg', 'wma', 'amr', 'mid', 'midi', 'aiff'].contains(ext))
      return "Audio";

    // Document extensions
    if (['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx', 'csv', 'rtf',
      'odt', 'ods', 'odp', 'epub', 'mobi', 'pages', 'numbers', 'key', 'xml', 'json'].contains(ext))
      return "Document";

    return "Other";
  }

  /// Get files based on selected tab
  List<FileSystemEntity> getFilteredFiles() {
    if (selectedIndex == 0) {
      // All files - show everything in current directory
      return allFiles;
    }

    // For specific file types, only show files if they match the current tab
    if (selectedIndex > 0) {
      String currentTabType = getTargetFileType();

      // Only return categorized files if they were scanned for the current tab type
      if (currentScanType == currentTabType) {
        return categorizedFiles;
      } else {
        // If we have files from a different scan, don't show them
        return [];
      }
    }

    return [];
  }

  String getTargetFileType() {
    switch (selectedIndex) {
      case 1: return "Image";
      case 2: return "Video";
      case 3: return "Document";
      case 4: return "Audio";
      default: return "";
    }
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
      if (sizeInBytes < 1073741824) return "${(sizeInBytes / 1048576).toStringAsFixed(1)} MB";
      return "${(sizeInBytes / 1073741824).toStringAsFixed(1)} GB";
    } catch (e) {
      return "Unknown size";
    }
  }

  String getFileCountText() {
    if (selectedIndex == 0) {
      final filteredFiles = getFilteredFiles();
      final fileCount = filteredFiles.where((f) => f is File).length;
      final folderCount = filteredFiles.where((f) => f is Directory).length;
      return "$fileCount files, $folderCount folders";
    } else {
      if (isScanning) {
        return "Scanning for ${tabTitles[selectedIndex].toLowerCase()}...";
      } else if (currentScanType == getTargetFileType()) {
        return "${categorizedFiles.length} ${tabTitles[selectedIndex].toLowerCase()} found";
      } else {
        return "Tap to scan for ${tabTitles[selectedIndex].toLowerCase()}";
      }
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
        actions: _getAppBarActions(),
      ),
      body: _buildBody(files),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  List<Widget> _getAppBarActions() {
    if (selectedIndex == 0) {
      return [
        if (pathHistory.isNotEmpty || currentDirectory.path != "/storage/emulated/0")
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: navigateBack,
            tooltip: "Go back",
          ),
        _buildQuickAccessMenu(),
      ];
    } else {
      // Show refresh button only if we've scanned for the current tab type
      if (currentScanType == getTargetFileType() && categorizedFiles.isNotEmpty) {
        return [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => scanEntireStorageForFileType(getTargetFileType()),
            tooltip: "Rescan",
          ),
        ];
      }
      return [];
    }
  }

  Widget _buildBody(List<FileSystemEntity> files) {
    // For category tabs (1-4), check if we need to show scan prompt
    if (selectedIndex > 0 && currentScanType != getTargetFileType() && !isScanning) {
      return _buildScanPrompt();
    }

    if (isScanning) {
      return _buildScanningProgress();
    }

    if (files.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
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
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.path,
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isDir) Text("${getFileType(file.path)} • ${formatFileSize(file as File)}"),
              ],
            ),
            trailing: isDir ? Icon(Icons.chevron_right) : null,
            onTap: () {
              if (isDir && selectedIndex == 0) {
                navigateToFolder(file as Directory);
              } else if (!isDir) {
                OpenFilex.open(file.path);
              }
            },
            onLongPress: () => _showFileOptions(file),
          ),
        );
      },
    );
  }

  Widget _buildScanPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyStateIcon(),
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            "Scan entire storage for ${tabTitles[selectedIndex].toLowerCase()}?",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            "This will search through all folders to find ${tabTitles[selectedIndex].toLowerCase()}",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => scanEntireStorageForFileType(getTargetFileType()),
            icon: Icon(Icons.search),
            label: Text("Start Scanning"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getAppBarColor(),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            "Scanning entire storage...",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(
            "Searching for ${tabTitles[selectedIndex].toLowerCase()}",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (selectedIndex > 0 && categorizedFiles.isEmpty && currentScanType == getTargetFileType())
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: () => scanEntireStorageForFileType(getTargetFileType()),
                child: Text("Scan Again"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        setState(() {
          selectedIndex = index;
          // Don't clear categorizedFiles, but track which type we're viewing
          // The files will only show if they match the current tab type
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.green,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.7),
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.storage), label: "All"),
        BottomNavigationBarItem(icon: Icon(Icons.image), label: "Images"),
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Videos"),
        BottomNavigationBarItem(icon: Icon(Icons.description), label: "Docs"),
        BottomNavigationBarItem(icon: Icon(Icons.audiotrack), label: "Audio"),
      ],
    );
  }


  Widget _buildQuickAccessMenu() {
    return PopupMenuButton(
      icon: Icon(Icons.folder_open, color: Colors.white),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Row(children: [Icon(Icons.download), SizedBox(width: 8), Text("Downloads")]),
          onTap: () => loadFiles(Directory("/storage/emulated/0/Download")),
        ),
        PopupMenuItem(
          child: Row(children: [Icon(Icons.photo), SizedBox(width: 8), Text("Pictures")]),
          onTap: () => loadFiles(Directory("/storage/emulated/0/Pictures")),
        ),
        PopupMenuItem(
          child: Row(children: [Icon(Icons.music_note), SizedBox(width: 8), Text("Music")]),
          onTap: () => loadFiles(Directory("/storage/emulated/0/Music")),
        ),
        PopupMenuItem(
          child: Row(children: [Icon(Icons.movie), SizedBox(width: 8), Text("Movies")]),
          onTap: () => loadFiles(Directory("/storage/emulated/0/Movies")),
        ),
        PopupMenuItem(
          child: Row(children: [Icon(Icons.description), SizedBox(width: 8), Text("Documents")]),
          onTap: () => loadFiles(Directory("/storage/emulated/0/Documents")),
        ),
        PopupMenuItem(
          child: Row(children: [Icon(Icons.refresh), SizedBox(width: 8), Text("Refresh")]),
          onTap: () => loadFiles(currentDirectory),
        ),
      ],
    );
  }

  Color _getAppBarColor() {
    switch (selectedIndex) {
      case 1: return Colors.purple;
      case 2: return Colors.red;
      case 3: return Colors.green;
      case 4: return Colors.blue;
      default: return Colors.green;
    }
  }

  IconData _getEmptyStateIcon() {
    switch (selectedIndex) {
      case 1: return Icons.image;
      case 2: return Icons.video_library;
      case 3: return Icons.description;
      case 4: return Icons.audiotrack;
      default: return Icons.folder_open;
    }
  }

  String _getEmptyStateText() {
    switch (selectedIndex) {
      case 1: return currentScanType == "Image" ? "No images found in storage" : "Tap to scan for images";
      case 2: return currentScanType == "Video" ? "No videos found in storage" : "Tap to scan for videos";
      case 3: return currentScanType == "Document" ? "No documents found in storage" : "Tap to scan for documents";
      case 4: return currentScanType == "Audio" ? "No audio files found in storage" : "Tap to scan for audio";
      default: return "No files found in current folder";
    }
  }

  void _showFileOptions(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("File Options"),
        content: Text("What would you like to do with '${file.path.split('/').last}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(onPressed: () { Navigator.pop(context); }, child: Text("Share")),
          TextButton(
            onPressed: () { Navigator.pop(context); },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}