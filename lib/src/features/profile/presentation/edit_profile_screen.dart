import 'dart:convert';
import 'dart:io';

import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _saving = false;

  String? _avatarBase64;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();

    final user = ref.read(authRepositoryProvider).currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _avatarBase64 = user?.avatarBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 35,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    if (base64Image.length > 850000) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La imagen es demasiado grande. Elige otra mas pequena.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedImage = file;
      _avatarBase64 = base64Image;
    });
  }

  ImageProvider? _avatarImageProvider() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_avatarBase64!));
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No hay usuario conectado')));
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.id).set({
        'id_usuario': user.id,
        'nombre': _nameController.text.trim(),
        'telefono': _phoneController.text.trim(),
        if (_avatarBase64 != null && _avatarBase64!.isNotEmpty)
          'avatar_base64': _avatarBase64,
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));

      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar perfil: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _avatarImageProvider();

    return PremiumScaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              BrandHeader(
                title: 'Edit profile',
                subtitle:
                    'Keep your ChargeGO identity polished and up to date.',
                compact: true,
                trailing: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(
                            Icons.add_a_photo_rounded,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PremiumCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introduce un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefono (opcional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Guardar cambios',
                  icon: Icons.save_rounded,
                  onPressed: _saving ? null : _save,
                  isLoading: _saving,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pulsa la foto para cambiar avatar',
                style: TextStyle(color: ChargeGoColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
