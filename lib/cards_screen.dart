import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'card.dart'; // Your card model

class CardScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  CardScreen({required this.folderId, required this.folderName});

  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  late DatabaseHelper dbHelper;
  late Future<List<CardModel>> cards;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    cards = _fetchCards();
  }

  Future<List<CardModel>> _fetchCards() async {
    List<Map<String, dynamic>> cardMaps =
        await dbHelper.getCards(widget.folderId);
    return cardMaps.map((cardMap) => CardModel.fromMap(cardMap)).toList();
  }

  Future<void> _addCard() async {
    List<CardModel> existingCards = await _fetchCards();

    if (existingCards.length >= 6) {
      // Show error if limit is reached
      _showErrorDialog('This folder can only hold 6 cards.');
      return;
    }

    // Show a dialog to ask for the card type and shape to be added
    _showCardSelectionDialog();
  }

  // Show dialog to select the card type and shape
  Future<void> _showCardSelectionDialog() async {
    String? selectedCardType;
    String? selectedCardShape;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to handle dropdown state changes
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Card Type and Shape'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Select card type'),
                    value: selectedCardType,
                    items: [
                      DropdownMenuItem(child: Text('Ace'), value: 'A'),
                      DropdownMenuItem(child: Text('2'), value: '2'),
                      DropdownMenuItem(child: Text('3'), value: '3'),
                      DropdownMenuItem(child: Text('4'), value: '4'),
                      DropdownMenuItem(child: Text('5'), value: '5'),
                      DropdownMenuItem(child: Text('6'), value: '6'),
                      DropdownMenuItem(child: Text('7'), value: '7'),
                      DropdownMenuItem(child: Text('8'), value: '8'),
                      DropdownMenuItem(child: Text('9'), value: '9'),
                      DropdownMenuItem(child: Text('10'), value: '10'),
                      DropdownMenuItem(child: Text('Jack'), value: 'J'),
                      DropdownMenuItem(child: Text('Queen'), value: 'Q'),
                      DropdownMenuItem(child: Text('King'), value: 'K'),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCardType =
                            newValue; // Update the selected value
                      });
                    },
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Select card shape'),
                    value: selectedCardShape,
                    items: [
                      DropdownMenuItem(child: Text('Hearts'), value: 'Hearts'),
                      DropdownMenuItem(
                          child: Text('Diamonds'), value: 'Diamonds'),
                      DropdownMenuItem(child: Text('Spades'), value: 'Spades'),
                      DropdownMenuItem(child: Text('Clubs'), value: 'Clubs'),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCardShape =
                            newValue; // Update the selected value
                      });
                    },
                  ),
                ],
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
                  onPressed: () {
                    if (selectedCardType != null && selectedCardShape != null) {
                      _addSelectedCard(selectedCardType!, selectedCardShape!);
                      Navigator.of(context).pop();
                    } else {
                      _showErrorDialog(
                          'Please select both card type and shape.');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add the selected card to the folder
  Future<void> _addSelectedCard(String cardType, String cardShape) async {
    String cardName;
    String imageUrl;

    // Construct the card name (e.g., "Ace of Hearts")
    switch (cardType) {
      case 'A':
        cardName = 'Ace of $cardShape';
        break;
      case 'J':
        cardName = 'Jack of $cardShape';
        break;
      case 'Q':
        cardName = 'Queen of $cardShape';
        break;
      case 'K':
        cardName = 'King of $cardShape';
        break;
      default:
        cardName = '$cardType of $cardShape';
    }

    imageUrl = _getCardImageUrl(cardType, cardShape);

    CardModel newCard = CardModel(
      name: cardName,
      suit: cardShape, // The selected shape becomes the suit
      imageUrl: imageUrl,
      folderId: widget.folderId,
    );

    await dbHelper.addCard(newCard.toMap());
    setState(() {
      cards = _fetchCards();
    });

    // Notify FolderScreen of the changes and return true
    Navigator.pop(
        context, true); // This ensures the card count updates in FolderScreen
  }

  // Function to get the correct image URL based on the card number/type and shape
  String _getCardImageUrl(String cardIdentifier, String suit) {
    String suitLetter;
    switch (suit) {
      case 'Hearts':
        suitLetter = 'H';
        break;
      case 'Diamonds':
        suitLetter = 'D';
        break;
      case 'Spades':
        suitLetter = 'S';
        break;
      case 'Clubs':
        suitLetter = 'C';
        break;
      default:
        suitLetter = 'H'; // Default to Hearts if something goes wrong
    }

    return 'https://deckofcardsapi.com/static/img/$cardIdentifier$suitLetter.png'; // Generate image URL
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(int cardId) async {
    await dbHelper.deleteCard(cardId);
    setState(() {
      cards = _fetchCards();
    });

    // Notify FolderScreen of changes
    Navigator.pop(context, true); // Return true to indicate a change was made
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folderName} Cards'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addCard, // Add new card after selecting type and shape
          ),
        ],
      ),
      body: FutureBuilder<List<CardModel>>(
        future: cards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading cards'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No cards in this folder.'));
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final card = snapshot.data![index];
              return Card(
                elevation: 4,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Image.network(card.imageUrl,
                            height: 100, fit: BoxFit.cover),
                        Text(card.name),
                        Text(card.suit),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCard(card.id!),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}