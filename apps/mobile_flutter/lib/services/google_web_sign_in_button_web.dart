import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

const double _googleWebButtonMaxWidth = 340;
const double _googleWebButtonHeight = 48;

Widget buildGoogleWebSignInButton() {
  return SizedBox(
    width: double.infinity,
    height: _googleWebButtonHeight,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _googleWebButtonMaxWidth;
        final buttonWidth = availableWidth < _googleWebButtonMaxWidth
            ? availableWidth
            : _googleWebButtonMaxWidth;
        if (buttonWidth <= 0 || !buttonWidth.isFinite) {
          return const SizedBox.shrink();
        }

        return Center(
          child: SizedBox(
            width: buttonWidth,
            height: _googleWebButtonHeight,
            child: Align(
              alignment: Alignment.center,
              child: web.renderButton(
                configuration: web.GSIButtonConfiguration(
                  type: web.GSIButtonType.standard,
                  theme: web.GSIButtonTheme.filledBlack,
                  size: web.GSIButtonSize.large,
                  text: web.GSIButtonText.signin,
                  shape: web.GSIButtonShape.rectangular,
                  minimumWidth: buttonWidth,
                  locale: 'en',
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
