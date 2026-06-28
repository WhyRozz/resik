import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/dinas_service.dart';
import '../../../services/desa_service.dart';

class RegisterStep1 extends StatefulWidget {
  const RegisterStep1({super.key});

  @override
  State<RegisterStep1> createState() => _RegisterStep1State();
}

class _RegisterStep1State extends State<RegisterStep1> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _alamatCtrl = TextEditingController();
  final TextEditingController _tglLahirCtrl = TextEditingController();
  DateTime? _selectedDate;

  // State Dropdowns
  String? _selectedGender;
  String? _selectedJob;
  String? _selectedDinasId;
  String? _selectedDesaId;

  // Data State
  List<Map<String, dynamic>> _dinasData = [];
  List<Map<String, dynamic>> _desaData = [];
  bool _isLoadingDinas = false;
  bool _isLoadingDesa = false;

  final List<String> _genders = ['Laki-laki', 'Perempuan'];
  final List<String> _jobs = ['Masyarakat Umum', 'ASN / PNS'];

  bool get _showDinas => _selectedJob == 'ASN / PNS';

  @override
  void initState() {
    super.initState();
    _loadDinasData();
    _loadDesaData();
  }

  Future<void> _loadDinasData() async {
    setState(() => _isLoadingDinas = true);
    final data = await DinasService().getDinasList();
    setState(() {
      _dinasData = data;
      _isLoadingDinas = false;
    });
  }

  Future<void> _loadDesaData() async {
    setState(() => _isLoadingDesa = true);
    final data = await DesaService().getAllDesa();
    setState(() {
      _desaData = data;
      _isLoadingDesa = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1B5E20),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tglLahirCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  bool _validateAndSave() {
    if (_namaCtrl.text.isEmpty) {
      _showSnackBar('Nama lengkap wajib diisi');
      return false;
    }
    if (_selectedGender == null) {
      _showSnackBar('Jenis kelamin wajib dipilih');
      return false;
    }
    if (_selectedDate == null) {
      _showSnackBar('Tanggal lahir wajib dipilih');
      return false;
    }
    if (_alamatCtrl.text.isEmpty) {
      _showSnackBar('Alamat wajib diisi');
      return false;
    }
    if (_selectedJob == null) {
      _showSnackBar('Pekerjaan wajib dipilih');
      return false;
    }
    if (_showDinas && _selectedDinasId == null) {
      _showSnackBar('Dinas wajib dipilih untuk ASN/PNS');
      return false;
    }
    if (_selectedDesaId == null) {
      _showSnackBar('Desa/Kelurahan wajib dipilih');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Column(
                  children: [
                    Image.asset('assets/images/logo-resik.png', height: 80),
                    const SizedBox(height: 10),
                    const Text(
                      'Daftar Akun',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const Text(
                      'Lengkapi Data Diri Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabel('Nama Lengkap'),
                          _buildTextField(controller: _namaCtrl, hint: 'Nama Lengkap'),
                          const SizedBox(height: 16),

                          _buildLabel('Jenis Kelamin'),
                          _buildDropdown(
                            items: _genders,
                            value: _selectedGender,
                            hint: 'Jenis Kelamin',
                            onChanged: (val) => setState(() => _selectedGender = val),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Tanggal Lahir'),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: _buildTextField(
                                controller: _tglLahirCtrl,
                                hint: 'Tanggal Lahir',
                                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF2E7D32), size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Alamat'),
                          _buildTextField(controller: _alamatCtrl, hint: 'Alamat', maxLines: 2),
                          const SizedBox(height: 16),

                          _buildLabel('Pekerjaan'),
                          _buildDropdown(
                            items: _jobs,
                            value: _selectedJob,
                            hint: 'Pekerjaan',
                            onChanged: (val) {
                              setState(() {
                                _selectedJob = val;
                                if (!_showDinas) _selectedDinasId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          if (_showDinas) ...[
                            _buildLabel('Dinas'),
                            _isLoadingDinas
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                                : _dinasData.isEmpty
                                    ? const Center(child: Text('Data dinas kosong', style: TextStyle(color: Colors.red)))
                                    : _buildDropdownDinas(),
                            const SizedBox(height: 16),
                          ],

                          _buildLabel('Desa/Kelurahan'),
                          _isLoadingDesa
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                              : _desaData.isEmpty
                                  ? const Center(child: Text('Data desa kosong', style: TextStyle(color: Colors.red)))
                                  : _buildDropdownDesa(),
                          const SizedBox(height: 16),

                          Center(
                            child: GestureDetector(
                              onTap: () {
                                if (_validateAndSave()) {
                                  Navigator.pushNamed(context, '/register-step2', arguments: {
                                    'nama': _namaCtrl.text,
                                    'gender': _selectedGender,
                                    'tglLahir': _selectedDate,
                                    'alamat': _alamatCtrl.text,
                                    'job': _selectedJob,
                                    'dinasId': _selectedDinasId,
                                    'desaId': _selectedDesaId,
                                  });
                                }
                              },
                              child: Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B5E20),
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFF1B5E20), fontFamily: 'Montserrat'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Montserrat'),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required List<String> items,
    required String? value,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Montserrat'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E7D32)),
        items: items.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(e, style: const TextStyle(fontFamily: 'Montserrat')),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownDinas() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDinasId,
        isDense: true,
        isExpanded: true,
        menuMaxHeight: 300,
        decoration: InputDecoration(
          hintText: 'Pilih Dinas',
          hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Montserrat'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E7D32)),
        items: _dinasData.map((item) {
          return DropdownMenuItem(
            value: item['id_dinas'].toString(),
            child: Text(
              item['nama_dinas'],
              style: const TextStyle(fontFamily: 'Montserrat'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedDinasId = val),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Dinas wajib dipilih';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownDesa() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDesaId,
        isDense: true,
        isExpanded: true,
        menuMaxHeight: 300,
        decoration: InputDecoration(
          hintText: 'Pilih Desa/Kelurahan',
          hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Montserrat'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E7D32)),
        items: _desaData.map((item) {
          return DropdownMenuItem(
            value: item['id_desa'].toString(),
            child: Text(
              '${item['nama_desa']} (${item['jenis']})',
              style: const TextStyle(fontFamily: 'Montserrat'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedDesaId = val),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Desa/Kelurahan wajib dipilih';
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _tglLahirCtrl.dispose();
    super.dispose();
  }
}