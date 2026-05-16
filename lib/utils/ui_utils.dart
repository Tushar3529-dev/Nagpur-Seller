import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';

enum ScreenType { mobile, tablet }

/// UIUtils = Design Tokens + UI Rules
/// This file should be the SINGLE SOURCE OF TRUTH for UI sizing.
class UIUtils {
  // -------------------------------
  // FONT SIZES
  // -------------------------------

  static double appTitle(ScreenType t) => t == ScreenType.tablet ? 24 : 18;
  static double pageTitle(ScreenType t) => t == ScreenType.tablet ? 22 : 16;
  static double sectionTitle(ScreenType t) => t == ScreenType.tablet ? 20 : 16;
  static double sectionSubtitle(ScreenType t) =>
      t == ScreenType.tablet ? 16 : 14; // Profile Body

  static double tileTitle(ScreenType t) => t == ScreenType.tablet ? 18 : 16;
  static double tileSubtitle(ScreenType t) => t == ScreenType.tablet ? 15 : 13;

  static double body(ScreenType t) => t == ScreenType.tablet ? 16 : 14;
  static double caption(ScreenType t) => t == ScreenType.tablet ? 13 : 11;

  static double bottomNavFontSize(ScreenType t) =>
      t == ScreenType.tablet ? 15 : 13;

  // -------------------------------
  // FONT WEIGHTS
  // -------------------------------

  static FontWeight bold = FontWeight.w600;
  static FontWeight semiBold = FontWeight.w500;
  static FontWeight regular = FontWeight.w400;

  // -------------------------------
  // ICON SIZES
  // -------------------------------

  static double appBarIcon(ScreenType t) => t == ScreenType.tablet ? 28 : 22;
  static double sectionIcon(ScreenType t) => t == ScreenType.tablet ? 24 : 18;
  static double tileIcon(ScreenType t) => t == ScreenType.tablet ? 22 : 18;
  static double smallIcon(ScreenType t) => t == ScreenType.tablet ? 18 : 14;

  static double chevronIcon(ScreenType t) => t == ScreenType.tablet ? 24 : 20;

  // Bottom Navigation Icon Sizes
  static double bottomNavIconActive(ScreenType t) =>
      t == ScreenType.tablet ? 26 : 22;
  static double bottomNavIconInactive(ScreenType t) =>
      t == ScreenType.tablet ? 24 : 20;

  // -------------------------------
  // SPACING / GAPS
  // -------------------------------

  static double gapXS(ScreenType t) => t == ScreenType.tablet ? 6 : 4;
  static double gapSM(ScreenType t) => t == ScreenType.tablet ? 10 : 6;
  static double gapMD(ScreenType t) =>
      t == ScreenType.tablet ? 16 : 12; // Adjusted for gaps
  static double gapLG(ScreenType t) => t == ScreenType.tablet ? 24 : 16;
  static double gapXL(ScreenType t) => t == ScreenType.tablet ? 32 : 20;

  // -------------------------------
  // PADDING
  // -------------------------------

  static EdgeInsets pagePadding(ScreenType t) =>
      EdgeInsets.all(t == ScreenType.tablet ? 24 : 16);

  static EdgeInsets cardPadding(ScreenType t) =>
      EdgeInsets.all(t == ScreenType.tablet ? 20 : 12);

  static EdgeInsets tilePadding(ScreenType t) => EdgeInsets.symmetric(
    horizontal: t == ScreenType.tablet ? 20 : 16,
    vertical: t == ScreenType.tablet ? 16 : 12,
  );

  static EdgeInsets tilePadding2(ScreenType t) => EdgeInsets.symmetric(
    horizontal: t == ScreenType.tablet ? 16 : 12,
    vertical: t == ScreenType.tablet ? 12 : 8,
  );

  static EdgeInsets taxGroupPadding(ScreenType t) => EdgeInsets.symmetric(
    horizontal: t == ScreenType.tablet ? 16 : 12,
    vertical: t == ScreenType.tablet ? 8 : 4,
  );

  static EdgeInsets sectionPadding(ScreenType t) => EdgeInsets.symmetric(
    horizontal: t == ScreenType.tablet ? 24 : 14, // Custom Section padding
    vertical: t == ScreenType.tablet ? 20 : 16,
  );

  static EdgeInsets bottomNavPadding(ScreenType t) =>
      EdgeInsets.only(bottom: t == ScreenType.tablet ? 10 : 6);

  static EdgeInsets cardsPadding(ScreenType t) => EdgeInsets.fromLTRB(
    t == ScreenType.tablet ? 24 : 16,
    0.0,
    t == ScreenType.tablet ? 24 : 16,
    t == ScreenType.tablet ? 24 : 16,
  );

  // -------------------------------
  // HEIGHTS
  // -------------------------------

  static double buttonHeight(ScreenType t) => t == ScreenType.tablet ? 56 : 44;
  static double inputHeight(ScreenType t) => t == ScreenType.tablet ? 54 : 42;
  static double appBarHeight(ScreenType t) => t == ScreenType.tablet ? 72 : 56;
  static double listTileHeight(ScreenType t) =>
      t == ScreenType.tablet ? 72 : 56;
  static double bottomNavHeight(ScreenType t) =>
      t == ScreenType.tablet ? 80 : 60;

  static double profileAppBarHeight(ScreenType t) =>
      t == ScreenType.tablet ? 160 : 120;

  // -------------------------------
  // WIDTHS
  // -------------------------------

  static double maxContentWidth(ScreenType t) =>
      t == ScreenType.tablet ? 720 : double.infinity;

  static double sidePanelWidth(ScreenType t) =>
      t == ScreenType.tablet ? 280 : 0;

  // -------------------------------
  // BORDER RADIUS
  // -------------------------------

  static double radiusXS(ScreenType t) => t == ScreenType.tablet ? 6 : 4;
  static double radiusSM(ScreenType t) => t == ScreenType.tablet ? 8 : 6;
  static double radiusMD(ScreenType t) => t == ScreenType.tablet ? 12 : 8;
  static double radiusLG(ScreenType t) => t == ScreenType.tablet ? 16 : 12;
  static double radiusXL(ScreenType t) => t == ScreenType.tablet ? 24 : 20;

  // -------------------------------
  // ELEVATION
  // -------------------------------

  static double cardElevation(ScreenType t) => t == ScreenType.tablet ? 3 : 1;
  static double appBarElevation(ScreenType t) => t == ScreenType.tablet ? 2 : 0;

  // -------------------------------
  // DIVIDERS
  // -------------------------------

  static double dividerThickness(ScreenType t) => t == ScreenType.tablet
      ? 1.2
      : 0.8; // More Page uses 0.5? But 0.8 is fine token.

  static EdgeInsets dividerPadding(ScreenType t) =>
      EdgeInsets.symmetric(vertical: t == ScreenType.tablet ? 12 : 8);

  // -------------------------------
  // AVATAR / IMAGE SIZES
  // -------------------------------

  static double avatarSM(ScreenType t) => t == ScreenType.tablet ? 36 : 28;
  static double avatarMD(ScreenType t) => t == ScreenType.tablet ? 48 : 36;
  static double avatarLG(ScreenType t) => t == ScreenType.tablet ? 64 : 48;
  static double avatarXL(ScreenType t) => t == ScreenType.tablet ? 105 : 75;

  // Profile Avatar Radius (not diameter)
  static double profileAvatarRadius(ScreenType t) =>
      t == ScreenType.tablet ? 50 : 40;
  static double profileIconSize(ScreenType t) =>
      t == ScreenType.tablet ? 60 : 48;

  // -------------------------------
  // LIST / GRID
  // -------------------------------

  static int gridColumns(ScreenType t) => t == ScreenType.tablet ? 3 : 1;
  static double gridSpacing(ScreenType t) => t == ScreenType.tablet ? 20 : 12;

  // -------------------------------
  // ANIMATION DURATIONS
  // -------------------------------

  static Duration fastAnim = const Duration(milliseconds: 150);
  static Duration normalAnim = const Duration(milliseconds: 250);
  static Duration slowAnim = const Duration(milliseconds: 400);

  /// Helper to get generic device width/height if needed,
  /// but prefer using the tokens above.
  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
}

/// Extension to easier access ScreenType from Context
extension ResponsiveContext on BuildContext {
  /// Use in build() methods to listen for changes
  ScreenType get screenType {
    // Uses 'watch' to trigger rebuild when state changes
    return watch<ScreenSizeBloc>().state.screenType;
  }

  /// Use in event handlers (onTap, onPressed) where 'watch' is not allowed
  ScreenType get screenTypeRead {
    return read<ScreenSizeBloc>().state.screenType;
  }
}

/// UI Dialogs
class UIUtilsDialogs {
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: _LoadingDialog(),
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
