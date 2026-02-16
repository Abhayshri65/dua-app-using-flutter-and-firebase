import 'package:cloud_firestore/cloud_firestore.dart';

class Dua {
  Dua({
    required this.id,
    required this.title,
    required this.duaTitle,
    required this.topic,
    required this.tags,
    required this.emotions,
    required this.categoryId,
    required this.subcategoryId,
    required this.categoryIds,
    required this.categoryNames,
    required this.arabic,
    required this.transliteration,
    required this.meanings,
    required this.audioUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? duaTitle;
  final String? topic;
  final List<String> tags;
  final List<String> emotions;
  final String? categoryId;
  final String? subcategoryId;
  final List<String> categoryIds;
  final List<String> categoryNames;
  final String? arabic;
  final String? transliteration;
  final Map<String, String> meanings;
  final String? audioUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static List<String> normalizeTagsFromInput(String input) {
    return normalizeTagList(
      input
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
    );
  }

  static List<String> normalizeTagList(List<String> tags) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final raw in tags) {
      final cleaned = _normalizeText(raw);
      if (cleaned.isEmpty) continue;
      if (seen.add(cleaned)) {
        normalized.add(cleaned);
      }
    }
    return normalized;
  }

  static List<String> buildSearchTokens(List<String> tags) {
    final tokens = <String>{};
    for (final tag in normalizeTagList(tags)) {
      tokens.add(tag);
      final words = tag.split(' ').where((w) => w.isNotEmpty);
      for (final word in words) {
        tokens.add(word);
        final maxPrefix = word.length < 8 ? word.length : 8;
        for (int i = 3; i <= maxPrefix; i++) {
          tokens.add(word.substring(0, i));
        }
      }
    }
    return tokens.toList();
  }

  static String _normalizeText(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.isEmpty) return '';
    final noPunct = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return noPunct.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  factory Dua.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final meaningsRaw = data['meanings'];
    return Dua(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      duaTitle: data['duaTitle']?.toString(),
      topic: data['topic']?.toString(),
      tags: (data['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      emotions: (data['emotions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      categoryId: data['categoryId']?.toString(),
      subcategoryId: data['subcategoryId']?.toString(),
      // Backward-compat: accept legacy single categoryId or string categoryIds.
      categoryIds: _readCategoryIds(data),
      categoryNames: (data['categoryNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      arabic: data['arabic']?.toString(),
      transliteration: data['transliteration']?.toString(),
      meanings: meaningsRaw is Map<String, dynamic>
          ? meaningsRaw.map((key, value) => MapEntry(
                key.toString(),
                value?.toString() ?? '',
              ))
          : const {},
      audioUrl: data['audioUrl']?.toString(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  static List<String> _readCategoryIds(Map<String, dynamic> data) {
    final raw = data['categoryIds'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
    final legacy = data['categoryId'];
    if (legacy is String && legacy.trim().isNotEmpty) {
      return [legacy.trim()];
    }
    return const [];
  }

  Map<String, dynamic> toMap({
    bool includeTimestamps = false,
    DateTime? createdAtOverride,
    DateTime? updatedAtOverride,
  }) {
    final normalizedTags = normalizeTagList(tags);
    final searchTokens = buildSearchTokens(normalizedTags);
    final map = <String, dynamic>{
      'title': title,
      'duaTitle': duaTitle ?? '',
      'topic': topic ?? '',
      'tags': normalizedTags,
      'searchTokens': searchTokens,
      'emotions': emotions,
      'categoryId': categoryId ?? '',
      'subcategoryId': subcategoryId ?? '',
      'categoryIds': categoryIds,
      'categoryNames': categoryNames,
      'arabic': arabic ?? '',
      'transliteration': transliteration ?? '',
      'meanings': meanings,
      'audioUrl': audioUrl ?? '',
    };
    if (includeTimestamps) {
      final created = createdAtOverride ?? createdAt;
      final updated = updatedAtOverride ?? updatedAt;
      if (created != null) {
        map['createdAt'] = created;
      }
      if (updated != null) {
        map['updatedAt'] = updated;
      }
    }
    return map;
  }

  String displayTitle() {
    if (duaTitle != null && duaTitle!.trim().isNotEmpty) {
      return duaTitle!.trim();
    }
    if (title.trim().isNotEmpty) {
      return title.trim();
    }
    return 'Untitled Dua';
  }

  Dua copyWith({
    String? id,
    String? title,
    String? duaTitle,
    String? topic,
    List<String>? tags,
    List<String>? emotions,
    String? categoryId,
    String? subcategoryId,
    List<String>? categoryIds,
    List<String>? categoryNames,
    String? arabic,
    String? transliteration,
    Map<String, String>? meanings,
    String? audioUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dua(
      id: id ?? this.id,
      title: title ?? this.title,
      duaTitle: duaTitle ?? this.duaTitle,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      emotions: emotions ?? this.emotions,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryNames: categoryNames ?? this.categoryNames,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      meanings: meanings ?? this.meanings,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
