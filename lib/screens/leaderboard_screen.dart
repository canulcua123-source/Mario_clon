import 'package:flutter/material.dart';
import '../supabase_client.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _scores = [];
  List<String> _levels = [];
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _fetchScores();
  }

  Future<void> _fetchScores() async {
    try {
      final scores = await SupabaseManager().getAllScores();
      final levels =
          scores.map((s) => s['level_id'] as String).toSet().toList();
      if (mounted) {
        setState(() {
          _scores = scores;
          _levels = levels;
          _selectedLevel = levels.isNotEmpty ? levels.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch scores';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else if (_scores.isEmpty) {
      body = const Center(child: Text('No scores yet!'));
    } else {
      final filteredScores =
          _scores.where((s) => s['level_id'] == _selectedLevel).toList();

      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedLevel,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLevel = newValue;
                });
              },
              items: _levels.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('Level $value'),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredScores.length,
              itemBuilder: (context, index) {
                final score = filteredScores[index];
                return ListTile(
                  leading: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  title: Text(score['player_name'] as String),
                  trailing: Text(
                    '${score['score']}s',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: body,
    );
  }
}
