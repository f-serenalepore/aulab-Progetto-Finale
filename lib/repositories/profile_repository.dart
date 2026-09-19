import 'dart:io';

import 'package:aullet/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  //recupero il client Supabase già inizializzato nel main.dart
  final _client = Supabase.instance.client;

  //Restituisce il profilo dell'utente o null
  Future<Profile?> fetchProfile(String userId) async {
    //La richiesta di SELECT è asincrona e con await aspettiamo che Supabase restituisca il risultato.
    final data = await _client
        .from('profiles')
        .select() // di default equivale a select('*'), cioè seleziona tutte le colonne
        .eq('user_id', userId)
        .maybeSingle(); //zero o uno record

    if (data == null) return null;
    return Profile.fromMap(data);
  }

  //Inserisce un nuovo profilo
  Future<void> createProfile(Profile profile) async {
    // await attende il completamento dell'operazione asincrona di INSERT
    final _ = await _client
        .from('profiles')
        .insert(
          profile.toMap(),
        ); //final _ significa che non mi interessa il valore che supabase mi restituisce (lista di mappe)
  }

  //Aggiorna il profilo esistente
  Future<void> updateProfile(Profile profile) async {
    final _ = await _client
        .from('profiles')
        .update(profile.toMap())
        .eq('user_id', profile.userId);
  }

  //carica file nel bucket 'image'
  Future<String> uploadImage(String imagePath, String userId) async {
    // Creiamo un percorso univoco per l'immagine
    final filePath = '$userId/avatar.jpg';

    await _client
        .storage //accedo a Supabase Storage
        .from('image') //seleziono bucket 'image'
        .upload(
          filePath,
          File(imagePath), //trasforma il path locale in un file
          fileOptions: const FileOptions(
            upsert: true, // permette di sostituire il file
          ),
        );

    final imageUrl = _client.storage.from('image').getPublicUrl(filePath);

    // Aggiungiamo un parametro per evitare la cache
    final uniqueUrl = '$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    return uniqueUrl; //restituisce url immagine
  }
}
