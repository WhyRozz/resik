import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // ✅ DATA & CONTROLLERS - PERSIST ACROSS BUILDS
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  // Data Lists
  List<Map<String, dynamic>> _kecamatanList = [];
  List<Map<String, dynamic>> _desaList = [];
  List<Map<String, dynamic>> _dinasList = [];

  bool _isLoadingKecamatan = false;
  bool _isLoadingDesa = false;
  bool _isLoadingDinas = false;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ✅ HELPER: Get or create controller (cached)
  TextEditingController _getController(String key, {String initialValue = ''}) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
      // Update formData when text changes
      _controllers[key]!.addListener(() {
        setState(() {
          _formData[key] = _controllers[key]!.text;
        });
      });
    }
    return _controllers[key]!;
  }

  @override
  void initState() {
    super.initState();
    _loadKecamatan();
    _loadDinas();
  }

  @override
  void dispose() {
    // ✅ Dispose semua controller
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadKecamatan() async {
    setState(() => _isLoadingKecamatan = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kecamatan'),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _kecamatanList = List<Map<String, dynamic>>.from(result['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error load kecamatan: $e');
    }
    setState(() => _isLoadingKecamatan = false);
  }

  Future<void> _loadDesa(int? kecamatanId) async {
    if (kecamatanId == null) {
      setState(() => _desaList = []);
      return;
    }

    setState(() => _isLoadingDesa = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/desa?kecamatan_id=$kecamatanId'),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _desaList = List<Map<String, dynamic>>.from(result['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error load desa: $e');
    }
    setState(() => _isLoadingDesa = false);
  }

  Future<void> _loadDinas() async {
    setState(() => _isLoadingDinas = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/dinas'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _dinasList = List<Map<String, dynamic>>.from(result['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error load dinas: $e');
    }
    setState(() => _isLoadingDinas = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan Progress
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Daftar Akun',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lengkapi data diri Anda untuk bergabung',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Progress Indicator
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index <= _currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: _currentStep == 0
                      ? _buildStep1()
                      : _currentStep == 1
                      ? _buildStep2()
                      : _buildStep3(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== STEP 1: DATA PRIBADI & LOKASI ====================
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            title: 'Data Pribadi',
            icon: Icons.person,
            children: [
              _buildTextField(
                label: 'Nama Lengkap',
                hint: 'Contoh: Budi Santoso',
                keyName: 'nama',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildDropdownStatic(
                label: 'Jenis Kelamin',
                keyName: 'gender',
                items: ['Laki-laki', 'Perempuan'],
                icon: Icons.male,
              ),
              const SizedBox(height: 16),
              _buildDateField(
                label: 'Tanggal Lahir',
                keyName: 'tglLahir',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              // Kecamatan (tanpa search)
              _buildSimpleDropdown(
                label: 'Kecamatan',
                keyName: 'kecamatan',
                items: _kecamatanList,
                itemKey: 'id_kecamatan',
                itemLabel: 'nama_kecamatan',
                icon: Icons.location_city,
                isLoading: _isLoadingKecamatan,
                onSelected: (val) {
                  if (val != null) {
                    final kecamatan = _kecamatanList.firstWhere(
                      (k) => k['id_kecamatan'] == val,
                      orElse: () => {},
                    );
                    _loadDesa(kecamatan['id_kecamatan']);
                    // Reset desa saat kecamatan berubah
                    _formData['desa'] = null;
                  }
                },
              ),
              const SizedBox(height: 16),

              // Desa (tanpa search, hanya enabled jika kecamatan dipilih)
              _buildSimpleDropdown(
                label: 'Desa/Kelurahan',
                keyName: 'desa',
                items: _desaList,
                itemKey: 'id_desa',
                itemLabel: 'nama_desa',
                icon: Icons.home_work_outlined,
                isLoading: _isLoadingDesa,
                enabled: _formData['kecamatan'] != null && _desaList.isNotEmpty,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: 'Alamat Lengkap',
                hint: 'Jl. Mawar No. 10, RT/RW, Kode Pos',
                keyName: 'alamat',
                icon: Icons.location_on,
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Pekerjaan
              _buildDropdownStatic(
                label: 'Pekerjaan',
                keyName: 'pekerjaan',
                items: ['Masyarakat Umum', 'ASN / PNS'],
                icon: Icons.work_outline,
                onChanged: (val) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              // Dinas (Hanya muncul jika ASN/PNS)
              if (_formData['pekerjaan'] == 'ASN / PNS') ...[
                _buildDropdown(
                  label: 'Dinas',
                  keyName: 'dinas',
                  items: _dinasList,
                  itemKey: 'id_dinas',
                  itemLabel: 'nama_dinas',
                  icon: Icons.business,
                  isLoading: _isLoadingDinas,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
          const SizedBox(height: 30),
          _buildButton('Lanjut', () {
            if (_validateStep1()) _nextStep();
          }),
        ],
      ),
    );
  }

  // ==================== STEP 2: KONTAK ====================
  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            title: 'Informasi Kontak',
            icon: Icons.contact_mail,
            children: [
              _buildTextField(
                label: 'No. Telepon',
                hint: '08xxxxxxxxxx',
                keyName: 'telepon',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Email',
                hint: 'email@contoh.com',
                keyName: 'email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildButtonOutline('Kembali', _prevStep)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildButton('Lanjut', () {
                  if (_validateStep2()) _nextStep();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== STEP 3: KEAMANAN ====================
  Widget _buildStep3() {
    final password = _formData['password'] ?? '';
    final validation = _validatePassword(password);
    final isStrong = _isPasswordStrong(password);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            title: 'Keamanan Akun',
            icon: Icons.lock,
            children: [
              _buildPasswordField(
                label: 'Password',
                keyName: 'password',
                hint: 'Minimal 8 karakter',
              ),
              // Password Requirements
              _buildPasswordRequirements(validation, isStrong),
              const SizedBox(height: 20),
              _buildPasswordField(
                label: 'Konfirmasi Password',
                keyName: 'konfirmasiPassword',
                hint: 'Ulangi password',
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildButtonOutline('Kembali', _prevStep)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildButton(
                  _isLoading ? 'Mendaftar...' : 'Daftar Sekarang',
                  _isLoading ? null : _submitRegistration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF22C55E)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String keyName,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final controller = _getController(
      keyName,
      initialValue: _formData[keyName]?.toString() ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontFamily: 'Poppins',
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF22C55E)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownStatic({
    required String label,
    required String keyName,
    required List<String> items,
    required IconData icon,
    Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _formData[keyName],
              hint: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Text(
                    'Pilih',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontFamily: 'Poppins')),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _formData[keyName] = val;
                });
                if (onChanged != null) onChanged(val);
              },
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String keyName,
    required List<Map<String, dynamic>> items,
    required String itemKey,
    required String itemLabel,
    required IconData icon,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    value: _formData[keyName],
                    hint: Row(
                      children: [
                        Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Text(
                          'Pilih',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    items: items.map((item) {
                      return DropdownMenuItem(
                        value: item[itemKey],
                        child: Text(
                          item[itemLabel],
                          style: const TextStyle(fontFamily: 'Poppins'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _formData[keyName] = val;
                      });
                    },
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
        ),
      ],
    );
  }

  // Ganti _buildSearchDropdown dengan dropdown biasa ini:

  Widget _buildSimpleDropdown({
    required String label,
    required String keyName,
    required List<Map<String, dynamic>> items,
    required String itemKey,
    required String itemLabel,
    required IconData icon,
    bool isLoading = false,
    Function(dynamic)? onSelected,
    bool enabled = true,
  }) {
    // Validasi: pastikan value ada di items
    final currentValue = _formData[keyName];
    final isValidValue =
        currentValue != null &&
        items.any((item) => item[itemKey] == currentValue);

    // Jika value tidak valid, reset
    if (currentValue != null && !isValidValue) {
      _formData[keyName] = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: isValidValue ? currentValue : null,
              hint: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  const Text(
                    'Pilih',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item[itemKey],
                  child: Text(
                    item[itemLabel],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF111827),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: enabled
                  ? (val) {
                      setState(() {
                        _formData[keyName] = val;
                      });
                      if (onSelected != null) onSelected(val);
                    }
                  : null,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String keyName,
    required IconData icon,
  }) {
    final controller = _getController(
      '${keyName}_display',
      initialValue: _formData[keyName] != null
          ? DateFormat('dd/MM/yyyy').format(_formData[keyName])
          : '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF22C55E),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _formData[keyName] = picked;
                if (_controllers.containsKey('${keyName}_display')) {
                  _controllers['${keyName}_display']!.text = DateFormat(
                    'dd/MM/yyyy',
                  ).format(picked);
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF22C55E)),
                    const SizedBox(width: 8),
                    Text(
                      controller.text.isEmpty
                          ? 'Pilih tanggal'
                          : controller.text,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String keyName,
    required String hint,
  }) {
    bool obscure = true;
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        final controller = _getController(
          keyName,
          initialValue: _formData[keyName]?.toString() ?? '',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: controller,
                obscureText: obscure,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF22C55E),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setStateLocal(() => obscure = !obscure);
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordRequirements(
    Map<String, bool> validation,
    bool isStrong,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStrong ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStrong ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Persyaratan Password:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem('Minimal 8 karakter', validation['minLength']!),
          _buildRequirementItem(
            'Huruf besar (A-Z)',
            validation['hasUppercase']!,
          ),
          _buildRequirementItem(
            'Huruf kecil (a-z)',
            validation['hasLowercase']!,
          ),
          _buildRequirementItem('Angka (0-9)', validation['hasNumber']!),
          _buildRequirementItem('Simbol (!@#\$%&*)', validation['hasSymbol']!),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? const Color(0xFF4CAF50) : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? const Color(0xFF1B5E20) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback? onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }

  Widget _buildButtonOutline(String text, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // ==================== VALIDASI & SUBMIT ====================

  Map<String, bool> _validatePassword(String password) {
    return {
      'minLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSymbol': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  bool _isPasswordStrong(String password) {
    final validation = _validatePassword(password);
    return validation['minLength']! &&
        validation['hasUppercase']! &&
        validation['hasLowercase']! &&
        validation['hasNumber']! &&
        validation['hasSymbol']!;
  }

  bool _validateStep1() {
    if ((_formData['nama'] ?? '').isEmpty) {
      _showError('Nama lengkap wajib diisi');
      return false;
    }
    if (_formData['gender'] == null) {
      _showError('Jenis kelamin wajib dipilih');
      return false;
    }
    if (_formData['tglLahir'] == null) {
      _showError('Tanggal lahir wajib dipilih');
      return false;
    }
    if (_formData['kecamatan'] == null) {
      _showError('Kecamatan wajib dipilih');
      return false;
    }
    if (_formData['desa'] == null) {
      _showError('Desa/Kelurahan wajib dipilih');
      return false;
    }
    if (_formData['pekerjaan'] == null) {
      _showError('Pekerjaan wajib dipilih');
      return false;
    }
    if (_formData['pekerjaan'] == 'ASN / PNS' && _formData['dinas'] == null) {
      _showError('Dinas wajib dipilih untuk ASN/PNS');
      return false;
    }
    if ((_formData['alamat'] ?? '').isEmpty) {
      _showError('Alamat wajib diisi');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if ((_formData['telepon'] ?? '').isEmpty) {
      _showError('No telepon wajib diisi');
      return false;
    }
    if ((_formData['email'] ?? '').isEmpty) {
      _showError('Email wajib diisi');
      return false;
    }
    if (!(_formData['email'] ?? '').contains('@')) {
      _showError('Email tidak valid');
      return false;
    }
    return true;
  }

  Future<void> _submitRegistration() async {
    final password = _formData['password'] ?? '';
    final konfirmasiPassword = _formData['konfirmasiPassword'] ?? '';

    if (password.isEmpty) {
      _showError('Password wajib diisi');
      return;
    }
    if (konfirmasiPassword.isEmpty) {
      _showError('Konfirmasi password wajib diisi');
      return;
    }
    if (password != konfirmasiPassword) {
      _showError('Password tidak cocok');
      return;
    }
    if (!_isPasswordStrong(password)) {
      _showError('Password tidak memenuhi persyaratan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ TENTUKAN TIPE USER BERDASARKAN PEKERJAAN
      final String tipeUser = _formData['pekerjaan'] == 'ASN / PNS'
          ? 'pns'
          : 'masyarakat';

      final requestData = {
        'tipe': tipeUser, // ✅ KIRIM 'tipe', bukan 'pekerjaan'
        'nama': _formData['nama'],
        'email': _formData['email'],
        'password': password,
        'password_confirmation': konfirmasiPassword,
        'no_telepon': _formData['telepon'],
        'jenis_kelamin': _formData['gender'],
        'tanggal_lahir': _formData['tglLahir'] != null
            ? DateFormat('yyyy-MM-dd').format(_formData['tglLahir'])
            : null,
        'alamat': _formData['alamat'],
        'id_desa': _formData['desa'],

        // ✅ HANYA KIRIM id_dinas JIKA PNS
        if (tipeUser == 'pns') 'id_dinas': _formData['dinas'],
      };

      debugPrint("📤 Sending registration: ${jsonEncode(requestData)}");

      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      final result = jsonDecode(response.body);

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['status'] == 'success') {
          _showSuccess('Registrasi berhasil! Silakan login.');
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          _showError(result['message'] ?? 'Registrasi gagal');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Terjadi kesalahan: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
