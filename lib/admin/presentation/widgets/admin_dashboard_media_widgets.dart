part of '../pages/admin_dashboard_page.dart';

class _BroadcastComposerCard extends StatelessWidget {
  final String type;
  final bool finderSelected;
  final bool providerSelected;
  final bool active;
  final bool saving;
  final TextEditingController titleController;
  final TextEditingController messageController;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onFinderToggle;
  final VoidCallback onProviderToggle;
  final ValueChanged<bool> onActiveChanged;
  final Future<void> Function() onSubmit;

  const _BroadcastComposerCard({
    required this.type,
    required this.finderSelected,
    required this.providerSelected,
    required this.active,
    required this.saving,
    required this.titleController,
    required this.messageController,
    required this.onTypeChanged,
    required this.onFinderToggle,
    required this.onProviderToggle,
    required this.onActiveChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isPromo = type == 'promotion';
    final audienceReady = finderSelected || providerSelected;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E3F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast Composer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Publish system messages and promotion campaigns to finder/provider notifications.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (saving)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (saving)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _composerControls(context),
                    const SizedBox(height: 10),
                    _composerInputs(context, isPromo),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 320, child: _composerControls(context)),
                  const SizedBox(width: 12),
                  Expanded(child: _composerInputs(context, isPromo)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ListenableBuilder(
              listenable: Listenable.merge([
                titleController,
                messageController,
              ]),
              builder: (context, _) {
                final hasValidTitle = titleController.text.trim().length >= 3;
                final hasValidMessage =
                    messageController.text.trim().length >= 3;
                final canSubmit =
                    !saving &&
                    audienceReady &&
                    hasValidTitle &&
                    hasValidMessage;
                return FilledButton.icon(
                  onPressed: canSubmit ? () => unawaited(onSubmit()) : null,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(saving ? 'Publishing...' : 'Publish broadcast'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _composerControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: type,
          isExpanded: true,
          dropdownColor: _adminFieldFillColor,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: _adminFieldDecoration(
            labelText: 'Broadcast type',
            dense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('System')),
            DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
          ],
          onChanged: (next) {
            if (next == null) return;
            onTypeChanged(next);
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Audience',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: finderSelected,
              label: const Text('Finder'),
              onSelected: (_) => onFinderToggle(),
              selectedColor: AppColors.primary.withValues(alpha: 0.16),
              side: BorderSide(
                color: finderSelected
                    ? AppColors.primary
                    : const Color(0xFFD3DDEF),
              ),
            ),
            FilterChip(
              selected: providerSelected,
              label: const Text('Provider'),
              onSelected: (_) => onProviderToggle(),
              selectedColor: AppColors.primary.withValues(alpha: 0.16),
              side: BorderSide(
                color: providerSelected
                    ? AppColors.primary
                    : const Color(0xFFD3DDEF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: active,
          title: const Text('Active now'),
          subtitle: const Text('Turn off to save as inactive'),
          onChanged: onActiveChanged,
        ),
      ],
    );
  }

  Widget _composerInputs(BuildContext context, bool isPromo) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: _adminFieldDecoration(
            labelText: 'Title',
            hintText: 'Short headline for notification',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: messageController,
          minLines: 3,
          maxLines: 4,
          decoration: _adminFieldDecoration(
            labelText: 'Message',
            hintText: 'Write announcement or promotion details',
          ),
        ),
        if (isPromo) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8E3F6)),
            ),
            child: Text(
              'Promotion broadcasts now publish title and message only. Promo codes have been removed from the system.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KycImagePanel extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _KycImagePanel({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    final uri = hasImage ? Uri.tryParse(imageUrl.trim()) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE6F7)),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? SafeImage(
                  source: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorBuilder: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Unable to load image preview',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      if (uri != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.platformDefault,
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Open original'),
                        ),
                      ],
                    ],
                  ),
                )
              : const Center(
                  child: Text(
                    'No image uploaded',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  imageUrl,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (uri != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await launchUrl(uri, mode: LaunchMode.platformDefault);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open'),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
