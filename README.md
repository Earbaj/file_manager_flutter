# Flutter File Manager

A simple **File Manager** app built with **Flutter** that allows users to browse and open files on their Android device. The app displays all accessible folders and files, and provides filtering by file type: Images, Videos, Documents, Audio, and All Files.

---

## Features

- **Browse device storage:** Navigate through all user-accessible folders.
- **Folder navigation:** Tap a folder to open it, and use the back button to go up one folder.
- **File type filtering:** Quickly filter files using the bottom navigation bar:
    - **All** – Show all files and folders
    - **Images** – JPG, PNG, GIF
    - **Videos** – MP4, MKV, AVI, MOV
    - **Documents** – PDF, DOC, DOCX, TXT, PPT, PPTX, XLS, XLSX
    - **Audio** – MP3, WAV, AAC
- **Safe recursive scanning:** Ignores restricted system folders like `/Android/` and hidden folders/files (starting with `.`).
- **File opening:** Tap on a file to open it using the default app (via [open_filex](https://pub.dev/packages/open_filex)).
- **Colored icons:** Folders and files are color-coded by type for easy identification.

| File Type   | Icon            | Color    |
|------------|----------------|----------|
| Folder     | 📁 (folder)     | Amber    |
| Image      | 🖼️ (image)      | Purple   |
| Video      | 🎬 (video)      | Red      |
| Audio      | 🎵 (audio)      | Blue     |
| Document   | 📄 (doc)        | Green    |
| Other      | 📦 (file)       | Grey     |

---

## Screenshots

_Add screenshots of your app here (optional)_

---

## Installation

1. **Clone the repository:**

```bash
git clone https://github.com/yourusername/flutter-file-manager.git
```
2. **Navigate to the project directory:**

```bash
cd flutter-file-manager
```
3. **Install dependencies:**

```bash
flutter pub get
```

4. **Run the app:**

```bash
flutter run
```

## Permissions
The app requires storage permission to read device files. On Android 10+, it uses scoped storage, and restricted folders like /Android/data will be ignored automatically.

Add the following permissions in **AndroidManifest.xml:**

```bash
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## Usage

1. Launch the app.
2. Browse the internal storage starting from /storage/emulated/0.
3. Tap on folders to navigate inside them.
4. Tap on files to open them.
5. Use the bottom navigation bar to filter files by type.
6. Press the device back button to go up one folder.


## Notes

- The app ignores system folders and hidden files, so some PDFs or files in /Android/data may not appear.
- Works on Android devices. iOS is not supported due to restricted file system access.
- Files in Download, Documents, or any user-created folder will always appear.

## Packages Used

- permission_handler To request storage permissions

- open_filex To open files with the default app