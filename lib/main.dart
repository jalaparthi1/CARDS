import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'cards_screen.dart';

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late DatabaseHelper dbHelper;
  late Future<List<Map<String, dynamic>>> foldersWithCardInfo;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    foldersWithCardInfo = _fetchFoldersWithCardInfo();
  }

  Future<List<Map<String, dynamic>>> _fetchFoldersWithCardInfo() async {
    List<Map<String, dynamic>> folderList = [];

    // Fetch all folders and include card count and first card image
    List<Map<String, dynamic>> folders = await dbHelper.getAllFolders();

    for (var folder in folders) {
      int folderId = folder['id'];
      int cardCount = await dbHelper.getCardCount(folderId);
      String? previewImage = await dbHelper.getFirstCardImage(folderId);

      folderList.add({
        'folderName': folder['name'],
        'folderId': folderId,
        'cardCount': cardCount,
        'previewImage': previewImage,
      });
    }

    return folderList;
  }

  Future<void> _addFolder() async {
    TextEditingController folderNameController = TextEditingController();

    // Show a dialog to input a new folder name
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                String folderName = folderNameController.text;
                if (folderName.isNotEmpty) {
                  await dbHelper.addFolder(folderName);
                  setState(() {
                    foldersWithCardInfo = _fetchFoldersWithCardInfo();
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameFolder(int folderId) async {
    TextEditingController folderNameController = TextEditingController();

    // Show a dialog to rename the folder
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: InputDecoration(hintText: 'New Folder Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Rename'),
              onPressed: () async {
                String newFolderName = folderNameController.text;
                if (newFolderName.isNotEmpty) {
                  await dbHelper.updateFolder(folderId, newFolderName);
                  setState(() {
                    foldersWithCardInfo = _fetchFoldersWithCardInfo();
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(int folderId) async {
    // Show a confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Folder'),
          content: Text(
              'Are you sure you want to delete this folder and all its cards?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await dbHelper.deleteFolder(folderId);
                setState(() {
                  foldersWithCardInfo = _fetchFoldersWithCardInfo();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Folders'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addFolder,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: foldersWithCardInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading folders'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No folders available.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var folder = snapshot.data![index];
              return ListTile(
                leading: folder['previewImage'] != null
                    ? Image.network(folder['previewImage']!, height: 50)
                    : Icon(Icons.folder, size: 50),
                title: Text(folder['folderName']),
                subtitle: Text('${folder['cardCount']} cards'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _renameFolder(folder['folderId']),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteFolder(folder['folderId']),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to the card screen when the folder is tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardScreen(
                        folderId: folder['folderId'],
                        folderName: folder['folderName'],
                      ),
                    ),
                  ).then((value) {
                    if (value == true) {
                      // Reload folders when returning from card screen (card added or deleted)
                      setState(() {
                        foldersWithCardInfo = _fetchFoldersWithCardInfo();
                      });
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData.dark().copyWith(
        // Use Flutter's dark theme
        primaryColor: Colors.deepPurple, // You can customize the primary color
        scaffoldBackgroundColor: Colors.black, // Background color for screens
        appBarTheme: AppBarTheme(
          color: Colors.deepPurple, // Dark theme for AppBar
        ),
        cardColor: Colors.grey[800], // Dark color for cards
      ),
      home: FolderScreen(), // Start with the folder screen
    );
  }
}
