/// Utility for cleaning and computing matching confidence between songs.
class SongMatcher {
  // Regex patterns for common music video and release annotations in titles
  static final RegExp _annotationRegex = RegExp(
    r'(\s*[\(\[](official\s*(music)?\s*video|official\s*audio|lyric\s*video|lyrics|audio|visualizer|remastered(\s*\d+)?|live|hd|4k|mv|explicit)[\)\]]|\s*-\s*(remastered(\s*\d+)?|live|mono|stereo))',
    caseSensitive: false,
  );

  static final RegExp _featRegex = RegExp(
    r'\s*[\(\[]?(feat\.?|ft\.?|featuring)\s+[^)\]]+[\)\]]?',
    caseSensitive: false,
  );

  static final RegExp _punctuationRegex = RegExp(r'[^\w\s]');
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  /// Cleans and normalizes a song title for comparison.
  static String normalizeTitle(String title) {
    var cleaned = title.trim();
    // Remove (Official Video), [Audio], - Remastered 2011, etc.
    cleaned = cleaned.replaceAll(_annotationRegex, '');
    // Remove feat. artists from title
    cleaned = cleaned.replaceAll(_featRegex, '');
    // Remove punctuation
    cleaned = cleaned.replaceAll(_punctuationRegex, ' ');
    // Lowercase and collapse spaces
    cleaned = cleaned.toLowerCase().replaceAll(_whitespaceRegex, ' ').trim();
    return cleaned;
  }

  /// Cleans and normalizes an artist name for comparison.
  static String normalizeArtist(String artist) {
    var cleaned = artist.trim().toLowerCase();
    cleaned = cleaned.replaceAll(_punctuationRegex, ' ');
    // Remove common prefixes/suffixes and featuring markers
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(vevo|topic|official|feat|ft|featuring)\b'),
      ' ',
    );
    cleaned = cleaned.replaceAll(_whitespaceRegex, ' ').trim();
    return cleaned;
  }

  /// Computes a Dice token similarity score between two normalized strings [0.0 - 1.0].
  static double tokenSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final tokens1 = s1.split(' ').where((t) => t.isNotEmpty).toSet();
    final tokens2 = s2.split(' ').where((t) => t.isNotEmpty).toSet();

    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;

    final intersection = tokens1.intersection(tokens2).length;
    return (2.0 * intersection) / (tokens1.length + tokens2.length);
  }

  /// Evaluates whether a candidate track is a confident match for a query.
  ///
  /// Returns a confidence score between 0.0 and 1.0. A score >= 0.75 is considered confident.
  static double matchConfidence({
    required String queryTitle,
    required String queryArtist,
    required String candidateTitle,
    required String candidateArtist,
  }) {
    final normQueryTitle = normalizeTitle(queryTitle);
    final normCandTitle = normalizeTitle(candidateTitle);
    final normQueryArtist = normalizeArtist(queryArtist);
    final normCandArtist = normalizeArtist(candidateArtist);

    if (normQueryTitle.isEmpty || normCandTitle.isEmpty) return 0.0;

    // Direct title exact match
    final isExactTitle = normQueryTitle == normCandTitle;
    final titleScore = isExactTitle ? 1.0 : tokenSimilarity(normQueryTitle, normCandTitle);

    // Artist similarity
    final isExactArtist = normQueryArtist == normCandArtist;
    final isArtistContained = normQueryArtist.isNotEmpty &&
        normCandArtist.isNotEmpty &&
        (normQueryArtist.contains(normCandArtist) || normCandArtist.contains(normQueryArtist));

    final artistScore = isExactArtist
        ? 1.0
        : (isArtistContained ? 0.85 : tokenSimilarity(normQueryArtist, normCandArtist));

    // If artist has almost zero similarity, reject as match
    if (artistScore < 0.4 && normQueryArtist.isNotEmpty && normCandArtist.isNotEmpty) {
      return 0.0;
    }

    // Weighted combined score: 65% title, 35% artist
    return (titleScore * 0.65) + (artistScore * 0.35);
  }
}
