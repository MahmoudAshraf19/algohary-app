// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileWeb(String url, String filename) {
  // `_blank` opens a new tab; the previous `blank` created a window literally
  // named "blank" that was reused (and could stay hidden) between downloads.
  final anchorElement = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..target = '_blank'
    ..rel = 'noopener';
  anchorElement.click();
}
