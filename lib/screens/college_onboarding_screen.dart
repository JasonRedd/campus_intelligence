import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CollegeOnboardingScreen extends StatefulWidget {
  const CollegeOnboardingScreen({super.key});

  @override
  State<CollegeOnboardingScreen> createState() =>
      _CollegeOnboardingScreenState();
}

class _CollegeOnboardingScreenState extends State<CollegeOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collegeController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;
  bool _confirmedCollege = false;

  @override
  void dispose() {
    _collegeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _collegeId(String name) {
    final normalized = name.toLowerCase().trim().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _updateCollegePreview(String value) {
    if (_confirmedCollege) {
      setState(() => _confirmedCollege = false);
    } else {
      setState(() {});
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final name = _collegeController.text.trim();
    final address = _addressController.text.trim();
    final collegeId = _collegeId(name);
    if (collegeId.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final collegeRef = firestore.collection('colleges').doc(collegeId);
      final profileRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('details');
      final memberRef = collegeRef.collection('members').doc(user.uid);
      final batch = firestore.batch();

      batch.set(collegeRef, {
        'name': name,
        'normalizedName': collegeId,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(profileRef, {
        'collegeId': collegeId,
        'collegeName': name,
        'collegeAddress': address,
        'collegeJoinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(memberRef, {
        'uid': user.uid,
        'email': user.email,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 64,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose your campus',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your campus community, knowledge, and updates will be kept in its own environment.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _collegeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'College or university',
                        prefixIcon: Icon(Icons.school_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value != null &&
                              value.trim().length >= 3
                          ? null
                          : 'Enter your college or university name',
                      onChanged: _updateCollegePreview,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'College address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value != null &&
                              value.trim().length >= 5
                          ? null
                          : 'Enter the college address',
                    ),
                    if (_collegeId(_collegeController.text).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: theme.colorScheme.primaryContainer.withAlpha(90),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your campus zone',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _collegeId(_collegeController.text),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This ID keeps your MemoryMap, feed, and campus updates in the correct college environment.',
                                style: theme.textTheme.bodySmall,
                              ),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _confirmedCollege,
                                onChanged: (value) => setState(
                                  () => _confirmedCollege = value ?? false,
                                ),
                                title: const Text(
                                  'I confirm this is my college',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving || !_confirmedCollege
                          ? null
                          : _continue,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward),
                      label: Text(_isSaving ? 'Joining campus...' : 'Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
