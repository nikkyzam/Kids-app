import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/database_helper.dart';
import '../../models/photo_memory.dart';
import '../../services/baby_book.dart';
import '../../services/photo_memory_service.dart';
import '../../services/photo_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/local_image.dart';

class MemoriesTimelineScreen extends StatefulWidget {
  final int profileId;

  const MemoriesTimelineScreen({super.key, required this.profileId});

  @override
  State<MemoriesTimelineScreen> createState() => _MemoriesTimelineScreenState();
}

class _MemoriesTimelineScreenState extends State<MemoriesTimelineScreen> {
  List<PhotoMemory> _photos = [];
  List<BabyBookEntry> _story = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await DatabaseHelper.instance.getPhotos(widget.profileId);
    photos.sort((a, b) => b.capturedAtDate.compareTo(a.capturedAtDate));
    final story = await BabyBook.load(widget.profileId);
    if (mounted) {
      setState(() {
        _photos = photos;
        _story = story;
        _loading = false;
      });
    }
  }

  /// A memory that belongs to nothing in particular — a first smile, a nap in
  /// a sunbeam. Everything else in the book hangs off an activity or a
  /// milestone, and plenty of what a parent wants to keep does neither.
  Future<void> _addStandaloneMemory() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final saved = await PhotoMemoryService.capture(
      context,
      profileId: widget.profileId,
      referenceType: BabyBook.standaloneReference,
      // The moment is its own occasion, so the date it happened is all the
      // reference it needs.
      referenceId: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      source: source,
    );
    if (saved == null || !mounted) return;
    await _loadPhotos();
  }

  Future<void> _deletePhoto(PhotoMemory photo) async {
    if (photo.id == null) return;
    await DatabaseHelper.instance.deletePhoto(photo.id!);
    // The file goes too, or deleting a memory would only hide it while it kept
    // taking up the parent's storage. PhotoStorage refuses paths outside its
    // own directory, so a row left over from an older build cannot reach into
    // the picker's cache or the user's library.
    await PhotoStorage.delete(photo.imagePath);
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memories'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Baby book'), Tab(text: 'Photos')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : _addStandaloneMemory,
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text('Add a memory'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _story.isEmpty
                      ? const _EmptyState(
                          icon: Icons.auto_stories_rounded,
                          title: 'The story starts here',
                          body: 'Tick a milestone, record a measurement or add '
                              'a photo, and it will all gather here in order.',
                        )
                      : _StoryBody(entries: _story),
                  _photos.isEmpty
                      ? const _EmptyState(
                          icon: Icons.camera_alt_rounded,
                          title: 'No photos yet',
                          body: 'Add a memory below, or tap the camera icon on '
                              'any completed activity or milestone.',
                        )
                      : _TimelineBody(
                          grouped: _groupedByMonth,
                          onDelete: _deletePhoto,
                        ),
                ],
              ),
      ),
    );
  }
}

/// The baby book: photos, milestones and measurements in one column, newest
/// first, grouped by month.
class _StoryBody extends StatelessWidget {
  final List<BabyBookEntry> entries;

  const _StoryBody({required this.entries});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<BabyBookEntry>>{};
    for (final entry in entries) {
      grouped
          .putIfAbsent(DateFormat('MMMM yyyy').format(entry.date), () => [])
          .add(entry);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final month in grouped.keys) ...[
          Padding(
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
          ...grouped[month]!.map((e) => _StoryTile(entry: e)),
        ],
      ],
    );
  }
}

class _StoryTile extends StatelessWidget {
  final BabyBookEntry entry;

  const _StoryTile({required this.entry});

  static const _icons = {
    BabyBookEntryKind.photo: Icons.photo_rounded,
    BabyBookEntryKind.milestone: Icons.emoji_events_rounded,
    BabyBookEntryKind.growth: Icons.straighten_rounded,
  };

  static const _colors = {
    BabyBookEntryKind.photo: AppTheme.primary,
    BabyBookEntryKind.milestone: AppTheme.success,
    BabyBookEntryKind.growth: AppTheme.secondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[entry.kind]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icons[entry.kind], size: 17, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE, d MMM').format(entry.date),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(entry.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              if (entry.note?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(entry.note!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.5)),
              ],
              if (entry.imagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image(
                      image: localImageProvider(entry.imagePath!),
                      fit: BoxFit.cover,
                      // A file the OS purged, or one lost with a restored
                      // backup, explains itself rather than throwing.
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.textMuted.withValues(alpha: 0.08),
                        alignment: Alignment.center,
                        child: const Text(
                          'This photo is no longer on this device',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _EmptyState(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
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
        content: const Text(
            'This photo will be permanently removed from your memories.'),
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
            Image(
              image: localImageProvider(photo.imagePath),
              fit: BoxFit.cover,
              // A photo file can go missing if it was removed outside the app
              // or the memory came from a restored backup, so say what
              // happened rather than showing a bare broken-image glyph.
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.primaryLight,
                padding: const EdgeInsets.all(8),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        color: AppTheme.textMuted, size: 28),
                    SizedBox(height: 6),
                    Text(
                      'Photo unavailable\non this device',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted, height: 1.3),
                    ),
                  ],
                ),
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
                    // The tag pill sizes to its label and overflowed the photo
                    // tile on narrow grids.
                    Flexible(
                        child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tagLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )),
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
    final formattedDate =
        DateFormat('MMMM d, yyyy').format(photo.capturedAtDate);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

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
              color: AppTheme.textMuted.withValues(alpha: 0.3),
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
                        child: Image(
                          image: localImageProvider(photo.imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primaryLight,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  color: AppTheme.textMuted, size: 48),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
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
