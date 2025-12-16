import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../timeline/services/timeline_data_service.dart';
import '../../timeline/models/timeline_state.dart';
import '../../../shared/models/timeline_event.dart';
import '../../timeline/models/river_flow_models.dart';

/// Enhanced Dashboard Screen with person switcher and interactive life wheel
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedPersonId;
  String? _selectedCategory;
  
  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineDataProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1420),
        title: const Text('Life Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(timelineDataProvider),
          ),
        ],
      ),
      body: timelineState.when(
        data: (state) => _buildDashboard(context, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
  
  Widget _buildDashboard(BuildContext context, TimelineState state) {
    if (state.allEvents.isEmpty) {
      return _buildEmptyState();
    }
    
    // Get all participants
    final allParticipants = state.allEvents.allParticipantIds.toList()..sort();
    
    // Default to first person if none selected
    _selectedPersonId ??= allParticipants.isNotEmpty ? allParticipants.first : null;
    
    // Filter events for selected person (or all if none)
    final events = _selectedPersonId == null 
        ? state.allEvents
        : state.allEvents.where((e) => 
            e.ownerId == _selectedPersonId || 
            e.participantIds.contains(_selectedPersonId)
          ).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Person Switcher
          _buildPersonSwitcher(allParticipants),
          const SizedBox(height: 20),
          
          // Stats Grid
          _buildStatsGrid(events, state.allEvents),
          const SizedBox(height: 24),
          
          // Life Wheel
          _buildLifeWheelSection(events),
          const SizedBox(height: 24),
          
          // Activity Timeline
          _buildActivityTimeline(events),
          const SizedBox(height: 24),
          
          // Shared Moments
          _buildSharedMoments(state.allEvents),
        ],
      ),
    );
  }
  
  Widget _buildPersonSwitcher(List<String> participants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viewing',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: participants.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildPersonChip(null, 'All', Colors.grey);
              }
              final personId = participants[index - 1];
              final color = RiverFlowColors.getColorForPerson(personId, index - 1);
              return _buildPersonChip(personId, _formatName(personId), color);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPersonChip(String? personId, String name, Color color) {
    final isSelected = _selectedPersonId == personId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPersonId = personId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsGrid(List<TimelineEvent> events, List<TimelineEvent> allEvents) {
    final yearsSpan = events.isEmpty ? 0 : 
        events.map((e) => e.timestamp.year).reduce(math.max) - 
        events.map((e) => e.timestamp.year).reduce(math.min) + 1;
    
    // Count special stats
    int births = 0, houses = 0, milestones = 0, photos = 0, travels = 0;
    for (final e in events) {
      final tagsLower = e.tags.map((t) => t.toLowerCase()).toList();
      if (tagsLower.contains('birth')) births++;
      if (tagsLower.contains('property') || tagsLower.contains('house')) houses++;
      if (e.eventType == 'milestone') milestones++;
      if (e.eventType == 'photo' || e.eventType == 'photo_burst') photos++;
      if (tagsLower.contains('travel') || tagsLower.contains('holiday')) travels++;
    }
    
    // Shared events count
    final sharedEvents = allEvents.where((e) => e.participantIds.isNotEmpty).length;
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard('Events', events.length.toString(), Icons.event, Colors.blue),
        _buildStatCard('Years', yearsSpan.toString(), Icons.calendar_today, Colors.purple),
        _buildStatCard('Milestones', milestones.toString(), Icons.star, Colors.amber),
        _buildStatCard('Photos', photos.toString(), Icons.photo_camera, Colors.green),
        _buildStatCard('Travels', travels.toString(), Icons.flight, Colors.cyan),
        _buildStatCard('Births', births.toString(), Icons.child_care, Colors.pink),
        _buildStatCard('Properties', houses.toString(), Icons.home, Colors.orange),
        _buildStatCard('Shared', sharedEvents.toString(), Icons.people, Colors.teal),
      ],
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLifeWheelSection(List<TimelineEvent> events) {
    // Aggregate by tags
    final categories = <String, int>{};
    for (final e in events) {
      for (final tag in e.tags) {
        categories[tag] = (categories[tag] ?? 0) + 1;
      }
    }
    
    // Sort by count and take top 8
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(8).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Life Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_selectedCategory != null)
              TextButton.icon(
                onPressed: () => setState(() => _selectedCategory = null),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Life Wheel with exploding segments
        Center(
          child: GestureDetector(
            onTap: () => _showLifeWheelDialog(topCategories, events.length),
            child: SizedBox(
              height: 250,
              width: 250,
              child: CustomPaint(
                painter: LifeWheelPainter(
                  categories: topCategories,
                  total: events.length,
                  selectedCategory: _selectedCategory,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        events.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Events',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Category chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: topCategories.asMap().entries.map((entry) {
            final idx = entry.key;
            final cat = entry.value;
            final isSelected = _selectedCategory == cat.key;
            final color = _getCategoryColor(idx);
            
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCategory = isSelected ? null : cat.key;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.4) : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${cat.key} (${cat.value})',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  void _showLifeWheelDialog(List<MapEntry<String, int>> categories, int total) {
    showDialog(
      context: context,
      builder: (context) => LifeWheelDialog(
        categories: categories,
        total: total,
        selectedCategory: _selectedCategory,
        onCategorySelected: (cat) {
          Navigator.pop(context);
          setState(() => _selectedCategory = cat);
        },
      ),
    );
  }
  
  Widget _buildActivityTimeline(List<TimelineEvent> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    
    // Group by year
    final yearCounts = <int, int>{};
    for (final e in events) {
      yearCounts[e.timestamp.year] = (yearCounts[e.timestamp.year] ?? 0) + 1;
    }
    
    final years = yearCounts.keys.toList()..sort();
    final maxCount = yearCounts.values.reduce(math.max);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Over Time',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: years.map((year) {
              final count = yearCounts[year]!;
              final height = 20 + (count / maxCount) * 50;
              final intensity = count / maxCount;
              
              return Expanded(
                child: Tooltip(
                  message: '$year: $count events',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.blue.withOpacity(0.3 + intensity * 0.5),
                          Colors.purple.withOpacity(0.3 + intensity * 0.5),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      boxShadow: intensity > 0.7 ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              years.first.toString(),
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
            ),
            Text(
              years.last.toString(),
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSharedMoments(List<TimelineEvent> allEvents) {
    final sharedEvents = allEvents.where((e) => e.participantIds.length >= 2).toList()
      ..sort((a, b) => b.participantIds.length.compareTo(a.participantIds.length));
    
    if (sharedEvents.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Shared Moments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${sharedEvents.length}',
                style: const TextStyle(color: Colors.teal, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sharedEvents.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final event = sharedEvents[index];
              return _buildSharedMomentCard(event);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSharedMomentCard(TimelineEvent event) {
    final hasPhoto = event.assets.isNotEmpty;
    
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPhoto ? Icons.photo : Icons.event,
                color: Colors.teal,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.title ?? 'Shared Event',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${event.participantIds.length + 1} people',
            style: TextStyle(
              color: Colors.teal.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
          Text(
            '${event.timestamp.year}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No events yet',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            'Add events to see your life dashboard',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
  
  String _formatName(String personId) {
    return personId
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
  
  Color _getCategoryColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}

/// Custom painter for the Life Wheel with exploding segments
class LifeWheelPainter extends CustomPainter {
  final List<MapEntry<String, int>> categories;
  final int total;
  final String? selectedCategory;
  
  LifeWheelPainter({
    required this.categories,
    required this.total,
    this.selectedCategory,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final innerRadius = radius * 0.55;
    
    double startAngle = -math.pi / 2;
    
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final sweepAngle = (cat.value / total) * 2 * math.pi;
      final color = _getColor(i);
      final isSelected = selectedCategory == cat.key;
      
      // Explode selected segment outward
      final explodeOffset = isSelected ? 12.0 : 0.0;
      final midAngle = startAngle + sweepAngle / 2;
      final explodeX = math.cos(midAngle) * explodeOffset;
      final explodeY = math.sin(midAngle) * explodeOffset;
      final segmentCenter = center + Offset(explodeX, explodeY);
      
      // Draw outer arc
      final outerPath = Path()
        ..moveTo(
          segmentCenter.dx + math.cos(startAngle) * innerRadius,
          segmentCenter.dy + math.sin(startAngle) * innerRadius,
        )
        ..lineTo(
          segmentCenter.dx + math.cos(startAngle) * radius,
          segmentCenter.dy + math.sin(startAngle) * radius,
        )
        ..arcTo(
          Rect.fromCircle(center: segmentCenter, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..lineTo(
          segmentCenter.dx + math.cos(startAngle + sweepAngle) * innerRadius,
          segmentCenter.dy + math.sin(startAngle + sweepAngle) * innerRadius,
        )
        ..arcTo(
          Rect.fromCircle(center: segmentCenter, radius: innerRadius),
          startAngle + sweepAngle,
          -sweepAngle,
          false,
        )
        ..close();
      
      final paint = Paint()
        ..color = isSelected ? color : color.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(outerPath, paint);
      
      // Draw segment border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0.5 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2 : 1;
      canvas.drawPath(outerPath, borderPaint);
      
      // Glow effect for selected
      if (isSelected) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(outerPath, glowPaint);
      }
      
      startAngle += sweepAngle;
    }
  }
  
  Color _getColor(int index) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF22C55E),
      Color(0xFFF97316),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
      Color(0xFFFACC15),
      Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }
  
  @override
  bool shouldRepaint(LifeWheelPainter oldDelegate) => 
      selectedCategory != oldDelegate.selectedCategory;
}

/// Dialog for expanded Life Wheel view
class LifeWheelDialog extends StatelessWidget {
  final List<MapEntry<String, int>> categories;
  final int total;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  
  const LifeWheelDialog({
    super.key,
    required this.categories,
    required this.total,
    this.selectedCategory,
    required this.onCategorySelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Life Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: CustomPaint(
                size: const Size(300, 300),
                painter: LifeWheelPainter(
                  categories: categories,
                  total: total,
                  selectedCategory: selectedCategory,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Events',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap a category to filter',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
