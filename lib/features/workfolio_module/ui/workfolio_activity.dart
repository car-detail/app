import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../../Models/image_module_data.dart';
import '../data_manager/workfolio_data_manager.dart';
import '../model/workfolio_post.dart';

/// Community "Workfolio" — an images-only feed where vendors and users post
/// wash/detailing results. Simple by design: no video, no comments, just
/// photos + likes, so it stays easy to use and quick to scroll.
class WorkfolioActivity extends StatefulWidget {
  const WorkfolioActivity({super.key});

  @override
  State<WorkfolioActivity> createState() => _WorkfolioActivityState();
}

class _WorkfolioActivityState extends State<WorkfolioActivity> {
  WorkfolioDataManager? _dataManager;
  String? _myUserId;

  final List<WorkfolioPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _dataManager = WorkfolioDataManager(prefs);
    _myUserId = prefs.getString(Constant.id);
    await _loadFeed(reset: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFeed({bool reset = false}) async {
    if (_dataManager == null) return;
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _hasMore = true;
      });
    }
    try {
      final response = await _dataManager!.getFeed(context, page: 1, limit: _limit);
      if (!mounted) return;
      final body = jsonDecode(response.body);
      final records = (body['data']?['records'] as List?) ?? [];
      final parsed = records.map((r) => WorkfolioPost.fromJson(r)).toList();
      setState(() {
        _posts
          ..clear()
          ..addAll(parsed);
        _loading = false;
        _hasMore = parsed.length == _limit;
        _page = 1;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _dataManager == null) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final response = await _dataManager!.getFeed(context, page: nextPage, limit: _limit);
      if (!mounted) return;
      final body = jsonDecode(response.body);
      final records = (body['data']?['records'] as List?) ?? [];
      final parsed = records.map((r) => WorkfolioPost.fromJson(r)).toList();
      setState(() {
        _posts.addAll(parsed);
        _page = nextPage;
        _hasMore = parsed.length == _limit;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleLike(WorkfolioPost post, int index) async {
    if (_dataManager == null || _myUserId == null) return;
    final wasLiked = post.likedBy.contains(_myUserId);
    setState(() {
      final updatedLikedBy = List<String>.from(post.likedBy);
      if (wasLiked) {
        updatedLikedBy.remove(_myUserId);
      } else {
        updatedLikedBy.add(_myUserId!);
      }
      _posts[index] = WorkfolioPost(
        id: post.id,
        image: post.image,
        caption: post.caption,
        authorId: post.authorId,
        authorName: post.authorName,
        authorImage: post.authorImage,
        authorRole: post.authorRole,
        vendorId: post.vendorId,
        vendorName: post.vendorName,
        vendorImage: post.vendorImage,
        likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
        likedBy: updatedLikedBy,
        createdAt: post.createdAt,
      );
    });
    try {
      await _dataManager!.toggleLike(context, post.id);
    } catch (_) {
      // silently keep optimistic state — non-critical
    }
  }

  Future<void> _openCreateSheet() async {
    if (!mounted) return;
    File? pickedFile;
    final captionController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool posting = false;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Share your work 🚗✨",
                      style: TextStyle(fontFamily: "Pop700", fontSize: 18, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {
                        BaseActivity.showFilePicker(sheetContext, (files) {
                          if (files != null && files.isNotEmpty) {
                            setSheetState(() => pickedFile = files.first);
                          }
                        }, allowMultipleImage: false);
                      },
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [ColorClass.base_color, ColorClass.start_color],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: pickedFile != null
                            ? Image.file(pickedFile!, fit: BoxFit.cover)
                            : const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 34),
                                    SizedBox(height: 8),
                                    Text("Tap to choose a photo",
                                        style: TextStyle(color: Colors.white, fontFamily: "Pop500", fontSize: 13)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: captionController,
                      maxLength: 140,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Add a caption (optional)",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (pickedFile == null || posting)
                            ? null
                            : () async {
                                setSheetState(() => posting = true);
                                final ok = await _submitPost(pickedFile!, captionController.text.trim());
                                if (ok && sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                } else {
                                  setSheetState(() => posting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorClass.base_color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: posting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text("Post", style: TextStyle(fontFamily: "Pop600", fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _submitPost(File file, String caption) async {
    if (_dataManager == null) return false;
    try {
      final uploadResponse = await _dataManager!.uploadImage(context, file);
      if (uploadResponse.statusCode != 200) {
        if (mounted) CommonWidget.errorShowSnackBarFor(context, "Couldn't upload image. Try again.");
        return false;
      }
      final imageData = ImageModuleData.fromJson(jsonDecode(uploadResponse.body));
      final url = imageData.data?.url;
      if (url == null || url.isEmpty) {
        if (mounted) CommonWidget.errorShowSnackBarFor(context, "Couldn't upload image. Try again.");
        return false;
      }

      final createResponse = await _dataManager!.createPost(context, imageUrl: url, caption: caption);
      if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
        if (mounted) await _loadFeed(reset: true);
        return true;
      }
      if (mounted) CommonWidget.errorShowSnackBarFor(context, "Couldn't create post. Try again.");
      return false;
    } catch (e) {
      if (mounted) CommonWidget.errorShowSnackBarFor(context, "Something went wrong. Try again.");
      return false;
    }
  }

  void _openPost(WorkfolioPost post, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WorkfolioPostViewer(
          post: post,
          isMine: post.authorId == _myUserId,
          onLike: () => _toggleLike(post, index),
          onDelete: _dataManager == null
              ? null
              : () async {
                  await _dataManager!.deletePost(context, post.id);
                  if (mounted) {
                    setState(() => _posts.removeWhere((p) => p.id == post.id));
                  }
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F9),
      appBar: AppBar(
        backgroundColor: ColorClass.base_color,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Feed", style: TextStyle(color: Colors.white, fontFamily: "Pop600", fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        backgroundColor: ColorClass.base_color,
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text("Post", style: TextStyle(color: Colors.white, fontFamily: "Pop600")),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadFeed(reset: true),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _posts.length + (_hasMore ? 1 : 0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      if (index >= _posts.length) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      final post = _posts[index];
                      return _WorkfolioTile(
                        post: post,
                        likedByMe: _myUserId != null && post.likedBy.contains(_myUserId),
                        onTap: () => _openPost(post, index),
                        onLike: () => _toggleLike(post, index),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_back_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 14),
            const Text(
              "No posts yet",
              style: TextStyle(fontFamily: "Pop600", fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              "Show off your best work — share a wash photo ✨",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "Pop400", fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkfolioTile extends StatelessWidget {
  final WorkfolioPost post;
  final bool likedByMe;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _WorkfolioTile({
    required this.post,
    required this.likedByMe,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.image,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: Colors.grey[200]);
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 22, 10, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontFamily: "Pop600", fontSize: 11),
                      ),
                    ),
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: likedByMe ? Colors.redAccent : Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "${post.likeCount}",
                            style: const TextStyle(color: Colors.white, fontFamily: "Pop500", fontSize: 11),
                          ),
                        ],
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

class _WorkfolioPostViewer extends StatefulWidget {
  final WorkfolioPost post;
  final bool isMine;
  final VoidCallback onLike;
  final Future<void> Function()? onDelete;

  const _WorkfolioPostViewer({
    required this.post,
    required this.isMine,
    required this.onLike,
    required this.onDelete,
  });

  @override
  State<_WorkfolioPostViewer> createState() => _WorkfolioPostViewerState();
}

class _WorkfolioPostViewerState extends State<_WorkfolioPostViewer> {
  late bool _liked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _liked = false;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: widget.isMine && widget.onDelete != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  onPressed: () async {
                    await widget.onDelete!();
                    if (mounted) Navigator.of(context).pop();
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                child: Image.network(post.image, fit: BoxFit.contain, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        backgroundImage: post.authorImage.isNotEmpty ? NetworkImage(post.authorImage) : null,
                        child: post.authorImage.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          post.vendorName ?? post.authorName,
                          style: const TextStyle(color: Colors.white, fontFamily: "Pop600", fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _liked = !_liked;
                            _likeCount += _liked ? 1 : -1;
                          });
                          widget.onLike();
                        },
                        child: Row(
                          children: [
                            Icon(
                              _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _liked ? Colors.redAccent : Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text("$_likeCount", style: const TextStyle(color: Colors.white, fontFamily: "Pop500")),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.caption,
                      style: const TextStyle(color: Colors.white70, fontFamily: "Pop400", fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
