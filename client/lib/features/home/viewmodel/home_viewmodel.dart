import 'dart:io';
import 'dart:ui';

import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/features/home/model/fav_song_model.dart';
import 'package:client/features/home/model/song_model.dart';
import 'package:client/features/home/repositories/home_local_repository.dart';
import 'package:client/features/home/repositories/home_repository.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'home_viewmodel.g.dart';

@riverpod
Future<List<SongModel>> getAllSongs(Ref ref) async {
  final token = ref.watch(currentUserProvider.select((user) => user!.token));
  final res = await ref
      .watch(homeRepositoryProvider)
      .getAllSongs(
        token: token,
      );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

@riverpod
class HomeViewmodel extends _$HomeViewmodel {
  late HomeRepository _homeRepository;
  late HomeLocalRepository _homeLocalRepository;

  @override
  AsyncValue? build() {
    _homeRepository = ref.watch(homeRepositoryProvider);
    _homeLocalRepository = ref.watch(homeLocalRepositoryProvider);
    return null;
  }

  Future<void> uploadSong({
    required File selectedAudio,
    required File selectedThumbnail,
    required String songName,
    required String artist,
    required Color selectedColor,
  }) async {
    state = const AsyncValue.loading();
    final res = await _homeRepository.uploadSong(
      selectedThumbnail, // Nota: Parece que pasaste esto dos veces en tu código original
      selectedAudio: selectedAudio,
      selectedThumbnail: selectedThumbnail,
      songName: songName,
      artist: artist,
      hexCode: selectedColor.hex,
      token: ref.read(currentUserProvider)!.token,
    );

    // Cambiamos el switch a un switch tradicional para poder ejecutar múltiples líneas
    switch (res) {
      case Left(value: final l):
        state = AsyncValue.error(l.message, StackTrace.current);
        break;
      case Right(value: final r):
        state = AsyncValue.data(r);

        ref.invalidate(getAllSongsProvider);
        ref.invalidate(
          getAllFavSongsProvider,
        );
        break;
    }
  }

  List<SongModel> getRecentlyPlayedSongs() {
    return _homeLocalRepository.loadSongs();
  }

  Future<void> favSong({
    required String songId,
  }) async {
    state = const AsyncValue.loading();
    final res = await _homeRepository.favSong(
      songId: songId,
      token: ref.read(currentUserProvider)!.token,
    );

    if (!ref.mounted) return;

    final val = switch (res) {
      Left(value: final l) => state = AsyncValue.error(
        l.message,
        StackTrace.current,
      ),
      Right(value: final r) => _favSongSuccess(r, songId),
    };

    print(val);
  }

  AsyncValue _favSongSuccess(bool isFavorited, String songId) {
    final userNotifier = ref.read(currentUserProvider.notifier);
    if (isFavorited) {
      userNotifier.addUser(
        ref
            .read(currentUserProvider)!
            .copyWith(
              favorites: [
                ...ref.read(currentUserProvider)!.favorites,
                FavSongModel(
                  id: '',
                  song_id: songId,
                  user_id: '',
                ),
              ],
            ),
      );
    } else {
      userNotifier.addUser(
        ref
            .read(currentUserProvider)!
            .copyWith(
              favorites: ref
                  .read(currentUserProvider)!
                  .favorites
                  .where((fav) => fav.song_id != songId)
                  .toList(),
            ),
      );
    }

    ref.invalidate(getAllFavSongsProvider);
    return state = AsyncValue.data(isFavorited);
  }
}

@riverpod
Future<List<SongModel>> getAllFavSongs(Ref ref) async {
  final token = ref.watch(currentUserProvider.select((user) => user!.token));

  try {
    final res = await ref
        .watch(homeRepositoryProvider)
        .getAllFavSongs(
          token: token,
        );

    return switch (res) {
      Left(value: final l) => throw l.message,
      Right(value: final r) => r,
    };
  } catch (e) {
    throw e.toString();
  }
}
