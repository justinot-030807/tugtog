/// Intelligence utility that classifies tracks into Spotify-style genres and detects
/// whether a track is an Official Release, Original Artist Upload, Audio-only, or Music Video.
class MusicClassifier {
  /// Known Filipino / OPM artists for immediate high-accuracy genre tagging
  static const Set<String> _opmArtists = {
    'ben&ben',
    'bini',
    'cup of joe',
    'maki',
    'lola amour',
    'zack tabudlo',
    'dilaw',
    'eraserheads',
    'parokya ni edgar',
    'rivermaya',
    'moira dela torre',
    'arthur nery',
    'tj monterde',
    'flow g',
    'al james',
    'sb19',
    'up dharma down',
    'kamikazee',
    'sponge cola',
    'orange & lemons',
    'iv of spades',
    'mayonnaise',
    'silent sanctuary',
    'december avenue',
    'itchyworms',
    'munimuni',
    'any name\'s okay',
    'the juans',
    'sunkissed lola',
    'rob deniel',
    'adie',
    'juan karlos',
    'over october',
    'rico blanco',
    'bamboo',
    'rey valera',
    'apo hiking society',
    'gary valenciano',
    'regine velasquez',
    'gloc-9',
    'shanti dope',
    'hev abi',
    'skusta clee',
    'tanya markova',
    'callalily',
    'sandwich',
    'chicosci',
    'urbandub',
    'franco',
    'hale',
    '6cyclemind',
    'imago',
    'moonstar88',
    'soapdish',
    'nobita',
    'mrld',
    'dionela',
    'denise',
    'denise julia',
    'alyssa quijano',
    'keiko necesario',
    'clara benin',
    'reese lansangan',
    'leanne & naara',
  };

  /// Known K-Pop artists
  static const Set<String> _kpopArtists = {
    'bts',
    'blackpink',
    'twice',
    'newjeans',
    'stray kids',
    'seventeen',
    'aespa',
    'le sserafim',
    'ive',
    'txt',
    'enhypen',
    'red velvet',
    'exo',
    'itzy',
    'nct',
    'nct 127',
    'nct dream',
    'riize',
    'illit',
    'babymonster',
    'iu',
    'taeyeon',
    'jungkook',
    'jimin',
    'v',
    'rm',
    'suga',
    'agust d',
    'j-hope',
    'jin',
    'rose',
    'jennie',
    'lisa',
    'jisoo',
  };

  static bool _matchesArtist(String lowerText, String target) {
    if (target.length <= 3) {
      final words = lowerText.split(RegExp(r'[^a-zA-Z0-9]'));
      return words.contains(target);
    }
    return lowerText.contains(target);
  }

  /// Detects the musical genre of a track based on artist, title, and query context.
  static String detectGenre({
    required String title,
    required String artist,
    String? query,
  }) {
    final lowerArtist = artist.toLowerCase().trim();
    final lowerTitle = title.toLowerCase().trim();
    final lowerQuery = (query ?? '').toLowerCase().trim();

    // 1. OPM check (Artist lookup or keywords)
    for (final opm in _opmArtists) {
      if (_matchesArtist(lowerArtist, opm) || _matchesArtist(lowerTitle, opm)) {
        return 'OPM';
      }
    }
    if (lowerTitle.contains('opm') ||
        lowerTitle.contains('tagalog') ||
        lowerTitle.contains('pinoy') ||
        lowerQuery.contains('opm') ||
        lowerQuery.contains('tagalog')) {
      return 'OPM';
    }

    // 2. K-Pop check
    for (final kpop in _kpopArtists) {
      if (_matchesArtist(lowerArtist, kpop)) {
        return 'K-Pop';
      }
    }
    if (lowerTitle.contains('k-pop') ||
        lowerTitle.contains('kpop') ||
        lowerQuery.contains('kpop')) {
      return 'K-Pop';
    }

    // 3. Acoustic / Chill
    if (lowerTitle.contains('acoustic') ||
        lowerTitle.contains('unplugged') ||
        lowerTitle.contains('lo-fi') ||
        lowerTitle.contains('lofi') ||
        lowerTitle.contains('chill') ||
        lowerQuery.contains('acoustic')) {
      return 'Acoustic';
    }

    // 4. Hip-Hop / Rap
    if (lowerTitle.contains('hip hop') ||
        lowerTitle.contains('hip-hop') ||
        lowerTitle.contains('rap') ||
        lowerTitle.contains('trap') ||
        lowerQuery.contains('rap') ||
        lowerQuery.contains('hip hop')) {
      return 'Hip-Hop';
    }

    // 5. Rock & Alternative
    if (lowerTitle.contains('rock') ||
        lowerTitle.contains('metal') ||
        lowerTitle.contains('punk') ||
        lowerTitle.contains('alternative') ||
        lowerQuery.contains('rock')) {
      return 'Rock';
    }

    // 6. R&B & Soul
    if (lowerTitle.contains('r&b') ||
        lowerTitle.contains('rnb') ||
        lowerTitle.contains('soul') ||
        lowerQuery.contains('r&b') ||
        lowerQuery.contains('rnb')) {
      return 'R&B';
    }

    // 7. Electronic / Dance
    if (lowerTitle.contains('edm') ||
        lowerTitle.contains('electronic') ||
        lowerTitle.contains('remix') ||
        lowerTitle.contains('dance') ||
        lowerQuery.contains('electronic')) {
      return 'EDM';
    }

    // Default mainstream genre
    return 'Pop';
  }

  /// Evaluates whether the upload originates directly from the original artist's channel.
  static bool isOriginalArtist({
    required String artist,
    required String author,
  }) {
    final lowerArtist = artist.toLowerCase().trim();
    final lowerAuthor = author.toLowerCase().trim();

    if (lowerAuthor.isEmpty || lowerArtist.isEmpty) return false;

    // 1. YouTube Music Topic channels (Official artist catalog)
    if (lowerAuthor.endsWith(' - topic')) return true;

    // 2. Author channel contains artist name or artist contains author channel
    final cleanAuthor = lowerAuthor
        .replaceAll('official', '')
        .replaceAll('vevo', '')
        .replaceAll('music', '')
        .replaceAll('channel', '')
        .trim();

    if (cleanAuthor.isNotEmpty &&
        (cleanAuthor.contains(lowerArtist) || lowerArtist.contains(cleanAuthor))) {
      return true;
    }

    // 3. VEVO or Records verified uploads
    if (lowerAuthor.contains('vevo') ||
        lowerAuthor.contains('records') ||
        lowerAuthor.contains('entertainment')) {
      return true;
    }

    return false;
  }

  /// Determines whether the track is an official studio audio release (Audio only).
  static bool isAudioOnly({
    required String title,
    required String author,
  }) {
    final lowerTitle = title.toLowerCase();
    final lowerAuthor = author.toLowerCase();

    // Topic channels are pure audio tracks
    if (lowerAuthor.endsWith(' - topic')) {
      return !isMusicVideo(title: title);
    }

    // Title indicator
    if (lowerTitle.contains('(official audio)') ||
        lowerTitle.contains('[official audio]') ||
        lowerTitle.contains('(audio)') ||
        lowerTitle.contains('[audio]') ||
        lowerTitle.contains('(visualizer)') ||
        lowerTitle.contains('[visualizer]') ||
        lowerTitle.contains('(official lyric video)') ||
        lowerTitle.contains('[official lyric video]') ||
        lowerTitle.contains('(lyric video)') ||
        lowerTitle.contains('[lyric video]')) {
      return true;
    }

    return false;
  }

  /// Determines whether the track is an official music video.
  static bool isMusicVideo({required String title}) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('(official music video)') ||
        lowerTitle.contains('[official music video]') ||
        lowerTitle.contains('(official video)') ||
        lowerTitle.contains('[official video]') ||
        lowerTitle.contains('(music video)') ||
        lowerTitle.contains('[music video]') ||
        lowerTitle.contains('(mv)') ||
        lowerTitle.contains('[mv]') ||
        lowerTitle.contains('(m/v)') ||
        lowerTitle.contains('[m/v]') ||
        lowerTitle.contains(' m/v') ||
        lowerTitle.contains(' mv ') ||
        lowerTitle.endsWith(' mv')) {
      return true;
    }

    return false;
  }
}
