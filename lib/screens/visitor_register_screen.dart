import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visitor_management/services/visitor_api_service.dart';

import '../core/app_exception.dart';
import '../core/constants.dart';
import '../models/visitor.dart';
import '../providers/visitor_providers.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'visitor_details_screen.dart';

/// Used for both registering a new visitor and editing an existing one.
class VisitorRegisterScreen extends ConsumerStatefulWidget {
  const VisitorRegisterScreen({super.key, this.visitor});

  /// When provided, the form is in edit mode.
  final Visitor? visitor;

  @override
  ConsumerState<VisitorRegisterScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends ConsumerState<VisitorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _purposeController;
  String? _visitorType;
  String? _project;
  bool _isSaving = false;

  bool get _isEdit => widget.visitor != null;

  @override
  void initState() {
    super.initState();
    final v = widget.visitor;
    _nameController = TextEditingController(text: v?.name ?? '');
    _mobileController = TextEditingController(text: v?.mobile ?? '');
    _emailController = TextEditingController(text: v?.email ?? '');
    _purposeController = TextEditingController(text: v?.purpose ?? '');
    // Only keep saved values that exist in the dropdown lists.
    _visitorType =
        AppConstants.visitorTypes.contains(v?.visitorType) ? v?.visitorType : null;
    _project = AppConstants.projects.contains(v?.project) ? v?.project : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String message) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }

  String? _validateMobile(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(text)) {
      return 'Enter exactly 10 digits';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // optional
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final existing = widget.visitor;
    final email = _emailController.text.trim();

    final visitor = Visitor(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: email.isEmpty ? null : email,
      visitorType: _visitorType!,
      project: _project!,
      purpose: _purposeController.text.trim(),
      status: existing?.status ?? VisitorStatus.registered,
      createdAt: existing?.createdAt ?? DateTime.now(),
      checkInTime: existing?.checkInTime,
      checkOutTime: existing?.checkOutTime,
    );

    setState(() => _isSaving = true);
    final api = VisitorApiService();

    try {
      if (existing == null) {
        // ---- POST to crudcrud ----
        final created = await api.createVisitor(visitor);
        await ref.read(visitorsProvider.notifier).addVisitor(created);

        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => VisitorDetailsScreen(visitorId: created.id),
          ),
        );
        messenger.showSnackBar(appSnackBar('Visitor registered successfully'));
      } else {
        // ---- PUT to crudcrud ----
        final updated = await api.updateVisitor(visitor.id, visitor);
        await ref.read(visitorsProvider.notifier).updateVisitor(updated);

        navigator.pop();
        messenger.showSnackBar(appSnackBar('Visitor updated successfully'));
      }
    } on AppException catch (e) {
      messenger.showSnackBar(appSnackBar(e.message, isError: true));
      if (mounted) setState(() => _isSaving = false);
    } catch (e) {
      messenger.showSnackBar(appSnackBar('Unexpected error: $e', isError: true));
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Visitor' : 'Register Visitor')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Visitor Name',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _validateRequired(v, 'Name is required'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: _validateMobile,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email (optional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _visitorType,
                  decoration: const InputDecoration(
                    labelText: 'Visitor Type',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    for (final type in AppConstants.visitorTypes)
                      DropdownMenuItem(value: type, child: Text(type)),
                  ],
                  onChanged: (value) => setState(() => _visitorType = value),
                  validator: (v) => v == null ? 'Select a visitor type' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _project,
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    prefixIcon: Icon(Icons.apartment_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    for (final project in AppConstants.projects)
                      DropdownMenuItem(value: project, child: Text(project)),
                  ],
                  onChanged: (value) => setState(() => _project = value),
                  validator: (v) => v == null ? 'Select a project' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _purposeController,
                  label: 'Purpose of Visit',
                  icon: Icons.edit_note,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      _validateRequired(v, 'Purpose of visit is required'),
                ),
                const SizedBox(height: 24),
             const SizedBox(height: 24),
Row(
  children: [
    Expanded(
      child: CustomButton(
        label: 'Cancel',
        isOutlined: true,
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: CustomButton(
        label: 'Save',
        icon: Icons.save_outlined,
        isLoading: _isSaving,
        onPressed: _save,
      ),
    ),
  ],
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}