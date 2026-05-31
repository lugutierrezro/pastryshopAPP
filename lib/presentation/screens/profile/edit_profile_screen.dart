import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _direccionCtrl;

  Uint8List? _imageBytes;
  String? _imageName;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nombreCtrl = TextEditingController(text: user?.nombre);
    _apellidoCtrl = TextEditingController(text: user?.apellido);
    _telefonoCtrl = TextEditingController(text: user?.telefono);
    _direccionCtrl = TextEditingController(text: user?.direccion);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
      }
    } catch (e) {
      ToastUtils.showError('No se pudo seleccionar la imagen');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    // If an image was picked, upload it first
    if (_imageBytes != null) {
      final url = await auth.uploadProfilePicture(_imageName ?? 'avatar_${auth.user?.id}.jpg', _imageBytes!);
      if (url == null) {
        ToastUtils.showError(auth.error ?? 'Error subiendo la imagen');
        setState(() => _isSaving = false);
        return;
      }
    }

    final success = await auth.updateProfile({
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
    });

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        ToastUtils.showSuccess('Perfil actualizado correctamente');
        Navigator.of(context).pop();
      }
    } else {
      ToastUtils.showError(auth.error ?? 'Error al actualizar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!) as ImageProvider
                          : (user?.imagenUrl != null && user!.imagenUrl!.isNotEmpty)
                              ? NetworkImage(user.imagenUrl!)
                              : null,
                      child: (_imageBytes == null && (user?.imagenUrl == null || user!.imagenUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoCtrl,
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'El apellido es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
