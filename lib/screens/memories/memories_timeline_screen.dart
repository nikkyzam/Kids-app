import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../models/photo_memory.dart';
import '../../theme/app_theme.dart';

class MemoriesTimelineScreen extends StatefulWidget {
  final int profileId;

  const MemoriesTimelineScreen({super.key, required this.profileId});

  @override
  State<MemoriesTimelineScreen> createState() => _MemoriesTimelineScreenState();
}

class _MemoriesTimelineScreenState extends State<MemoriesTimelineScreen> {
  List<PhotoMemory> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await DatabaseHelper.instance.getPhotos(widget.profileId);
    photos.sort((a, b) => b.capturedAtDate.compareTo(a.capturedAtDate));
    if (mounted) {
      setState(() {
        _photos = photos;
        _loading = false;
      });
    }
  }

  Future<void> _deletePhoto(PhotoMemory photo) async {
    if (photo.id == null) return;
    await DatabaseHelper.instance.deletePhoto(photo.id!);
    await _loadPhotos();
  }

  Map<String, List<PhotoMemory>> get _groupedByMonth {
    final grouped = <String, List<PhotoMemory>>{};
    for (final photo in _photos) {
      final key = DateFormat('MMMM yyyy').format(photo.capturedAtDate);
      grouped.putIfAbsent(key, () => []).add(photo);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Memories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? _EmptyState()
              : _TimelineBody(
                  grouped: _groupedByMonth,
                  onDelete: _deletePhoto,
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_rounded, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No memories yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the camera icon on any completed activity or milestone to add a photo memory',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineBody extends StatelessWidget {
  final Map<String, List<PhotoMemory>> grouped;
  final Future<void> Function(PhotoMemory) onDelete;

  const _TimelineBody({required this.grouped, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final months = grouped.keys.toList();

    return CustomScrollView(
      slivers: [
        for (final month in months) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                month.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final photo = grouped[month]![index];
                  return _MemoryCard(photo: photo, onDelete: onDelete);
                },
                childCount: grouped[month]!.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final PhotoMemory photo;
  final Future<void> Function(PhotoMemory) onDelete;

  const _MemoryCard({required this.photo, required this.onDelete});

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemoryDetailSheet(
        photo: photo,
        onDelete: () async {
          Navigator.of(context).pop();
          await onDelete(photo);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete memory?'),
        content: const Text('This photo will be permanently removed from your memories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete(photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActivity = photo.referenceType == 'activity';
    final tagColor = isActivity ? AppTheme.primary : AppTheme.secondary;
    final tagLabel = isActivity ? 'Activity' : 'Milestone';
    final dateLabel = DateFormat('MMM d').format(photo.capturedAtDate);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => _openDetail(context),
        onLongPress: () => _confirmDelete(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.primaryLight,
                child: const Icon(Icons.broken_image_rounded, color: AppTheme.textMuted, size: 36),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tagLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryDetailSheet extends StatelessWidget {
  final PhotoMemory photo;
  final VoidCallback onDelete;

  const _MemoryDetailSheet({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isActivity = photo.referenceType == 'activity';
    final tagColor = isActivity ? AppTheme.primary : AppTheme.secondary;
    final tagLabel = isActivity ? 'Activity' : 'Milestone';
    final formattedDate = DateFormat('MMMM d, yyyy').format(photo.capturedAtDate);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.file(
                          File(photo.imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primaryLight,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tagLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tagColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (photo.caption != null && photo.caption!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        photo.caption!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
                    child: OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
