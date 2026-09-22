import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class InstagramGalleryPicker extends StatefulWidget {
  final int maxSelection;
  const InstagramGalleryPicker({super.key, this.maxSelection = 10});

  @override
  State<InstagramGalleryPicker> createState() => _InstagramGalleryPickerState();
}

class _InstagramGalleryPickerState extends State<InstagramGalleryPicker> {
  List<AssetEntity> _mediaList = [];
  List<AssetEntity> _selectedMedia = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common, // Images and Videos
      );
      if (paths.isNotEmpty) {
        final List<AssetEntity> media = await paths.first.getAssetListPaged(page: 0, size: 100);
        setState(() {
          _mediaList = media;
          _isLoading = false;
        });
      }
    } else {
      PhotoManager.openSetting();
    }
  }

  void _toggleSelection(AssetEntity entity) {
    setState(() {
      if (_selectedMedia.contains(entity)) {
        _selectedMedia.remove(entity);
      } else {
        if (_selectedMedia.length < widget.maxSelection) {
          _selectedMedia.add(entity);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You can only select up to ${widget.maxSelection} items.')),
          );
        }
      }
    });
  }

  Future<void> _done() async {
    List<File> files = [];
    for (var entity in _selectedMedia) {
      final file = await entity.file;
      if (file != null) files.add(file);
    }
    if (mounted) Navigator.pop(context, files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        actions: [
          if (_selectedMedia.isNotEmpty)
            TextButton(
              onPressed: _done,
              child: Text(
                'Next (${_selectedMedia.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _mediaList.length,
              itemBuilder: (context, index) {
                final entity = _mediaList[index];
                final isSelected = _selectedMedia.contains(entity);
                final selectedIndex = _selectedMedia.indexOf(entity) + 1;

                return GestureDetector(
                  onTap: () => _toggleSelection(entity),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: entity.thumbnailData,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
                        },
                      ),
                      if (entity.type == AssetType.video)
                        const Positioned(
                          bottom: 5,
                          right: 5,
                          child: Icon(Icons.videocam, color: Colors.white, size: 18),
                        ),
                      if (isSelected)
                        Container(
                          color: Colors.black.withOpacity(0.4),
                        ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black.withOpacity(0.3),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Text(
                                    '$selectedIndex',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
