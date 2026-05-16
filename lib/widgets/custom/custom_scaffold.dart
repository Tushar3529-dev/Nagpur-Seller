import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/widgets/custom/custom_filter_sheet.dart';
import 'package:hyper_local_seller/widgets/custom/custom_search_field.dart';

class CustomScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final bool? showAppbar;
  final PreferredSizeWidget? appBar;
  final List<Widget>? appBarActions;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final bool isHaveSearch;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final bool centerTitle;
  final bool? behindAppbar;
  final TextEditingController? searchController;
  final VoidCallback? onBackTap;
  final FloatingActionButton? floatingActionButton;
  final bool? showFilters;
  final bool? showStore;
  final FilterType filterType;

  const CustomScaffold({
    super.key,
    required this.body,
    this.title,
    this.showAppbar,
    this.appBar,
    this.appBarActions,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.isHaveSearch = false,
    this.onSearchChanged,
    this.searchHint,
    this.centerTitle = false,
    this.searchController,
    this.onBackTap,
    this.behindAppbar = false,
    this.floatingActionButton,
    this.showFilters = false,
    this.showStore = false,
    this.filterType = FilterType.order,
  });

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final tertiary = theme.colorScheme.tertiary;
    final isDark = theme.brightness == Brightness.dark;

    PreferredSizeWidget? appBar;
    if (widget.appBar != null) {
      appBar = widget.appBar;
    } else if (widget.showAppbar == true) {
      appBar = AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Platform.isAndroid
                      ? Icons.arrow_back
                      : Icons.arrow_back_ios_new_rounded,
                  color: tertiary,
                ),
                onPressed: widget.onBackTap ?? () => Navigator.pop(context),
              )
            : null,
        title: widget.title != null
            ? Text(
                widget.title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: tertiary,
                ),
              )
            : null,
        centerTitle: widget.centerTitle,
        actions: widget.appBarActions,
        actionsPadding: EdgeInsets.only(right: 4),
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        bottom: widget.isHaveSearch ? _buildSearchAppBar(isDark) : null,
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: widget.behindAppbar ?? false,
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
      appBar: appBar,
      body: widget.body,
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  PreferredSize _buildSearchAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(54.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CustomSearchField(
          controller: widget.searchController,
          onChanged: widget.onSearchChanged,
          hint: widget.searchHint ?? "Search",
          showFilters: widget.showFilters,
          showStore: widget.showStore,
          filterType: widget.filterType,
        ),
      ),
    );
  }
}
