import 'dart:io';
import 'package:flutter/material';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PdfProNoAdApp());
}

class PdfProNoAdApp extends StatefulWidget {
  const PdfProNoAdApp({super.key});

  @override
  State<PdfProNoAdApp> createState() => _PdfProNoAdAppState();
}

class _PdfProNoAdAppState extends State<PdfProNoAdApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Pro No Ad',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // AMOLED Dark Black
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white),
      ),
      home: HomeScreen(onToggleTheme: toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({super.key, required this.onToggleTheme, required this.isDarkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FileSystemEntity> _pdfFiles = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchAllPdfFiles();
  }

  Future<void> _fetchAllPdfFiles() async {
    setState(() => _isLoading = true);
    
    var status = await Permission.storage.request();
    var manageStatus = await Permission.manageExternalStorage.request();

    if (status.isGranted || manageStatus.isGranted || Platform.isIOS) {
      try {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          String rootPath = externalDir.path.split("Android")[0];
          Directory rootDir = Directory(rootPath);
          List<FileSystemEntity> files = [];
          
          await for (var entity in rootDir.list(recursive: true, followLinks: false)) {
            if (entity.path.toLowerCase().endsWith('.pdf')) {
              files.add(entity);
            }
          }
          setState(() {
            _pdfFiles = files;
          });
        }
      } catch (e) {
        debugPrint("PDF Search Error: $e");
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createPdfFromImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    final pdf = pw.Document();
    final imageBytes = await File(image.path).readAsBytes();
    final pdfImage = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(pdfImage, fit: pw.BoxFit.cover),
          );
        },
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final newFilePath = "${outputDir.path}/Scan_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(newFilePath);
    await file.writeAsBytes(await pdf.save());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("সফলভাবে নতুন PDF তৈরি হয়েছে!")),
    );

    _fetchAllPdfFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Pro No Ad', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("PDF Pro No Ad User"),
              accountEmail: Text("Ad-Free Pro Version"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.picture_as_pdf, color: Colors.blue, size: 36),
              ),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('সব ফাইল'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('পাসওয়ার্ড লক ও সিকিউরিটি'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('সেটিংস'),
              onTap: () {},
            ),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfFiles.isEmpty
              ? const Center(child: Text("মোবাইলে কোনো PDF ফাইল পাওয়া যায়নি।"))
              : ListView.builder(
                  itemCount: _pdfFiles.length,
                  itemBuilder: (context, index) {
                    final file = _pdfFiles[index];
                    final fileName = file.path.split('/').last;

                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                      title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: const Text("PDF Document"),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            file.delete();
                            _fetchAllPdfFiles();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'share', child: Text('শেয়ার করুন')),
                          const PopupMenuItem(value: 'lock', child: Text('লক / আনলক')),
                          const PopupMenuItem(value: 'delete', child: Text('ডিলিট করুন', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                      onTap: () {
                        Printing.layoutPdf(onLayout: (_) => File(file.path).readAsBytes());
                      },
                    );
                  },
                ),

      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(size: 36, color: Colors.white),
        backgroundColor: Colors.blue,
        buttonSize: const Size(70.0, 70.0),
        childrenButtonSize: const Size(60.0, 60.0),
        spacing: 15,
        spaceBetweenChildren: 15,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.camera_alt, color: Colors.white),
            backgroundColor: Colors.green,
            label: 'ক্যামেরা দিয়ে স্ক্যান করুন',
            onTap: () => _createPdfFromImage(ImageSource.camera),
          ),
          SpeedDialChild(
            child: const Icon(Icons.photo_library, color: Colors.white),
            backgroundColor: Colors.purple,
            label: 'গ্যালারি থেকে ছবি সিলেক্ট করে PDF করুন',
            onTap: () => _createPdfFromImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
