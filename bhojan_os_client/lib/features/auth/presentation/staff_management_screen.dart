import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'staff_notifier.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(staffProvider.notifier).fetchStaff());
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddStaffDialog(),
    );
  }

  void _showEditStaffDialog(StaffMember member) {
    showDialog(
      context: context,
      builder: (context) => _EditStaffDialog(member: member),
    );
  }

  void _showResetAuthDialog(StaffMember member) {
    showDialog(
      context: context,
      builder: (context) => _ResetAuthDialog(member: member),
    );
  }

  void _handleDeleteStaff(StaffMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Account'),
        content: Text('Are you sure you want to delete ${member.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8102E)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(staffProvider.notifier).deleteStaff(member.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member deleted successfully.')),
          );
        } else {
          final err = ref.read(staffProvider).errorMessage ?? 'Failed to delete staff member.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Staff Roster', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003893))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            onPressed: () => ref.read(staffProvider.notifier).fetchStaff(),
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: staffState.isLoading && staffState.roster.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : staffState.roster.isEmpty
              ? const Center(
                  child: Text('No staff accounts registered.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: staffState.roster.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = staffState.roster[index];
                    return _buildStaffMemberCard(member);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF003893),
        onPressed: _showAddStaffDialog,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _buildStaffMemberCard(StaffMember member) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                member.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003893)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(member.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(member.role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Phone: ${member.phone}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Row(
              children: [
                Switch(
                  value: member.isActive,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) => ref.read(staffProvider.notifier).toggleActive(member.id, val),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditStaffDialog(member);
                    } else if (val == 'reset') {
                      _showResetAuthDialog(member);
                    } else if (val == 'delete') {
                      _handleDeleteStaff(member);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                    const PopupMenuItem(value: 'reset', child: Text('Reset Credentials')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete staff', style: TextStyle(color: Color(0xFFC8102E)))),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _AddStaffDialog extends ConsumerStatefulWidget {
  const _AddStaffDialog();

  @override
  ConsumerState<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends ConsumerState<_AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  String _selectedRole = 'WAITER';

  final List<String> _roles = ['OWNER', 'MANAGER', 'CASHIER', 'WAITER', 'KITCHEN'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(staffProvider.notifier).createStaff(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            pin: _pinController.text.trim(),
            role: _selectedRole,
          );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member registered successfully.')),
          );
        } else {
          final err = ref.read(staffProvider).errorMessage ?? 'Registration failed.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Staff Member'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (val) => val == null || val.trim().length < 8 ? 'Enter valid phone number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Login Password *', prefixIcon: Icon(Icons.lock_outline)),
                validator: (val) => val == null || val.length < 6 ? 'Password must be >= 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Screen PIN (4 Digits) *', prefixIcon: Icon(Icons.pin_outlined)),
                validator: (val) => val == null || val.trim().length != 4 ? 'Enter 4-digit PIN' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Staff Role *', prefixIcon: Icon(Icons.badge_outlined)),
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003893)),
          onPressed: _submit,
          child: const Text('Register', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _EditStaffDialog extends ConsumerStatefulWidget {
  final StaffMember member;
  const _EditStaffDialog({required this.member});

  @override
  ConsumerState<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends ConsumerState<_EditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedRole;

  final List<String> _roles = ['OWNER', 'MANAGER', 'CASHIER', 'WAITER', 'KITCHEN'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phone);
    _selectedRole = widget.member.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(staffProvider.notifier).updateStaff(
            id: widget.member.id,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole,
          );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff profile updated successfully.')),
          );
        } else {
          final err = ref.read(staffProvider).errorMessage ?? 'Update failed.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Staff Member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
              validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (val) => val == null || val.trim().length < 8 ? 'Enter valid phone number' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Staff Role *', prefixIcon: Icon(Icons.badge_outlined)),
              items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003893)),
          onPressed: _submit,
          child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _ResetAuthDialog extends ConsumerStatefulWidget {
  final StaffMember member;
  const _ResetAuthDialog({required this.member});

  @override
  ConsumerState<_ResetAuthDialog> createState() => _ResetAuthDialogState();
}

class _ResetAuthDialogState extends ConsumerState<_ResetAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(staffProvider.notifier).resetCredentials(
            id: widget.member.id,
            password: _passwordController.text,
            pin: _pinController.text,
          );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credentials reset successfully.')),
          );
        } else {
          final err = ref.read(staffProvider).errorMessage ?? 'Reset failed.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reset Credentials: ${widget.member.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Login Password (Optional)', prefixIcon: Icon(Icons.lock_outline)),
              validator: (val) {
                if (val != null && val.isNotEmpty && val.length < 6) return 'Password must be >= 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New Screen PIN (Optional)', prefixIcon: Icon(Icons.pin_outlined)),
              validator: (val) {
                if (val != null && val.isNotEmpty && val.trim().length != 4) return 'PIN must be 4 digits';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003893)),
          onPressed: _submit,
          child: const Text('Reset', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
