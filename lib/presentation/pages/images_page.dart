import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wsl_image.dart';
import '../providers/image_providers.dart';

/// Image management page — list, pull, delete
class ImagesPage extends ConsumerStatefulWidget {
  const ImagesPage({super.key});

  @override
  ConsumerState<ImagesPage> createState() => _ImagesPageState();
}

class _ImagesPageState extends ConsumerState<ImagesPage> {
  final _pullController = TextEditingController();

  @override
  void dispose() {
    _pullController.dispose();
    super.dispose();
  }

  // ======== Build ========

  @override
  Widget build(BuildContext context) {
    final imagesAsync = ref.watch(imageListProvider);
    final pullProgress = ref.watch(pullProgressProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Images')),
      content: _buildContent(context, imagesAsync, pullProgress),
    );
  }

  Widget _buildContent(BuildContext context, AsyncValue<List<WslImage>> images,
      AsyncValue<Map<String, dynamic>?> pullProgress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pull progress bar (visible only when active)
        _buildPullProgressBar(context, pullProgress),

        // Image list or state
        Expanded(child: images.when(
          loading: () => const Center(child: ProgressRing()),
          error: (error, _) => _buildError(context, error.toString()),
          data: (list) => list.isEmpty
              ? _buildEmpty(context)
              : _buildImageList(context, list),
        )),
      ],
    );
  }

  // ======== Pull Progress Bar ========

  Widget _buildPullProgressBar(
      BuildContext context, AsyncValue<Map<String, dynamic>?> progress) {
    final data = progress.valueOrNull;
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    final status = data['status'] as String? ?? '';
    final currentBytes = (data['currentBytes'] as num?)?.toInt() ?? 0;
    final totalBytes = (data['totalBytes'] as num?)?.toInt() ?? 0;
    final layerId = data['id'] as String? ?? '';

    // Hide when completed or errored (brief flash and gone)
    if (status == 'completed' || status == 'error') {
      return const SizedBox.shrink();
    }

    final progressValue = totalBytes > 0 ? currentBytes / totalBytes : 0.0;
    final layerInfo = layerId.length > 12
        ? '${layerId.substring(0, 12)}...'
        : layerId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: SizedBox(
        height: 60,
        child: Card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: ProgressRing(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$status${layerInfo.isNotEmpty ? ' — $layerInfo' : ''}',
                      style: FluentTheme.of(context).typography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ProgressBar(value: progressValue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== Error State ========

  Widget _buildError(BuildContext context, String message) {
    final theme = FluentTheme.of(context);
    return Center(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.status_error_full,
              size: 48,
              color: theme.typography.caption?.color,
            ),
            const SizedBox(height: 12),
            Text('Failed to load images',
                style: theme.typography.bodyStrong),
            const SizedBox(height: 4),
            Text(message,
                style: theme.typography.caption,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(imageListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ======== Empty State ========

  Widget _buildEmpty(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          const Icon(FluentIcons.box_checkmark_solid, size: 48),
          Text('No images yet', style: theme.typography.title),
          Text(
            'Pull your first container image to get started.',
            style: theme.typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () => _showPullDialog(context),
            child: const Text('Pull Image'),
          ),
        ],
      ),
    );
  }

  // ======== Image List ========

  Widget _buildImageList(BuildContext context, List<WslImage> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Command bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              FilledButton(
                onPressed: () => _showPullDialog(context),
                child: const Text('Pull Image'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () =>
                    ref.read(imageListProvider.notifier).refresh(),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),

        // Image cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: images.length,
            itemBuilder: (context, index) =>
                _buildImageCard(context, images[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(BuildContext context, WslImage image) {
    final theme = FluentTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.accentColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(FluentIcons.box_checkmark_solid,
                  size: 20, color: theme.accentColor),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(image.name,
                          style: theme.typography.bodyStrong),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.accentColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(image.tag,
                            style: theme.typography.caption?.copyWith(
                                color: theme.accentColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatBytes(image.sizeBytes)} — ${_formatTimeAgo(image.createdAt)}',
                    style: theme.typography.caption,
                  ),
                ],
              ),
            ),

            // Actions
            Tooltip(
              message: 'Delete image',
              child: IconButton(
                icon: const Icon(FluentIcons.delete, size: 18),
                onPressed: () => _confirmDelete(context, image),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======== Dialogs ========

  Future<void> _showPullDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Pull Image'),
        content: SizedBox(
          width: 360,
          child: InfoLabel(
            label: 'Image Reference',
            child: TextBox(
              placeholder: 'library/alpine:latest',
              controller: _pullController,
            ),
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, _pullController.text.trim()),
            child: const Text('Pull'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      _pullController.clear();
      ref.read(imageListProvider.notifier).pullImage(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WslImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Delete Image'),
        content: Text('Delete "${image.name}:${image.tag}"? '
            'Containers using this image will be affected.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          Button(
            onPressed: () => Navigator.pop(ctx, true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(Colors.red),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(imageListProvider.notifier).deleteImage(image.id);
    }
  }

  // ======== Formatters ========

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
