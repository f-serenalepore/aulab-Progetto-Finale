import 'package:aullet/viewmodel/profile_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewmodel>();
    vm.loadProfile().then((_) {
      if (vm.profile != null) {
        _nameCtrl.text = vm.profile!.displayName;
      }
    });
  }

  //Refactoring del View ProfilePage()//////////////////////////////////
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //aggiunta riga seguente, assente nel codice del docente
    final vm = context.read<ProfileViewmodel>();
    //solo la prima volta schedulo il caricamento in post frame
    if (!_didScheduleLoad) {
      _didScheduleLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        //carico i dati dal ViewModel
        await context.read<ProfileViewmodel>().loadProfile();
        //dopo il caricamento popolo il TextEditingController
        if (mounted && vm.profile != null) {
          _nameCtrl.text = vm.profile!.displayName;
        }
      });
    }
  }
  ///////////////////////////////////////////////////////////////////////

  @override //best practice
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewmodel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
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
                  TextButton(
                    onPressed: vm.pickAndUploadAvatar,
                    child: const Text('Cambia Avatar'),
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
