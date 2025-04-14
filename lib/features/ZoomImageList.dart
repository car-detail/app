import 'package:car_app/Common/Color.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../Common/CommonWidget.dart';

class ZoomableImageList extends StatefulWidget {
  final List<String> imageUrls;
  int currentIndex;
  Function()? funtion;

  ZoomableImageList(
      {super.key,
      required this.imageUrls,
      this.currentIndex = 0,
      this.funtion});

  @override
  _ZoomableImageListState createState() => _ZoomableImageListState();
}

class _ZoomableImageListState extends State<ZoomableImageList> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      _currentPage = widget.currentIndex;
    });
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            CommonWidget.gettopbar(
              "Attachments",
              context,
              /*icon: "send",
            funtion: widget.funtion != null
                ? widget.funtion
                : () {
                    CommonWidget.shareFile(context, widget.imageUrls);
                  }*/
            ),
            Expanded(
              child: Stack(
                children: [
                  PhotoViewGallery.builder(
                    itemCount: widget.imageUrls.length,
                    builder: (context, index) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: NetworkImage(widget.imageUrls[index]),
                        minScale: PhotoViewComputedScale.contained * 0.8,
                        maxScale: PhotoViewComputedScale.covered * 2,
                      );
                    },
                    scrollPhysics: const BouncingScrollPhysics(),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    pageController: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                  ),
                  if (widget.imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                  color: ColorClass.base_color,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                              child: IconButton(
                                color: Colors.white,
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  if (_currentPage > 0) {
                                    _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                              )),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                                color: ColorClass.base_color,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25))),
                            child: IconButton(
                              color: Colors.white,
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                if (_currentPage <
                                    widget.imageUrls.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          ],
        ));
  }

  void _shareImage() async {
    final currentImageIndex = _currentPage;
    final currentImageUrl = widget.imageUrls[currentImageIndex];
    // Download the image or use its URL directly to share
    // Share.share(currentImageUrl);
  }
}
