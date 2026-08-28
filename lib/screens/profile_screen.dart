import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  final String email;

  const ProfileScreen({super.key, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Prefer not to say';
  Uint8List? _profileImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await StorageService.getProfile();
    if (!mounted) return;
    _nameController.text = profile['name']!;
    _phoneController.text = profile['phone']!;
    _ageController.text = profile['age']!;
    _gender = profile['gender']!.isEmpty ? _gender : profile['gender']!;
    final image = profile['image']!;
    if (image.isNotEmpty) _profileImage = base64Decode(image);
    setState(() => _isLoading = false);
  }

  Future<void> _chooseImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _profileImage = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await StorageService.saveProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _gender,
      age: _ageController.text.trim(),
      imageBase64: _profileImage == null ? null : base64Encode(_profileImage!),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _profileImage == null
                              ? null
                              : MemoryImage(_profileImage!),
                          child: _profileImage == null
                              ? const Icon(Icons.person, size: 64)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton.filled(
                            onPressed: _chooseImage,
                            icon: const Icon(Icons.camera_alt),
                            tooltip: 'Change profile picture',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _field(_nameController, 'Name'),
                  const SizedBox(height: 14),
                  _field(
                    _phoneController,
                    'Phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: widget.email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'Prefer not to say',
                              'Female',
                              'Male',
                              'Non-binary',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _gender = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    _ageController,
                    'Age',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save profile'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Enter your $label' : null,
    );
  }
}
