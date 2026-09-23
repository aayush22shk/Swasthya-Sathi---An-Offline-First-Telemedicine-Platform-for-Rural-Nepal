import 'package:flutter/material.dart';
import '../../features/doctor_profile/view/doctor_detail_screen.dart';
import '../../services/doctor_service.dart';
import 'doctor_model.dart';

class DoctorHorizontalList extends StatefulWidget {
  final String title;
  final List<DoctorModel>? doctors;
  final VoidCallback? onViewAll;

  const DoctorHorizontalList({
    super.key,
    this.title = 'Available Specialists',
    this.doctors,
    this.onViewAll,
  });

  @override
  State<DoctorHorizontalList> createState() => _DoctorHorizontalListState();
}

class _DoctorHorizontalListState extends State<DoctorHorizontalList> {
  List<DoctorModel>? _loadedDoctors;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.doctors == null) {
      _fetchDoctors();
    }
  }

  @override
  void didUpdateWidget(covariant DoctorHorizontalList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.doctors != null) {
      setState(() => _loadedDoctors = null);
    }
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    final docs = await DoctorService().getDoctors();
    if (mounted) {
      setState(() {
        _loadedDoctors = docs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.doctors ?? _loadedDoctors ?? DoctorModel.sampleDoctors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onViewAll != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onViewAll,
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0072FF),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12.0),

        // Content
        if (_isLoading)
          const SizedBox(
            height: 230,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0072FF)),
            ),
          )
        else if (list.isEmpty)
          Container(
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No doctors available at this time.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final doc = list[index];
                return Container(
                  width: 170,
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.0),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorDetailScreen(doctor: doc),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor Image & Availability Stack
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(17.0),
                                  topRight: Radius.circular(17.0),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1.15,
                                  child: Image.network(
                                    doc.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.person,
                                          size: 40, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              ),

                              // Online / Available Badge Top-Left
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0, vertical: 3.0),
                                  decoration: BoxDecoration(
                                    color: doc.isAvailable
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF64748B),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        doc.isAvailable ? 'Online' : 'Offline',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Rating Badge Top-Right
                              if (doc.rating > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            size: 11, color: Color(0xFFFBBF24)),
                                        const SizedBox(width: 2),
                                        Text(
                                          doc.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Name & Specialty Text Details
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.name,
                                  style: const TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  doc.specialty,
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  doc.consultationFee,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0072FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
