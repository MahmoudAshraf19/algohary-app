import 'dart:html' as html;

void downloadFileWeb(String url, String filename) {
  html.AnchorElement anchorElement = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..target = 'blank';
  anchorElement.click();
}
