class StudySet {
  final String id;
  final String title;
  final String description;
  final int cardCount;
  final String? createdAt;
  final String? updatedAt;

  StudySet({
    required this.id,
    required this.title,
    required this.description,
    required this.cardCount,
    this.createdAt,
    this.updatedAt,
  });

  factory StudySet.fromJson(Map<String, dynamic> json) {
    return StudySet(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      cardCount: json['cardCount'] ?? 0,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'title': title,
      'description': description,
      'cardCount': cardCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}