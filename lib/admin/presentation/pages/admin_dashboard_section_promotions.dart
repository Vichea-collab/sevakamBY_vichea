part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Future<void> _submitPromotionComposer() async {
    final title = _promotionTitleController.text.trim();
    final targetValue = _promotionTargetValueController.text.trim();
    if (title.length < 3 ||
        _promotionImageBytes == null ||
        targetValue.isEmpty) {
      _showError(
        const AdminApiException('Title, image, and target value are required.'),
      );
      return;
    }

    final targetRoles = <String>[
      if (_promotionComposerFinder) 'finder',
      if (_promotionComposerProvider) 'provider',
    ];
    if (targetRoles.isEmpty) {
      _showError(const AdminApiException('Select at least one audience role.'));
      return;
    }

    _setSectionState(() => _promotionComposerSaving = true);
    try {
      final extension = _fileExtensionFromName(_promotionImageName ?? '');
      final imageUrl = await FirebaseStorageService.uploadPromotionImage(
        _promotionImageBytes!,
        extension: extension,
      );
      if (imageUrl == null || imageUrl.isEmpty) {
        throw const AdminApiException(
          'Promotion image upload failed. Please try another image.',
        );
      }

      await _runAuthed(
        () => AdminDashboardState.createPromotion(
          placement: _promotionComposerPlacement,
          badgeLabel: _promotionBadgeController.text.trim(),
          title: title,
          description: '',
          imageUrl: imageUrl,
          ctaLabel: _promotionCtaController.text.trim(),
          targetType: _promotionComposerTargetType,
          targetValue: targetValue,
          targetRoles: targetRoles,
          query: _promotionQueryController.text.trim(),
          category: _promotionCategoryController.text.trim(),
          city: _promotionCityController.text.trim(),
          sortOrder:
              int.tryParse(_promotionSortOrderController.text.trim()) ?? 0,
          active: _promotionComposerActive,
          startAtIso: _promotionStartAtController.text.trim().isEmpty
              ? null
              : _promotionStartAtController.text.trim(),
          endAtIso: _promotionEndAtController.text.trim().isEmpty
              ? null
              : _promotionEndAtController.text.trim(),
        ),
      );

      _promotionBadgeController.text = 'Featured';
      _promotionTitleController.clear();
      _promotionCtaController.text = 'Explore';
      _promotionTargetValueController.clear();
      _promotionQueryController.clear();
      _promotionCategoryController.clear();
      _promotionCityController.clear();
      _promotionSortOrderController.text = '0';
      _promotionStartAtController.clear();
      _promotionEndAtController.clear();
      _promotionComposerPlacement = 'finder_home';
      _promotionComposerTargetType = 'search';
      _promotionComposerFinder = true;
      _promotionComposerProvider = false;
      _promotionComposerActive = true;
      _promotionImageBytes = null;
      _promotionImageName = null;

      await _loadPromotions(1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promotion published successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        _setSectionState(() => _promotionComposerSaving = false);
      }
    }
  }

  Future<void> _pickPromotionImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 1800,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      _setSectionState(() {
        _promotionImageBytes = bytes;
        _promotionImageName = file.name;
      });
    } catch (error) {
      _showError(error);
    }
  }

  void _clearPromotionImage() {
    _setSectionState(() {
      _promotionImageBytes = null;
      _promotionImageName = null;
    });
  }

  String _fileExtensionFromName(String fileName) {
    final cleanName = fileName.trim();
    if (cleanName.isEmpty || !cleanName.contains('.')) return 'jpg';
    final extension = cleanName.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
      case 'webp':
      case 'gif':
      case 'jpg':
      case 'jpeg':
        return extension == 'jpeg' ? 'jpg' : extension;
      default:
        return 'jpg';
    }
  }

  Future<void> _togglePromotionActive(AdminPromotionRow row) async {
    final nextActive = !row.active;
    try {
      await _runAuthed(
        () => AdminDashboardState.updatePromotionActive(
          promotionId: row.id,
          active: nextActive,
        ),
      );
      await _loadPromotions(1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextActive
                ? 'Promotion activated successfully.'
                : 'Promotion deactivated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Widget _buildPromotionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD8E4F6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110F172A),
                blurRadius: 20,
                spreadRadius: -12,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Home Promotion',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Publish curated finder-home ads and link them to providers, services, or search results.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _promotionComposerPlacement,
                      decoration: const InputDecoration(labelText: 'Placement'),
                      items: const [
                        DropdownMenuItem(
                          value: 'finder_home',
                          child: Text('Finder home'),
                        ),
                      ],
                      onChanged: (value) => _setSectionState(
                        () => _promotionComposerPlacement =
                            value ?? 'finder_home',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _promotionComposerTargetType,
                      decoration: const InputDecoration(
                        labelText: 'Target type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'search',
                          child: Text('Search'),
                        ),
                        DropdownMenuItem(
                          value: 'service',
                          child: Text('Service'),
                        ),
                        DropdownMenuItem(
                          value: 'category',
                          child: Text('Category'),
                        ),
                        DropdownMenuItem(
                          value: 'provider',
                          child: Text('Provider'),
                        ),
                        DropdownMenuItem(
                          value: 'post',
                          child: Text('Post list'),
                        ),
                        DropdownMenuItem(value: 'page', child: Text('Page')),
                      ],
                      onChanged: (value) => _setSectionState(
                        () => _promotionComposerTargetType = value ?? 'search',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _promotionBadgeController,
                      decoration: const InputDecoration(labelText: 'Badge'),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _promotionCtaController,
                      decoration: const InputDecoration(labelText: 'CTA label'),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _promotionSortOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sort order',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _promotionTitleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _promotionTargetValueController,
                      decoration: const InputDecoration(
                        labelText: 'Target value',
                        hintText:
                            'Provider UID, service name, category, or page key',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _promotionQueryController,
                      decoration: const InputDecoration(
                        labelText: 'Search query',
                        hintText: 'Optional search seed',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _promotionCategoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _promotionCityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'Optional city target',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _promotionStartAtController,
                      decoration: const InputDecoration(
                        labelText: 'Start at',
                        hintText: '2026-03-15',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _promotionEndAtController,
                      decoration: const InputDecoration(
                        labelText: 'End at',
                        hintText: '2026-04-15',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 520,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD8E4F6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Promotion image',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (_promotionImageBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _promotionImageBytes!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF2FF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (_promotionImageName ?? '').trim().isEmpty
                                          ? 'No image selected'
                                          : _promotionImageName!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Pick a local image to upload for this promotion banner.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: _promotionComposerSaving
                                              ? null
                                              : _pickPromotionImage,
                                          icon: const Icon(
                                            Icons.photo_library_outlined,
                                          ),
                                          label: Text(
                                            _promotionImageBytes == null
                                                ? 'Choose image'
                                                : 'Change image',
                                          ),
                                        ),
                                        if (_promotionImageBytes != null)
                                          TextButton(
                                            onPressed: _promotionComposerSaving
                                                ? null
                                                : _clearPromotionImage,
                                            child: const Text('Remove'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    selected: _promotionComposerFinder,
                    label: const Text('Finder'),
                    onSelected: (_) => _setSectionState(
                      () =>
                          _promotionComposerFinder = !_promotionComposerFinder,
                    ),
                  ),
                  FilterChip(
                    selected: _promotionComposerProvider,
                    label: const Text('Provider'),
                    onSelected: (_) => _setSectionState(
                      () => _promotionComposerProvider =
                          !_promotionComposerProvider,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Active'),
                      const SizedBox(width: 8),
                      Switch(
                        value: _promotionComposerActive,
                        onChanged: (value) =>
                            _setSectionState(() => _promotionComposerActive = value),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _promotionComposerSaving
                        ? null
                        : _submitPromotionComposer,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(
                      _promotionComposerSaving
                          ? 'Publishing...'
                          : 'Publish promotion',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AdminTableCard<AdminPromotionRow>(
          title: 'Home Promotions',
          subtitle:
              'Only active windowed promotions are shown in the finder home carousel.',
          loadingListenable: AdminDashboardState.loadingPromotions,
          rowsListenable: AdminDashboardState.promotions,
          paginationListenable: AdminDashboardState.promotionsPagination,
          onPageSelected: _loadPromotions,
          controls: [
            _DropdownFilter(
              label: 'Placement',
              value: _promotionPlacementFilter,
              options: const [
                _DropdownOption(value: 'finder_home', label: 'Finder home'),
              ],
              onChanged: (value) {
                _setSectionState(() => _promotionPlacementFilter = value);
                unawaited(_loadPromotions(1));
              },
            ),
            _DropdownFilter(
              label: 'Target',
              value: _promotionTargetTypeFilter,
              options: const [
                _DropdownOption(value: 'all', label: 'All targets'),
                _DropdownOption(value: 'search', label: 'Search'),
                _DropdownOption(value: 'service', label: 'Service'),
                _DropdownOption(value: 'category', label: 'Category'),
                _DropdownOption(value: 'provider', label: 'Provider'),
                _DropdownOption(value: 'post', label: 'Post list'),
                _DropdownOption(value: 'page', label: 'Page'),
              ],
              onChanged: (value) {
                _setSectionState(() => _promotionTargetTypeFilter = value);
                unawaited(_loadPromotions(1));
              },
            ),
            _DropdownFilter(
              label: 'Lifecycle',
              value: _promotionStatusFilter,
              options: const [
                _DropdownOption(value: 'all', label: 'All states'),
                _DropdownOption(value: 'active', label: 'Active'),
                _DropdownOption(value: 'scheduled', label: 'Scheduled'),
                _DropdownOption(value: 'expired', label: 'Expired'),
                _DropdownOption(value: 'inactive', label: 'Inactive'),
              ],
              onChanged: (value) {
                _setSectionState(() => _promotionStatusFilter = value);
                unawaited(_loadPromotions(1));
              },
            ),
          ],
          columns: const [
            'Badge',
            'Title',
            'Target',
            'Window',
            'Status',
            'Sort',
            'Action',
          ],
          emptyText: 'No promotions found for this page.',
          summaryBuilder: (items) {
            final active = items
                .where((item) => item.lifecycle.toLowerCase() == 'active')
                .length;
            final scheduled = items
                .where((item) => item.lifecycle.toLowerCase() == 'scheduled')
                .length;
            return [
              _MetricChipData(
                label: 'Page promotions',
                value: '${items.length}',
              ),
              _MetricChipData(
                label: 'Active',
                value: '$active',
                color: AppColors.success,
              ),
              _MetricChipData(
                label: 'Scheduled',
                value: '$scheduled',
                color: AppColors.warning,
              ),
            ];
          },
          filterRows: (items) {
            final query = _searchQuery.trim().toLowerCase();
            return items
                .where((item) {
                  final targetMatch =
                      _promotionTargetTypeFilter == 'all' ||
                      item.targetType.toLowerCase() ==
                          _promotionTargetTypeFilter;
                  if (!targetMatch) return false;
                  final lifecycleMatch =
                      _promotionStatusFilter == 'all' ||
                      item.lifecycle.toLowerCase() == _promotionStatusFilter;
                  if (!lifecycleMatch) return false;
                  if (query.isEmpty) return true;
                  final haystack =
                      '${item.badgeLabel} ${item.title} ${item.description} ${item.targetType} ${item.targetValue} ${item.query} ${item.category} ${item.city}'
                          .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);
          },
          rowCells: (item) {
            final targetSummary = [
              _prettyStatus(item.targetType),
              if (item.targetValue.isNotEmpty) item.targetValue,
            ].join(' • ');
            final windowText =
                '${_formatDateTime(item.startAt)} -> ${_formatDateTime(item.endAt)}';
            return [
              DataCell(_cellText(item.badgeLabel, width: 120)),
              DataCell(_cellText(item.title, width: 220)),
              DataCell(_cellText(targetSummary, width: 220)),
              DataCell(_cellText(windowText, width: 220)),
              DataCell(
                _Pill(
                  text: _prettyStatus(item.lifecycle),
                  color: _statusColor(item.lifecycle),
                ),
              ),
              DataCell(_cellText('${item.sortOrder}', width: 70)),
              DataCell(
                _actionMenu(
                  actions: [
                    _ActionMenuItem(
                      label: item.active ? 'Deactivate' : 'Activate',
                      onTap: () => _togglePromotionActive(item),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }
}
