import 'dart:convert';
import 'package:flutter/services.dart';
import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

class QuoteService {
  final SettingsRepository _settingsRepository;
  List<String>? _quotes;

  QuoteService(this._settingsRepository);

  Future<List<String>> _loadQuotes() async {
    if (_quotes != null) return _quotes!;
    final raw    = await rootBundle.loadString('assets/data/quotes.json');
    _quotes      = List<String>.from(json.decode(raw));
    return _quotes!;
  }

  /// Returns today's quote text. Rotates once per calendar day.
  Future<String> getTodayQuote() async {
    final quotes  = await _loadQuotes();
    final settingsResult = await _settingsRepository.getSettings();
    final settings = settingsResult.fold(
      (_) => SettingsEntity.defaults(),
      (s) => s,
    );

    final today    = _dateKey(DateTime.now());
    final lastDate = settings.lastQuoteDate != null
        ? _dateKey(settings.lastQuoteDate!)
        : null;

    if (lastDate == today) {
      // Same day — return cached index
      return quotes[settings.lastQuoteIndex % quotes.length];
    }

    // New day — advance index
    final nextIndex = (settings.lastQuoteIndex + 1) % quotes.length;
    await _settingsRepository.updateSettings(
      settings.copyWith(
        lastQuoteIndex: nextIndex,
        lastQuoteDate:  DateTime.now(),
      ),
    );
    return quotes[nextIndex];
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
