import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../domain/entities/authentication.dart';
import '../../../../domain/repositories/user_repository.dart';
import '../../../shared/widgets/common_widgets.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  bool _isAddingUser = false;
  bool _isEditingUser = false;
  User? _editingUser;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userUsernameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  String _userRoleSelection = 'volailler';

  List<User> _usersList = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userUsernameController.dispose();
    _userPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await getIt<UserRepository>().getUsers();

    if (mounted) {
      setState(() {
        _isLoading = false;
        result.fold(
          (failure) => _errorMessage = failure.message,
          (users) => _usersList = users,
        );
      });
    }
  }

  Future<void> _createUser() async {
    final name = _userNameController.text.trim();
    final username = _userUsernameController.text.trim();
    final password = _userPasswordController.text;
    final role = _userRoleSelection;

    if (!mounted) return;
    showActionLoadingDialog(context, message: 'Création du collaborateur...');

    try {
      setState(() => _isLoading = true);

      final result = await getIt<UserRepository>().createUser(
        email: '${username.toLowerCase()}@fermetrack.com',
        username: username,
        fullName: name,
        phone: '0112233455',
        role: role,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isLoading = false);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${failure.message}')),
          );
        },
        (newUser) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collaborateur créé avec succès !')),
          );
          setState(() {
            _isAddingUser = false;
          });
          _loadUsers();
        },
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la création du collaborateur.')),
        );
      }
    }
  }

  Future<void> _updateUser() async {
    if (_editingUser == null) return;
    final name = _userNameController.text.trim();
    final username = _userUsernameController.text.trim();
    final role = _userRoleSelection;

    if (!mounted) return;
    showActionLoadingDialog(context, message: 'Mise à jour du collaborateur...');

    try {
      setState(() => _isLoading = true);

      final result = await getIt<UserRepository>().updateUser(
        userId: _editingUser!.id,
        email: _editingUser!.email.isEmpty ? '${username.toLowerCase()}@fermetrack.com' : _editingUser!.email,
        fullName: name,
        phone: '0112233455',
        role: role,
        status: 'active',
        farmId: _editingUser!.farmId ?? '2ef87261-ee96-4c67-8e4f-fc63825230cb',
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isLoading = false);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de mise à jour: ${failure.message}')),
          );
        },
        (updatedUser) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collaborateur mis à jour avec succès !')),
          );
          setState(() {
            _isEditingUser = false;
            _editingUser = null;
          });
          _loadUsers();
        },
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la mise à jour du collaborateur.')),
        );
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    if (!mounted) return;
    showActionLoadingDialog(context, message: 'Suppression du collaborateur...');

    try {
      setState(() => _isLoading = true);

      final result = await getIt<UserRepository>().deleteUser(user.id);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isLoading = false);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de suppression: ${failure.message}')),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Utilisateur ${user.fullName} supprimé')),
          );
          _loadUsers();
        },
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression du collaborateur.')),
        );
      }
    }
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
          if (_isLoading && _usersList.isEmpty)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null && _usersList.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadUsers,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadUsers,
                child: ListView.builder(
                  itemCount: _usersList.length,
                  itemBuilder: (context, index) {
                    final user = _usersList[index];
                    IconData roleIcon = Icons.person;
                    if (user.role == 'directeur') roleIcon = Icons.admin_panel_settings;
                    if (user.role == 'technicien') roleIcon = Icons.engineering;
                    if (user.role == 'volailler') roleIcon = Icons.agriculture;
                    if (user.role == 'magasinier') roleIcon = Icons.store;

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
                                  user.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Identifiant: ${user.username}  ·  Rôle: ${user.role}',
                                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                                ),
                                Text(
                                  'Email: ${user.email}',
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
                                _editingUser = user;
                                _userNameController.text = user.fullName;
                                _userUsernameController.text = user.username;
                                _userPasswordController.clear();
                                _userRoleSelection = user.role;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.danger),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Supprimer un utilisateur'),
                                  content: Text('Voulez-vous vraiment supprimer ${user.fullName} ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteUser(user);
                                      },
                                      child: const Text(
                                        'Supprimer',
                                        style: TextStyle(color: AppColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
            readOnly: _isEditingUser, // Login cannot be updated
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
          if (!_isEditingUser) ...[
            AppInputBox(
              label: 'Mot de passe',
              placeholder: 'Ex: yaopassword',
              controller: _userPasswordController,
            ),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isAddingUser = false;
                        _isEditingUser = false;
                        _editingUser = null;
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
                          (!_isEditingUser && _userPasswordController.text.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez remplir tous les champs')),
                        );
                        return;
                      }

                      if (_isEditingUser) {
                        _updateUser();
                      } else {
                        _createUser();
                      }
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
