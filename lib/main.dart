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
    //Make the database
    dbHelper = DatabaseHelper();
    //Get the folder with starting data
    foldersWithCardInfo = _fetchFoldersWithCardInfo();
  }

  //Get folders and information about the cards
  Future<List<Map<String, dynamic>>> _fetchFoldersWithCardInfo() async {
    List<Map<String, dynamic>> folderList = [];

    // Fetch all folders 
    List<Map<String, dynamic>> folders = await dbHelper.getAllFolders();

    //Loop through the folders and get card count and respective image
    for (var folder in folders) {
      int folderId = folder['id'];
      int cardCount = await dbHelper.getCardCount(folderId);
      String? previewImage = await dbHelper.getFirstCardImage(folderId);

      //Adding folder info to list
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

    // Dialog to add folder and name it
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
                  //Add folder to the database
                  await dbHelper.addFolder(folderName);
                  setState(() {
                    //Refresh the database
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

    //Dialog to rename an already existing folder
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
                //End dialog
                Navigator.of(context).pop();
              },
            ),
            //Get the folder, rename it, and update it in database
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
    // Dialog confirming folder deletion
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
                //End dialog
                Navigator.of(context).pop();
              },
            ),
            //Delete folder from database and refresh folder list
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
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          color: Colors.deepPurple,
        ),
        cardColor: Colors.grey[800],
      ),
      home: FolderScreen(), 
    );
  }
}
