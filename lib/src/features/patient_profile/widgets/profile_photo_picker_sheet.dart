import 'package:flutter/material.dart';

class ProfilePhotoPickerSheet extends StatefulWidget {
  final String? currentPhotoUrl;

  const ProfilePhotoPickerSheet({
    super.key,
    this.currentPhotoUrl,
  });

  /// Shows the picker sheet and returns:
  /// - `String` (the new image URL) if selected & saved
  /// - `""` (empty string) if the user chose to remove the picture
  /// - `null` if cancelled
  static Future<String?> show(BuildContext context, {String? currentPhotoUrl}) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfilePhotoPickerSheet(currentPhotoUrl: currentPhotoUrl),
    );
  }

  @override
  State<ProfilePhotoPickerSheet> createState() => _ProfilePhotoPickerSheetState();
}

class _ProfilePhotoPickerSheetState extends State<ProfilePhotoPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _urlController;
  String? _selectedUrl;

  // Curated avatar presets with reliable, high-quality portraits
  static const List<Map<String, String>> _avatarPresets = [
    {
      'name': 'Aayush (Male)',
      'url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80',
    },
    {
      'name': 'Pooja (Female)',
      'url': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&q=80',
    },
    {
      'name': 'Ramesh (Professional)',
      'url': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&q=80',
    },
    {
      'name': 'Sita (Professional)',
      'url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80',
    },
    {
      'name': 'Bikash (Doctor)',
      'url': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&q=80',
    },
    {
      'name': 'Anjali (Doctor)',
      'url': 'https://images.unsplash.com/photo-1594824813566-78a9c2794025?w=400&q=80',
    },
    {
      'name': 'Hari (Senior)',
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
    },
    {
      'name': 'Gita (Youth)',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedUrl = widget.currentPhotoUrl;
    _urlController = TextEditingController(text: widget.currentPhotoUrl ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onSelectPreset(String url) {
    setState(() {
      _selectedUrl = url;
      _urlController.text = url;
    });
  }

  void _onSave() {
    final finalUrl = _selectedUrl?.trim() ?? _urlController.text.trim();
    Navigator.of(context).pop(finalUrl);
  }

  void _onRemove() {
    Navigator.of(context).pop('');
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrentPhoto = widget.currentPhotoUrl != null &&
        widget.currentPhotoUrl!.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        top: 14.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44.0,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Title & Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Picture',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    'Choose an avatar or paste an image URL',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (hasCurrentPhoto)
                TextButton.icon(
                  onPressed: _onRemove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16.0, color: Color(0xFFEF4444)),
                  label: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18.0),

          // Preview Area
          Center(
            child: Stack(
              children: [
                Container(
                  width: 92.0,
                  height: 92.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0072FF), width: 3.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0072FF).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _selectedUrl != null && _selectedUrl!.isNotEmpty
                        ? Image.network(
                            _selectedUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person_rounded,
                              size: 48.0,
                              color: Color(0xFF0072FF),
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 48.0,
                            color: Color(0xFF0072FF),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0072FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Tabs
          Container(
            height: 40.0,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF0072FF),
                borderRadius: BorderRadius.circular(10.0),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
              tabs: const [
                Tab(text: 'Avatars'),
                Tab(text: 'Custom URL'),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          // Tab Content
          SizedBox(
            height: 175.0,
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Preset Avatars Grid
                GridView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  itemCount: _avatarPresets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final preset = _avatarPresets[index];
                    final url = preset['url']!;
                    final isSelected = _selectedUrl == url;

                    return GestureDetector(
                      onTap: () => _onSelectPreset(url),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52.0,
                            height: 52.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0072FF)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.5 : 1.2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.account_circle,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            preset['name']!.split(' ').first,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF0072FF)
                                  : const Color(0xFF475569),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 2. Custom URL Input
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Direct Image URL',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextFormField(
                        controller: _urlController,
                        onChanged: (val) {
                          setState(() {
                            _selectedUrl = val.trim().isNotEmpty ? val.trim() : null;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'https://example.com/my-photo.jpg',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13.0,
                          ),
                          prefixIcon: const Icon(
                            Icons.link_rounded,
                            color: Color(0xFF64748B),
                            size: 20.0,
                          ),
                          suffixIcon: _urlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18.0),
                                  onPressed: () {
                                    _urlController.clear();
                                    setState(() => _selectedUrl = null);
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                                color: Color(0xFF0072FF), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Supports JPG, PNG, WEBP, or public image hosting links.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0072FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Profile Picture',
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
