import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:native_pdf_view/native_pdf_view.dart';

void main() => runApp(Quran());

class Quran extends StatefulWidget {
  @override
  _QuranState createState() => _QuranState();
}

class _QuranState extends State<Quran> {
  PDFDocument _document;
  static const List<double> _doubleTapScales = <double>[1.0, 1.1];
  int currentPage=569;
  bool isBookmarked = false;

  final pageController =
      PageController(initialPage: 569, viewportFraction: 1, keepPage: true);
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
   showBookmark(currentPage);
  }
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(primaryColor: Colors.white),
        home: Scaffold(
          // appBar: AppBar(title: Text('القرآن الكريم')),
          body: FutureBuilder<PDFDocument>(
            future: _getDocument(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SafeArea(
                  child: Stack(
                    children: <Widget>[
                      PDFView.builder(
                        onPageChanged: (page) {
                          currentPage = pageController.page.round().toInt();
                                  showBookmark(currentPage);
                          print(currentPage);
                        },
                        scrollDirection: Axis.horizontal,
                        document: snapshot.data,
                        controller: pageController,
                        builder: (PDFPageImage pageImage, bool isCurrentIndex) {
                          Widget image = ExtendedImage.memory(
                            pageImage.bytes,
                            fit: BoxFit.fitWidth,
                            // gesture not applied (minScale,maxScale,speed...)
                            mode: ExtendedImageMode.gesture,
                            initGestureConfigHandler: (_) => GestureConfig(
                              //minScale: 1,
                              // animationMinScale:1,
                              // maxScale: 1.1,
                              //animationMaxScale: 1,
                              speed: 1,
                              inertialSpeed: 100,
                              inPageView: true,
                              initialScale: 1,
                              cacheGesture: true,
                            ),
                            onDoubleTap: (ExtendedImageGestureState state) {
                              final pointerDownPosition =
                                  state.pointerDownPosition;
                              final begin = state.gestureDetails.totalScale;
                              double end;
                              if (begin == _doubleTapScales[0]) {
                                end = _doubleTapScales[1];
                              } else {
                                end = _doubleTapScales[0];
                              }
                              state.handleDoubleTap(
                                scale: end,
                                doubleTapPosition: pointerDownPosition,
                              );
                            },
                          );

                          if (isCurrentIndex) {
                            //currentPage=pageImage.pageNumber.round().toInt();
                            image = Hero(
                              tag: pageImage.pageNumber.toString(),
                              child: Container(child: image),
                              transitionOnUserGestures: true,
                            );
                          }
                          return image;
                        },
                      ),
                      isBookmarked
                          ? Align(
                              alignment: Alignment.topLeft,
                              child: Opacity(
                                opacity: 0.8,
                                child: Icon(
                                  Icons.bookmark,
                                  color: Colors.red[800],
                                  size: 40.0,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'PDF Rendering does not '
                    'support on the system of this version',
                  ),
                );
              }

              return Center(child: CircularProgressIndicator());
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                title: Text('الإنتقال إلى العلامة'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                title: Text('حفظ العلامة'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.format_list_numbered_rtl),
                title: Text('الفهرس'),
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.red[800],
            onTap: _onItemTapped,
          ),
        ),
      );

  Future<bool> hasSupport() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    bool hasSupport = androidInfo.version.sdkInt >= 21;
    return hasSupport;
  }

  void showBookmark(int position) {
    print("called for page : $position");
    if (position == 568) {
      setState(() {
        isBookmarked=true;
      });
    }else{
      setState(() {
        isBookmarked=false;
      });
    }
  }

  Future<PDFDocument> _getDocument() async {
    if (_document != null) {
      return _document;
    }
    if (await hasSupport()) {
      return _document = await PDFDocument.openAsset('assets/quran.pdf');
    } else {
      throw Exception(
        'PDF Rendering does not '
        'support on the system of this version',
      );
    }
  }
}
