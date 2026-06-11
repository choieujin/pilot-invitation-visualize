import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/mockup_style.dart';
import '../services/mockup_exporter.dart';
import '../services/pdf_rasterizer.dart';
import '../widgets/mockup_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialPages, this.initialFileName});

  /// 데모/테스트에서 업로드 단계를 건너뛰고 바로 편집 화면을 띄우기 위한 주입용.
  final List<RenderedPage>? initialPages;
  final String? initialFileName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<RenderedPage> _pages = [];
  int _selectedPage = 0;
  MockupStyle _selectedStyle = kDefaultStyles.first;
  bool _loading = false;
  bool _exporting = false;
  String? _error;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    if (widget.initialPages != null) {
      _pages = widget.initialPages!;
      _fileName = widget.initialFileName;
    }
  }

  Future<void> _pickPdf() async {
    setState(() => _error = null);
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = '파일을 읽을 수 없어요. 다시 시도해 주세요.');
      return;
    }
    await _render(bytes, file.name);
  }

  Future<void> _render(Uint8List bytes, String name) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pages = await PdfRasterizer.render(bytes);
      if (pages.isEmpty) {
        setState(() => _error = '페이지를 찾을 수 없는 PDF예요.');
        return;
      }
      setState(() {
        _pages = pages;
        _selectedPage = 0;
        _fileName = name;
      });
    } catch (e) {
      setState(() => _error = 'PDF를 처리하는 중 문제가 생겼어요: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    if (_pages.isEmpty) return;
    setState(() => _exporting = true);
    try {
      await MockupExporter.exportPng(
        _pages[_selectedPage].image,
        _selectedStyle,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _reset() {
    setState(() {
      _pages = [];
      _selectedPage = 0;
      _fileName = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          '청첩장 실물 미리보기',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_pages.isNotEmpty)
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('새 PDF'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const _LoadingView()
            : _pages.isEmpty
                ? _UploadView(onPick: _pickPdf, error: _error)
                : _EditorView(
                    pages: _pages,
                    selectedPage: _selectedPage,
                    selectedStyle: _selectedStyle,
                    fileName: _fileName,
                    exporting: _exporting,
                    onSelectPage: (i) => setState(() => _selectedPage = i),
                    onSelectStyle: (s) => setState(() => _selectedStyle = s),
                    onExport: _export,
                  ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('청첩장을 렌더링하고 있어요…'),
        ],
      ),
    );
  }
}

class _UploadView extends StatelessWidget {
  const _UploadView({required this.onPick, this.error});

  final VoidCallback onPick;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drafts_outlined,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                '청첩장 시안 PDF를 올려주세요',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '업로드하면 인쇄된 카드가 실제로 어떻게 보일지\n여러 연출로 미리 만들어 드려요.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file),
                label: const Text('PDF 선택'),
              ),
              if (error != null) ...[
                const SizedBox(height: 20),
                Text(
                  error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView({
    required this.pages,
    required this.selectedPage,
    required this.selectedStyle,
    required this.fileName,
    required this.exporting,
    required this.onSelectPage,
    required this.onSelectStyle,
    required this.onExport,
  });

  final List<RenderedPage> pages;
  final int selectedPage;
  final MockupStyle selectedStyle;
  final String? fileName;
  final bool exporting;
  final ValueChanged<int> onSelectPage;
  final ValueChanged<MockupStyle> onSelectStyle;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final page = pages[selectedPage];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 820;
        final preview = _Preview(
          page: page,
          style: selectedStyle,
          fileName: fileName,
          exporting: exporting,
          onExport: onExport,
        );
        final controls = _Controls(
          pages: pages,
          selectedPage: selectedPage,
          selectedStyle: selectedStyle,
          onSelectPage: onSelectPage,
          onSelectStyle: onSelectStyle,
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: preview),
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: controls,
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 420, child: preview),
              Padding(
                padding: const EdgeInsets.all(20),
                child: controls,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.page,
    required this.style,
    required this.fileName,
    required this.exporting,
    required this.onExport,
  });

  final RenderedPage page;
  final MockupStyle style;
  final String? fileName;
  final bool exporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: MockupView(page: page.image, style: style),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '${style.name} · ${style.description}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: exporting ? null : onExport,
                icon: exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(exporting ? '저장 중…' : '이미지 저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.pages,
    required this.selectedPage,
    required this.selectedStyle,
    required this.onSelectPage,
    required this.onSelectStyle,
  });

  final List<RenderedPage> pages;
  final int selectedPage;
  final MockupStyle selectedStyle;
  final ValueChanged<int> onSelectPage;
  final ValueChanged<MockupStyle> onSelectStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pages.length > 1) ...[
          Text('페이지', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final selected = i == selectedPage;
                return GestureDetector(
                  onTap: () => onSelectPage(i),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RawImage(
                      image: pages[i].image,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text('연출 스타일', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        ...kDefaultStyles.map((style) {
          final selected = style.id == selectedStyle.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelectStyle(style),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56 * (1 / kSceneAspect),
                        child: MockupView(
                          page: pages[selectedPage].image,
                          style: style,
                          borderRadius: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.name,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            style.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle,
                          color: theme.colorScheme.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
