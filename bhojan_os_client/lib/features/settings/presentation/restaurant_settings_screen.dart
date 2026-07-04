import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_notifier.dart';

class RestaurantSettingsScreen extends ConsumerStatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  ConsumerState<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends ConsumerState<RestaurantSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();
  final _vatController = TextEditingController();
  final _scController = TextEditingController();

  String _selectedCurrency = 'NPR';
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch profile and populate form fields
    Future.microtask(() async {
      await ref.read(settingsProvider.notifier).fetchSettings();
      final current = ref.read(settingsProvider).settings;
      if (current != null) {
        _nameController.text = current.name;
        _phoneController.text = current.phone;
        _addressController.text = current.address;
        _panController.text = current.panNumber ?? '';
        _vatController.text = current.vatRate.toStringAsFixed(2);
        _scController.text = current.scRate.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _panController.dispose();
    _vatController.dispose();
    _scController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final vat = double.tryParse(_vatController.text) ?? 0.0;
      final sc = double.tryParse(_scController.text) ?? 0.0;

      final success = await ref.read(settingsProvider.notifier).updateSettings(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            panNumber: _panController.text.trim(),
            vatRate: vat,
            scRate: sc,
          );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003893))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF003893),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF003893),
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.store_outlined)),
            Tab(text: 'Taxes & Currency', icon: Icon(Icons.percent_outlined)),
            Tab(text: 'Thermal Printer', icon: Icon(Icons.print_outlined)),
          ],
        ),
      ),
      body: state.isLoading && state.settings == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(state),
                  _buildTaxTab(state),
                  _buildPrinterTab(),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: state.isLoading ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003893),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Save Configuration Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildProfileTab(SettingsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Restaurant Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Provide general identification parameters printed on tax bills.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Restaurant Brand Name *',
              prefixIcon: const Icon(Icons.store_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Enter brand name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Contact Phone Number *',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) => val == null || val.trim().length < 8 ? 'Enter valid phone number' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Restaurant Physical Address *',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Enter address' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _panController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'PAN Number (9 digits) *',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) => val == null || val.trim().length < 9 ? 'Enter a valid Nepalese PAN number' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxTab(SettingsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Taxation & Government Charges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Configures Nepalese tax calculations (Standard VAT 13% and Service Charge 10%).', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          TextFormField(
            controller: _vatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Value Added Tax (VAT) % *',
              prefixIcon: const Icon(Icons.percent_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid VAT %' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _scController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Service Charge % *',
              prefixIcon: const Icon(Icons.room_service_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid SC %' : null,
          ),
          const SizedBox(height: 32),
          const Text('Preferences Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: InputDecoration(
              labelText: 'Base Currency',
              prefixIcon: const Icon(Icons.currency_exchange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: const [
              DropdownMenuItem(value: 'NPR', child: Text('Nepalese Rupee (NPR)')),
              DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD)')),
            ],
            onChanged: (val) => setState(() => _selectedCurrency = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: InputDecoration(
              labelText: 'System Language',
              prefixIcon: const Icon(Icons.language),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Nepali', child: Text('Nepali (नेपाली)')),
            ],
            onChanged: (val) => setState(() => _selectedLanguage = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ESC/POS Thermal Printer Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Configure 80mm cash counter printers.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.print_disabled_outlined, color: Color(0xFFC8102E), size: 36),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No Hardware Printer Connected', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          Text('Mock thermal receipt viewer will trigger instead.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Triggers search scan dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scanning for local Bluetooth and USB receipt printers...')),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search Devices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF003893),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
