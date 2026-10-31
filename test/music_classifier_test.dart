import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/core/utils/music_classifier.dart';

void main() {
  group('MusicClassifier - Genre Detection Algorithm', () {
    test('Correctly classifies OPM artists and keywords', () {
      expect(
        MusicClassifier.detectGenre(title: 'Tingin', artist: 'Cup of Joe'),
        equals('OPM'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Pantropiko', artist: 'BINI'),
        equals('OPM'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Dilaw', artist: 'Maki'),
        equals('OPM'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Leaves', artist: 'Ben&Ben'),
        equals('OPM'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Ang Huling El Bimbo', artist: 'Eraserheads'),
        equals('OPM'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Unknown Title', artist: 'Unknown Artist', query: 'OPM Hits'),
        equals('OPM'),
      );
    });

    test('Correctly classifies K-Pop artists and keywords', () {
      expect(
        MusicClassifier.detectGenre(title: 'Dynamite', artist: 'BTS'),
        equals('K-Pop'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'How Sweet', artist: 'NewJeans'),
        equals('K-Pop'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Pink Venom', artist: 'BLACKPINK'),
        equals('K-Pop'),
      );
    });

    test('Correctly classifies Rock, Hip-Hop, Acoustic, EDM, and Pop', () {
      expect(
        MusicClassifier.detectGenre(title: 'Bohemian Rhapsody', artist: 'Queen', query: 'Classic Rock'),
        equals('Rock'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Lose Yourself', artist: 'Eminem', query: 'Rap'),
        equals('Hip-Hop'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Canon in D (Acoustic Guitar)', artist: 'Sungha Jung'),
        equals('Acoustic'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Titanium (EDM Remix)', artist: 'David Guetta'),
        equals('EDM'),
      );
      expect(
        MusicClassifier.detectGenre(title: 'Cruel Summer', artist: 'Taylor Swift'),
        equals('Pop'),
      );
    });
  });

  group('MusicClassifier - Original Artist Verification', () {
    test('Topic channels are identified as original artist uploads', () {
      expect(
        MusicClassifier.isOriginalArtist(artist: 'Cup of Joe', author: 'Cup of Joe - Topic'),
        isTrue,
      );
    });

    test('Official artist channels match artist name', () {
      expect(
        MusicClassifier.isOriginalArtist(artist: 'BINI', author: 'BINI Official'),
        isTrue,
      );
      expect(
        MusicClassifier.isOriginalArtist(artist: 'Taylor Swift', author: 'TaylorSwiftVEVO'),
        isTrue,
      );
      expect(
        MusicClassifier.isOriginalArtist(artist: 'Ben&Ben', author: 'Ben&Ben Music'),
        isTrue,
      );
    });

    test('Unofficial cover or fan channels are not marked as original artist', () {
      expect(
        MusicClassifier.isOriginalArtist(artist: 'Ben&Ben', author: 'Pinoy Covers Channel'),
        isFalse,
      );
      expect(
        MusicClassifier.isOriginalArtist(artist: 'Cup of Joe', author: 'Karaoke Hits PH'),
        isFalse,
      );
    });
  });

  group('MusicClassifier - Audio vs Music Video Classification', () {
    test('Identifies official audio releases', () {
      expect(
        MusicClassifier.isAudioOnly(title: 'Sining (Official Audio)', author: 'Dionela'),
        isTrue,
      );
      expect(
        MusicClassifier.isAudioOnly(title: 'Pantropiko (Official Lyric Video)', author: 'Star Music'),
        isTrue,
      );
      expect(
        MusicClassifier.isAudioOnly(title: 'Song Title', author: 'Artist - Topic'),
        isTrue,
      );
    });

    test('Identifies official music videos', () {
      expect(
        MusicClassifier.isMusicVideo(title: 'Salamin, Salamin (Official Music Video)'),
        isTrue,
      );
      expect(
        MusicClassifier.isMusicVideo(title: 'Ditto (M/V)'),
        isTrue,
      );
      expect(
        MusicClassifier.isMusicVideo(title: 'Casual Song Title'),
        isFalse,
      );
    });
  });
}
