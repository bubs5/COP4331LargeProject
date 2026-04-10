class Flashcard {
  final int id;
  final String term;
  final String definition;
  final String setId;

  Flashcard({
    required this.id,
    required this.term,
    required this.definition,
    required this.setId,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json){
    return Flashcard(
      id: json['id'],
      term: json['term'] ?? '',
      definition: json['definition'] ?? '',
      setId: json['setId'].toString(),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'term': term,
      'definition': definition,
      'setId': setId,
    };
  }
}