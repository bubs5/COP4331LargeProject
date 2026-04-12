import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/studyset.dart';
import '../models/flashcard.dart';
import '../config.dart';
import 'localstorage.dart';

//SetsService
// flip AppConfig.useMockData = false
// set AppConfig.baseUrl to your API to go live.

class SetsService {
  static const String _setsKey = 'study_sets';
  static const String _cardsKey = 'flashcards';

  // ─all sets
  Future<List<StudySet>> getStudySets() async{
    if (AppConfig.useMockData) return _mockGetStudySets();

    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/sets')); //api
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['studySets'] ?? data;
      return list.map((item) => StudySet.fromJson(item)).toList();
    }
    throw Exception('Failed to load study sets');
  }

  // set by id
  Future<StudySet?> getStudySetById(String setId) async{
    if (AppConfig.useMockData){
      final sets = await _mockGetStudySets();
      try{
        return sets.firstWhere((s) => s.id == setId);
      }
      catch (_){
        return null;
      }
    }

    final response =
    await http.get(Uri.parse('${AppConfig.baseUrl}/sets/$setId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return StudySet.fromJson(data['studySet'] ?? data);
    }
    return null;
  }

  // cards for set
  Future<List<Flashcard>> getCardsForSet(String setId) async{
    if (AppConfig.useMockData) return _mockGetCardsForSet(setId);

    final response =
    await http.get(Uri.parse('${AppConfig.baseUrl}/sets/$setId/cards'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['flashcards'] ?? data;
      return list.map((item) => Flashcard.fromJson(item)).toList();
    }
    throw Exception('Failed to load flashcards');
  }

  // create set
  Future<StudySet> createStudySet({
    required String title,
    required String description,
  }) async {
    if (AppConfig.useMockData){
      final sets = await _mockGetStudySets();
      final newSet = StudySet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        description: description.trim(),
        cardCount: 0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      sets.insert(0, newSet);
      await LocalStorageService.saveList(
          _setsKey, sets.map((s) => s.toJson()).toList());
      return newSet;
    }

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/sets'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title.trim(), 'description': description.trim()}),
    );
    if (response.statusCode == 200 || response.statusCode == 201){
      final data = jsonDecode(response.body);
      return StudySet.fromJson(data['studySet'] ?? data);
    }
    throw Exception('Failed to create study set');
  }

  // delete set
  Future<void> deleteStudySet(String setId) async{
    if (AppConfig.useMockData) {
      final sets = await _mockGetStudySets();
      final cards = await _mockGetAllCards();
      sets.removeWhere((s) => s.id == setId);
      cards.removeWhere((c) => c.setId == setId);
      await LocalStorageService.saveList(
          _setsKey, sets.map((s) => s.toJson()).toList());
      await LocalStorageService.saveList(
          _cardsKey, cards.map((c) => c.toJson()).toList());
      return;
    }

    await http.delete(Uri.parse('${AppConfig.baseUrl}/sets/$setId'));
  }

  // create card
  Future<Flashcard> createCard({
    required String setId,
    required String term,
    required String definition,
  }) async{
    if (AppConfig.useMockData){
      final cards = await _mockGetAllCards();
      final newCard = Flashcard(
        id: DateTime.now().millisecondsSinceEpoch,
        setId: setId,
        term: term.trim(),
        definition: definition.trim(),
      );
      cards.add(newCard);
      await LocalStorageService.saveList(
          _cardsKey, cards.map((c) => c.toJson()).toList());
      await _mockIncrementCardCount(setId, 1);
      return newCard;
    }

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/sets/$setId/cards'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'term': term.trim(), 'definition': definition.trim()}),
    );
    if (response.statusCode == 200 || response.statusCode == 201){
      final data = jsonDecode(response.body);
      return Flashcard.fromJson(data['flashcard'] ?? data);
    }
    throw Exception('Failed to add card');
  }

  // update card
  Future<Flashcard?> updateCard({
    required int cardId,
    required String term,
    required String definition,
  }) async {
    if (AppConfig.useMockData){
      final cards = await _mockGetAllCards();
      Flashcard? updated;
      final next = cards.map((c){
        if (c.id != cardId) return c;
        updated = Flashcard(
          id: c.id,
          setId: c.setId,
          term: term.trim(),
          definition: definition.trim(),
        );
        return updated!;
      }).toList();
      await LocalStorageService.saveList(
          _cardsKey, next.map((c) => c.toJson()).toList());
      return updated;
    }

    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/cards/$cardId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'term': term.trim(), 'definition': definition.trim()}),
    );
    if (response.statusCode == 200){
      final data = jsonDecode(response.body);
      return Flashcard.fromJson(data['flashcard'] ?? data);
    }
    return null;
  }

  // delete card
  Future<void> deleteCard(int cardId) async{
    if (AppConfig.useMockData){
      final cards = await _mockGetAllCards();
      final deleted = cards.firstWhere(
            (c) => c.id == cardId,
        orElse: () => Flashcard(id: -1, term: '', definition: '', setId: ''),
      );
      cards.removeWhere((c) => c.id == cardId);
      await LocalStorageService.saveList(
          _cardsKey, cards.map((c) => c.toJson()).toList());
      if (deleted.id != -1){
        await _mockIncrementCardCount(deleted.setId, -1);
      }
      return;
    }

    await http.delete(Uri.parse('${AppConfig.baseUrl}/cards/$cardId'));
  }

  // mock helpers
  Future<List<StudySet>> _mockGetStudySets() async{
    final stored = await LocalStorageService.getList(_setsKey);
    if (stored.isNotEmpty) {
      return stored
          .map((item) => StudySet.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    //seed initial data
    final seed = [
      StudySet(
        id: '1',
        title: 'Addition',
        description: 'Basic addition',
        cardCount: 2,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      StudySet(
        id: '2',
        title: 'Multiplication',
        description: 'basic multiplication',
        cardCount: 2,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];

    await LocalStorageService.saveList(
        _setsKey, seed.map((s) => s.toJson()).toList());

    final seedCards = [
      Flashcard(id: 1, setId: '1', term: '1+1', definition: '2'),
      Flashcard(id: 2, setId: '1', term: '2+2', definition: '4'),
      Flashcard(id: 3, setId: '2', term: '1x1', definition: '1'),
      Flashcard(id: 4, setId: '2', term: '2x2', definition: '4'),
    ];
    await LocalStorageService.saveList(
        _cardsKey, seedCards.map((c) => c.toJson()).toList());

    return seed;
  }

  Future<List<Flashcard>> _mockGetCardsForSet(String setId) async{
    //ensuring seeds exist
    await _mockGetStudySets();
    final all = await _mockGetAllCards();
    return all.where((c) => c.setId == setId).toList();
  }

  Future<List<Flashcard>> _mockGetAllCards() async {
    final stored = await LocalStorageService.getList(_cardsKey);
    return stored
        .map((item) => Flashcard.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _mockIncrementCardCount(String setId, int delta) async {
    final sets = await _mockGetStudySets();
    final updated = sets.map((s) {
      if (s.id != setId) return s;
      return StudySet(
        id: s.id,
        title: s.title,
        description: s.description,
        cardCount: (s.cardCount + delta).clamp(0, 9999),
        createdAt: s.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
    }).toList();
    await LocalStorageService.saveList(
        _setsKey, updated.map((s) => s.toJson()).toList());
  }
}
