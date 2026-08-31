import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  bool _isAddingUser = false;
  bool _isEditingUser = false;
  int? _editingUserIndex;

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userUsernameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  String _userRoleSelection = 'volailler';

  final List<Map<String, String>> _usersList = [
    {
      'name': 'Directeur Général',
      'username': 'directeur',
      'role': 'directeur',
      'password': 'password123',
    },
    {
      'name': 'Dr. Koffi (Technicien)',
      'username': 'technicien',
      'role': 'technicien',
      'password': 'techpassword',
    },
    {
      'name': 'Ama Koffi (Volailler)',
      'username': 'volailler',
      'role': 'volailler',
      'password': 'volaillerpass',
    },
    {
      'name': 'Yao (Magasinier)',
      'username': 'magasinier',
      'role': 'magasinier',
      'password': 'magasinierpass',
    },
  ];

  @override
  void dispose() {
    _userNameController.dispose();
    _userUsernameController.dispose();
    _userPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingUser || _isEditingUser) {
      return _buildUserForm();
    }
    return _buildUserList();
  }

  Widget _buildUserList() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingUser = true;
                  _userNameController.clear();
                  _userUsernameController.clear();
                  _userPasswordController.clear();
                  _userRoleSelection = 'volailler';
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un utilisateur'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('UTILISATEURS ENREGISTRÉS', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          Expanded(
            child: ListView.builder(
              itemCount: _usersList.length,
              itemBuilder: (context, index) {
                final user = _usersList[index];
                IconData roleIcon = Icons.person;
                if (user['role'] == 'directeur') roleIcon = Icons.admin_panel_settings;
                if (user['role'] == 'technicien') roleIcon = Icons.engineering;
                if (user['role'] == 'volailler') roleIcon = Icons.agriculture;
                if (user['role'] == 'magasinier') roleIcon = Icons.store;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(roleIcon, color: AppColors.primaryDark, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Identifiant: ${user['username']}  ·  Rôle: ${user['role']}',
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                            ),
                            Text(
                              'Mot de passe: ${user['password']}',
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primaryDark),
                        onPressed: () {
                          setState(() {
                            _isEditingUser = true;
                            _editingUserIndex = index;
                            _userNameController.text = user['name']!;
                            _userUsernameController.text = user['username']!;
                            _userPasswordController.text = user['password']!;
                            _userRoleSelection = user['role']!;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.danger),
                        onPressed: () {
                          setState(() {
                            final deleted = _usersList.removeAt(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Utilisateur ${deleted['name']} supprimé')),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditingUser ? 'MODIFIER L\'UTILISATEUR' : 'AJOUTER UN NOUVEL UTILISATEUR',
            style: AppTypography.label,
          ),
          const SizedBox(height: 16),
          AppInputBox(
            label: 'Nom complet',
            placeholder: 'Ex: Yao Koffi',
            controller: _userNameController,
          ),
          const SizedBox(height: 14),
          AppInputBox(
            label: 'Identifiant (Login)',
            placeholder: 'Ex: yaokoffi',
            controller: _userUsernameController,
          ),
          const SizedBox(height: 14),
          const Text('Rôle de l\'utilisateur', style: AppTypography.label),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line, width: 1.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _userRoleSelection,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _userRoleSelection = val);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'directeur', child: Text('Directeur')),
                  DropdownMenuItem(value: 'technicien', child: Text('Technicien')),
                  DropdownMenuItem(value: 'volailler', child: Text('Volailler')),
                  DropdownMenuItem(value: 'magasinier', child: Text('Magasinier')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppInputBox(
            label: 'Mot de passe',
            placeholder: 'Ex: yaopassword',
            controller: _userPasswordController,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isAddingUser = false;
                      _isEditingUser = false;
                      _editingUserIndex = null;
                    });
                  },
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_userNameController.text.isEmpty ||
                        _userUsernameController.text.isEmpty ||
                        _userPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir tous les champs')),
                      );
                      return;
                    }

                    setState(() {
                      if (_isEditingUser && _editingUserIndex != null) {
                        _usersList[_editingUserIndex!] = {
                          'name': _userNameController.text,
                          'username': _userUsernameController.text,
                          'role': _userRoleSelection,
                          'password': _userPasswordController.text,
                        };
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Utilisateur mis à jour')),
                        );
                      } else {
                        _usersList.add({
                          'name': _userNameController.text,
                          'username': _userUsernameController.text,
                          'role': _userRoleSelection,
                          'password': _userPasswordController.text,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Utilisateur ajouté')),
                        );
                      }
                      _isAddingUser = false;
                      _isEditingUser = false;
                      _editingUserIndex = null;
                    });
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
