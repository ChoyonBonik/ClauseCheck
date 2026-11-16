import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'paywall_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _remainingScans = 2;
  bool _isPremium = false;
  bool _isLoading = false;
  String _loadingMessage = 'Analyzing contract...';
  String _selectedCategory = 'Apartment Lease';

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Apartment Lease', 'icon': Icons.home_work_outlined, 'id': 'lease'},
    {'title': 'Freelance SOW', 'icon': Icons.laptop_chromebook, 'id': 'freelance'},
    {'title': 'Employment', 'icon': Icons.badge_outlined, 'id': 'employment'},
    {'title': 'Terms & General', 'icon': Icons.description_outlined, 'id': 'general'},
  ];

  @override
  void initState() {
    super.initState();
    _refreshLimits();
  }

  Future<void> _refreshLimits() async {
    final scans = await StorageService.getRemainingFreeScans();
    final premium = await StorageService.isPremium();
    setState(() {
      _remainingScans = scans;
      _isPremium = premium;
    });
  }

  Future<void> _checkAndProceed(Future<void> Function() scanAction) async {
    final canScan = await StorageService.canPerformScan();
    if (!canScan) {
      if (!mounted) return;
      final unlocked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      if (unlocked == true) {
        await _refreshLimits();
      }
      return;
    }
    await scanAction();
  }

  Future<void> _pickFile() async {
    await _checkAndProceed(() async {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (file != null && file.path != null) {
        _runAnalysis(filePath: file.path!);
      }
    });
  }

  Future<void> _capturePhoto() async {
    await _checkAndProceed(() async {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        _runAnalysis(filePath: photo.path);
      }
    });
  }

  Future<void> _pasteText() async {
    await _checkAndProceed(() async {
      final textController = TextEditingController();
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF161F30),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste Contract / Clause Text',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 8,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste terms, lease clause, or SOW here...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Analyze Clauses', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true && textController.text.trim().isNotEmpty) {
        _runAnalysis(contractText: textController.text.trim());
      }
    });
  }

  Future<void> _runAnalysis({String? filePath, String? contractText}) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Consulting Gemini 1.5 Pro...';
    });

    try {
      final analysis = await ApiService.analyzeContract(
        filePath: filePath,
        contractText: contractText,
        category: _selectedCategory,
      );

      await StorageService.decrementScan();
      await _refreshLimits();

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(result: analysis)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Colors.indigoAccent),
            const SizedBox(width: 8),
            const Text('AI Contract Guard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
              _refreshLimits();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isPremium ? Colors.amber.withValues(alpha: 0.2) : Colors.indigoAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isPremium ? Colors.amber : Colors.indigoAccent),
              ),
              child: Row(
                children: [
                  Icon(_isPremium ? Icons.star_rounded : Icons.bolt_rounded,
                      size: 16, color: _isPremium ? Colors.amber : Colors.indigoAccent),
                  const SizedBox(width: 4),
                  Text(
                    _isPremium ? 'PRO PASS' : '$_remainingScans Free',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isPremium ? Colors.amber : Colors.indigoAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.indigoAccent),
                  const SizedBox(height: 24),
                  Text(_loadingMessage, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Scanning clauses and checking liabilities...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Instant Contract Protection', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text(
                          'Detect predatory terms, hidden renewal traps, and unfair penalty fees before signing.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Selector
                  const Text('Select Document Focus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) {
                        final cat = _categories[i];
                        final isSelected = _selectedCategory == cat['title'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat['title']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigoAccent : const Color(0xFF161F30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
                            ),
                            child: Row(
                              children: [
                                Icon(cat['icon'], size: 16, color: isSelected ? Colors.white : Colors.white70),
                                const SizedBox(width: 8),
                                Text(cat['title'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Upload Methods
                  const Text('Choose Input Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 14),

                  _buildActionCard(
                    icon: Icons.upload_file_rounded,
                    title: 'Upload PDF / Document',
                    subtitle: 'Supports multi-page contracts, leases & TOS',
                    color: Colors.indigoAccent,
                    onTap: _pickFile,
                  ),
                  const SizedBox(height: 12),

                  _buildActionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Snap Photo of Paper Contract',
                    subtitle: 'Multimodal AI reads physical pages & fine print',
                    color: Colors.purpleAccent,
                    onTap: _capturePhoto,
                  ),
                  const SizedBox(height: 12),

                  _buildActionCard(
                    icon: Icons.paste_rounded,
                    title: 'Paste Text / Clause',
                    subtitle: 'Analyze specific paragraphs or email agreements',
                    color: Colors.tealAccent,
                    onTap: _pasteText,
                  ),

                  const SizedBox(height: 30),

                  // Privacy Notice
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_outline, color: Colors.white38, size: 14),
                        SizedBox(width: 6),
                        Text('Your documents are processed securely & never shared', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF161F30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
