import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/phone_input_formatter.dart';
import '../utils/profile_photo.dart';
import '../widgets/user_avatar.dart';

enum _PhotoAction {
  gallery(
    Icons.photo_library_outlined,
    'Escolher da galeria',
    ImageSource.gallery,
  ),
  camera(Icons.photo_camera_outlined, 'Tirar foto', ImageSource.camera),
  remove(Icons.delete_outline_rounded, 'Remover foto', null);

  const _PhotoAction(this.icon, this.label, this.source);

  final IconData icon;
  final String label;
  final ImageSource? source;
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  String _email = '';
  String? _photo;
  bool _loading = true;
  bool _saving = false;
  bool _savingPhoto = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final user = await ApiService.fetchMe();
      if (!mounted) return;
      setState(() {
        _nameController.text = user['nome'] as String? ?? '';
        _phoneController.text = PhoneInputFormatter.format(
          user['telefone'] as String? ?? '',
        );
        _email = user['email'] as String? ?? '';
        _photo = user['foto_perfil'] as String?;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _loadError = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final phone = _phoneController.text.trim();
      await ApiService.updateMe(
        nome: _nameController.text.trim(),
        telefone: phone.isEmpty ? null : phone,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados da conta atualizados.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _saveError = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static bool get _canUseCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _changePhoto() async {
    final actions = [
      _PhotoAction.gallery,
      if (_canUseCamera) _PhotoAction.camera,
      if (_photo != null) _PhotoAction.remove,
    ];
    final action = actions.length == 1
        ? actions.single
        : await showModalBottomSheet<_PhotoAction>(
            context: context,
            showDragHandle: true,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final action in actions)
                    ListTile(
                      leading: Icon(action.icon),
                      title: Text(action.label),
                      onTap: () => Navigator.of(context).pop(action),
                    ),
                ],
              ),
            ),
          );
    if (action == null || !mounted) return;

    setState(() => _savingPhoto = true);
    try {
      final user = action == _PhotoAction.remove
          ? await ApiService.deleteProfilePhoto()
          : await _pickAndUploadPhoto(action.source!);
      if (user == null || !mounted) return;
      setState(() => _photo = user['foto_perfil'] as String?);
      _showMessage(
        action == _PhotoAction.remove
            ? 'Foto removida.'
            : 'Foto de perfil atualizada.',
      );
    } on PlatformException {
      _showMessage(
        'Não foi possível abrir a câmera ou a galeria. Verifique as permissões do app.',
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<Map<String, dynamic>?> _pickAndUploadPhoto(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final Uint8List photo;
    try {
      photo = await prepareProfilePhoto(await file.readAsBytes());
    } catch (_) {
      throw Exception(
        'Não foi possível ler essa imagem. Escolha uma foto JPG ou PNG.',
      );
    }
    return ApiService.updateProfilePhoto(photo);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final photoLabel = _photo == null ? 'Adicionar foto' : 'Alterar foto';
    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _errorView()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            UserAvatar(
                              name: _nameController.text,
                              photo: _photo,
                              radius: 48,
                            ),
                            Positioned(
                              right: -6,
                              bottom: -6,
                              child: IconButton.filled(
                                onPressed: _savingPhoto ? null : _changePhoto,
                                tooltip: photoLabel,
                                style: IconButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    width: 3,
                                  ),
                                ),
                                icon: _savingPhoto
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.photo_camera_rounded,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _savingPhoto ? null : _changePhoto,
                          child: Text(photoLabel),
                        ),
                      ),
                      Text(
                        _email,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.palette.muted),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Informe ao menos 2 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: _email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          helperText: 'O e-mail é usado para entrar e não pode ser alterado.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Telefone (opcional)',
                          hintText: '(11) 98765-4321',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) =>
                            PhoneInputFormatter.isValid(value ?? '')
                            ? null
                            : 'Telefone inválido. Informe DDD e número.',
                      ),
                      if (_saveError != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _saveError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: context.palette.muted),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar sua conta.\n$_loadError',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
