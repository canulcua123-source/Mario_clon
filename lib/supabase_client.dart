import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();

  factory SupabaseManager() {
    return _instance;
  }

  SupabaseManager._internal();

  SupabaseClient? _client;

  Future<void> initialize() async {
    // TODO: Replace with your Supabase URL and anon key if they are different.
    const supabaseUrl = 'https://fxznbmmkqjkofvqebfvu.supabase.co';
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4em5ibW1rcWprb2Z2cWViZnZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxODA0NDksImV4cCI6MjA3Nzc1NjQ0OX0.BABvDhQhuYlqGfEBRIVyS0L34Z9RgTgUMdvFy4UF9e8';

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Fetches the best score (lowest time) for a specific level from the public leaderboard.
  Future<int?> getBestScore(String levelId) async {
    final response = await client
        .from('scores')
        .select('score')
        .eq('level_id', levelId)
        .order('score', ascending: true)
        .limit(1)
        .maybeSingle();

    if (response != null && response.isNotEmpty) {
      return response['score'] as int?;
    }
    return null;
  }

  /// Submits a new score for a specific level to the public leaderboard.
  Future<void> submitScore({
    required String playerName,
    required int score,
    required String levelId,
  }) async {
    await client.from('scores').insert({
      'player_name': playerName,
      'score': score,
      'level_id': levelId,
    });
  }

  /// Fetches all scores from the public leaderboard.
  Future<List<Map<String, dynamic>>> getAllScores() async {
    final response = await client
        .from('scores')
        .select()
        .order('level_id', ascending: true)
        .order('score', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }
}
