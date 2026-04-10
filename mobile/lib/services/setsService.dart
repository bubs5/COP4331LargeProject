//change when api is installed
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/studyset.dart';
import '../models/flashcard.dart';
import 'localstorage.dart';

class SetsService {
  static const bool useMockData = true;

  // Change this later to your real API URL
  static const String baseUrl = '';

  static const String setsKey = 'study_sets';
  static const String cardsKey = 'flashcards';

  Future<List<StudySet>> getStudySets() async{
    if (useMockData){
      return _getMockStudySets();
    }

    final response = await http.get(Uri.parse('$baseUrl/sets'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => StudySet.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load study sets');
    }
  }

  Future<StudySet?> getStudySetById(String setId) async{
    if (useMockData){
      final sets = await _getMockStudySets();
      try {
        return sets.firstWhere((set) => set.id == setId);
      }
      catch (_){
        return null;
      }
    }

    final response = await http.get(Uri.parse('$baseUrl/sets/$setId'));

    if (response.statusCode == 200){
      return StudySet.fromJson(jsonDecode(response.body));
    }
    else{
      return null;
    }
  }

  Future<List<Flashcard>> getCardsForSet(String setId) async {
    if (useMockData){
      return _getMockCardsForSet(setId);
    }

    final response = await http.get(Uri.parse('$baseUrl/sets/$setId/cards'));

    if (response.statusCode == 200){
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Flashcard.fromJson(item)).toList();
    }
    else{
      throw Exception('Failed to load flashcards');
    }
  }

  Future<void> createStudySet({
    required String title,
    required String description,
  }) async {
    if (useMockData){
      final setsRaw = await LocalStorageService.getList(setsKey);
      final sets = setsRaw
          .map((item) => StudySet.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final newSet = StudySet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        cardCount: 0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      sets.add(newSet);

      await LocalStorageService.saveList(
        setsKey,
        sets.map((set) => set.toJson()).toList(),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/sets'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201){
      throw Exception('Failed to create study set');
    }
  }

  Future<void> addCardToSet({
    required String setId,
    required String term,
    required String definition,
  }) async {
    if (useMockData){
      final cardsRaw = await LocalStorageService.getList(cardsKey);
      final cards = cardsRaw
          .map((item) => Flashcard.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final newCard = Flashcard(
        id: DateTime.now().millisecondsSinceEpoch,
        setId: setId,
        term: term,
        definition: definition,
      );

      cards.add(newCard);

      await LocalStorageService.saveList(
        cardsKey,
        cards.map((card) => card.toJson()).toList(),
      );

      final setsRaw = await LocalStorageService.getList(setsKey);
      final sets = setsRaw
          .map((item) => StudySet.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final updatedSets = sets.map((set){
        if (set.id == setId) {
          return StudySet(
            id: set.id,
            title: set.title,
            description: set.description,
            cardCount: set.cardCount + 1,
            createdAt: set.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
        return set;
      }).toList();

      await LocalStorageService.saveList(
        setsKey,
        updatedSets.map((set) => set.toJson()).toList(),
      );

      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/sets/$setId/cards'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'term': term,
        'definition': definition,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add card');
    }
  }

  Future<List<StudySet>> _getMockStudySets() async{
    final stored = await LocalStorageService.getList(setsKey);

    if (stored.isNotEmpty){
      return stored
          .map((item) => StudySet.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    final starterSets = [
      StudySet(
        id: '1',
        title: 'Biology Chapter 1',
        description: 'Basic biology terms',
        cardCount: 2,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      StudySet(
        id: '2',
        title: 'Spanish Basics',
        description: 'Common Spanish vocabulary',
        cardCount: 2,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];

    await LocalStorageService.saveList(
      setsKey,
      starterSets.map((set) => set.toJson()).toList(),
    );

    final starterCards = [
      Flashcard(
        id: 1,
        setId: '1',
        term: 'Cell',
        definition: 'The basic unit of life',
      ),
      Flashcard(
        id: 2,
        setId: '1',
        term: 'DNA',
        definition: 'Genetic material in living things',
      ),
      Flashcard(
        id: 3,
        setId: '2',
        term: 'Hola',
        definition: 'Hello',
      ),
      Flashcard(
        id: 4,
        setId: '2',
        term: 'Gracias',
        definition: 'Thank you',
      ),
    ];

    await LocalStorageService.saveList(
      cardsKey,
      starterCards.map((card) => card.toJson()).toList(),
    );

    return starterSets;
  }

  Future<List<Flashcard>> _getMockCardsForSet(String setId) async {
    final stored = await LocalStorageService.getList(cardsKey);

    if (stored.isEmpty) {
      await _getMockStudySets();
    }

    final refreshed = await LocalStorageService.getList(cardsKey);

    return refreshed
        .map((item) => Flashcard.fromJson(Map<String, dynamic>.from(item)))
        .where((card) => card.setId == setId)
        .toList();
  }
}