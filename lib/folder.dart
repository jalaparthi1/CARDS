class Folder {
  final int? id;
  final String name;

  Folder({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
