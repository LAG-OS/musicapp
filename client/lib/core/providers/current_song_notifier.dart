import 'package:client/features/home/model/song_model.dart';
import 'package:client/features/home/repositories/home_local_repository.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_song_notifier.g.dart';

@Riverpod(keepAlive: true)
class CurrentSongNotifier extends _$CurrentSongNotifier {
  late HomeLocalRepository _homeLocalRepository;
  late AudioPlayer audioPlayer;

  @override
  SongModel? build() {
    _homeLocalRepository = ref.watch(homeLocalRepositoryProvider);
    audioPlayer = AudioPlayer();

    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        audioPlayer.seek(Duration.zero);
        audioPlayer.pause();
      }
    });

    ref.onDispose(() {
      audioPlayer.dispose();
    });

    return null;
  }

  void updateSong(SongModel song) async {
    final audioSource = AudioSource.uri(
      Uri.parse(song.song_url),
      tag: MediaItem(
        id: song.id,
        title: song.song_name,
        artist: song.artist,
        artUri: Uri.parse(song.thumbnail_url),
      ),
    );

    await audioPlayer.setAudioSource(audioSource);

    _homeLocalRepository.uploadLocalSong(song);
    audioPlayer.play();
    state = song;
  }

  void playPause() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
  }

  void seek(double val) {
    audioPlayer.seek(
      Duration(
        milliseconds: (val * audioPlayer.duration!.inMilliseconds).toInt(),
      ),
    );
  }
}
