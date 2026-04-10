import 'package:flutter/material.dart';

import '../models/studyset.dart';
import '../services/setsService.dart';

class DashboardScreen extends StatefulWidget{
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>{
  final SetsService _setsService = SetsService();

  List<StudySet> _studySets = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState(){
    super.initState();
    _loadStudySets();
  }

  Future<void> _loadStudySets() async{
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try{
      final sets = await _setsService.getStudySets();

      if (!mounted) return;

      setState((){
        _studySets = sets;
        _isLoading = false;
      });
    }
    catch (e){
      if (!mounted) return;

      setState((){
        _errorMessage = 'Failed to load study sets.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudySets,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create Set screen coming next'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(){
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty){
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_studySets.isEmpty){
      return const Center(
        child: Text('No study sets yet.'),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _studySets.length,
      itemBuilder: (context, index){
        final set = _studySets[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              set.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${set.description}\n${set.cardCount} cards',
              ),
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Open set: ${set.title}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}