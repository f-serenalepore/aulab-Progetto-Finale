import 'package:aullet/viewmodel/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  bool _didScheduleLoad = false;

  //Refactoring del View ProfilePage()//////////////////////////////////
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //aggiunta riga seguente, assente nel codice del docente
    final vm = context.read<ProfileViewModel>();
    //solo la prima volta schedulo il caricamento in post frame
    if (!_didScheduleLoad) {
      //flag per chiamare la callback solo una volta
      _didScheduleLoad = true;
      //addPostFrameCallback() permette di eseguire il codice dopo il primo frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        //carico i dati dal ViewModel
        await vm.loadProfile();
        //dopo il caricamento popolo il TextEditingController
        //mounted verifica che lo State sia ancora attivo prima di aggiornare il controller
        if (mounted && vm.profile != null) {
          _nameCtrl.text = vm.profile!.displayName;
        }
      });
    }
  }
  ///////////////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();
    vm.loadProfile().then((_) {
      if (vm.profile != null) {
        _nameCtrl.text = vm.profile!.displayName;
      }
    });
  }

  @override //best practice
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (vm.profile != null) {
                        vm.pickAndUploadAvatar(vm.profile!.userId);
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: vm.profile?.avatarUrl != null
                              ? NetworkImage(vm.profile!.avatarUrl!)
                              : null,
                          child: vm.profile?.avatarUrl == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      vm.updateDisplayName(_nameCtrl.text);
                    },
                    child: const Text('Salva'),
                  ),

                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
