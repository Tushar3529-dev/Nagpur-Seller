import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';

class SettingsContentPage extends StatelessWidget {
  final String title;
  final String htmlContent;

  const SettingsContentPage({
    super.key,
    required this.title,
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    return CustomScaffold(
      title: title,
      showAppbar: true,
      centerTitle: true,
      body: SingleChildScrollView(
        padding: UIUtils.pagePadding(screenType),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HtmlWidget(
              htmlContent.isEmpty ? "<p>No content available.</p>" : htmlContent,
              textStyle: TextStyle(
                fontSize: UIUtils.body(screenType),
                height: 1.5,
              ),
              customStylesBuilder: (element) {
                if (element.localName == 'a' &&
                    element.attributes['href']?.startsWith('mailto:') == true) {
                  return {
                    'display': 'inline',
                    'visibility': 'visible',
                    'text-decoration': 'underline',
                    'font-size': '${UIUtils.body(screenType)}px',
                    'color': 'blue !important',
                    'background-color': 'transparent',
                  };
                }
                return null; // let other elements use default styles
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
