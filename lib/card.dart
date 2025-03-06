class CardModel {
  int? id;
  String name; // Remove the final keyword
  String suit;
  String imageUrl;
  int folderId;

  CardModel({
    this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    required this.folderId,
  });

  // Convert a CardModel object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'imageUrl': imageUrl,
      'folderId': folderId,
    };
  }

  // Create a CardModel from a Map
  static CardModel fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      name: map['name'],
      suit: map['suit'],
      imageUrl: map['imageUrl'],
      folderId: map['folderId'],
    );
  }
}
