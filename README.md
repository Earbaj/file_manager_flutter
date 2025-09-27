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
git clone https://github.com/yourusername/flutter-file-manager.git
```