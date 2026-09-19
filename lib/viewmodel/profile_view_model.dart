import 'package:aullet/models/profile.dart';
import 'package:aullet/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileViewModel extends ChangeNotifier {
  final _repo = ProfileRepository();
  final _picker = ImagePicker();
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  //aggiorniamo lo stato _isLoading e avvisiamo i listeners
  void _setLoading(bool value) {
    _isLoading = value;
    //quando iniziamo un nuovo caricamento (value = true), cancelliamo eventuali messaggi di errore precedenti
    if (value) {
      _error = null;
    }
    notifyListeners();
  }

  //Carica il profilo dell'utente corrente
  Future<void> loadProfile() async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      _profile = await _repo.fetchProfile(user.id);

      //Se non esiste, crea un profilo di default
      if (_profile == null) {
        _profile = Profile(
          id: '', //Supabase genera id automaticamente
          userId: user.id,
          displayName: user.email!.split('@')[0],
        );
        await _repo.createProfile(_profile!);
        _profile = await _repo.fetchProfile(user.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  //aggiorna il nome visualizzato
  Future<void> updateDisplayName(String newDisplayName) async {
    //verifico che _profile esiste
    if (_profile == null) return;

    _setLoading(true);

    try {
      //modifico il displayName
      _profile!.displayName = newDisplayName;
      //aggiorno il DB tramite profile_repository
      await _repo.updateProfile(_profile!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickAndUploadAvatar(String userId) async {
    //l'utente seleziona l'immagine dalla galleria del telefono
    final image = await _picker.pickImage(source: ImageSource.gallery);
    //caso in cui l'utente non seleziona alcuna immagine
    if (image == null) return;
    _setLoading(true);
    try {
      //recupero l'utente attuale da Supabase e salvo il suo profilo in _profile
      final user = Supabase.instance.client.auth.currentUser!;
      _profile = await _repo.fetchProfile(user.id);
      // Se per qualche motivo il profilo non esiste, non possiamo aggiornare l'avatar
      if (_profile == null) return;

      //upload su Storage con return url immagine caricata
      final imageUrl = await _repo.uploadImage(image.path, user.id);

      //aggiorno i dati dell'oggetto _profile
      _profile!.avatarUrl = imageUrl;

      //Aggiorno il profilo nel database
      await _repo.updateProfile(_profile!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}
