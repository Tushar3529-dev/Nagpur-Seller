import 'package:flutter/material.dart';

class MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });
}

class CustomDropMenu extends StatefulWidget {
  final List<MenuItem> items;
  final Color? dotsColor;
  final double dotsSize;
  final Color? menuBackgroundColor;
  final BorderRadius? menuBorderRadius;
  final EdgeInsetsGeometry? menuPadding;
  final double? maxMenuWidth;
  final BoxShadow? menuShadow;
  final Duration animationDuration;

  const CustomDropMenu({
    super.key,
    required this.items,
    this.dotsColor,
    this.dotsSize = 24,
    this.menuBackgroundColor,
    this.menuBorderRadius,
    this.menuPadding,
    this.maxMenuWidth = 150,
    this.menuShadow,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<CustomDropMenu> createState() => _CustomDropMenuState();
}

class _CustomDropMenuState extends State<CustomDropMenu>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (!mounted) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() {
      _isOpen = true;
    });
  }

  void _closeMenu() {
    if (!mounted) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOpen = false;
      return;
    }

    _animationController.reverse().then((_) {
      if (mounted) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });

    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    final menuWidth = widget.maxMenuWidth ?? 150;
    const verticalGap = 8.0;
    const horizontalPadding = 8.0;

    // Calculate horizontal position - align to right edge of button
    double menuLeft = offset.dx + size.width - menuWidth - 4;

    // Ensure menu doesn't go off left edge
    if (menuLeft < horizontalPadding) {
      menuLeft = horizontalPadding;
    }

    // Ensure menu doesn't go off right edge
    if (menuLeft + menuWidth > screenSize.width - horizontalPadding) {
      menuLeft = screenSize.width - menuWidth - horizontalPadding;
    }

    // Calculate vertical position
    double menuTop = offset.dy + size.height + verticalGap;
    final estimatedMenuHeight = (widget.items.length * 44.0) + 16;

    // If not enough space below, show above
    if (menuTop + estimatedMenuHeight > screenSize.height - 100) {
      menuTop = offset.dy - estimatedMenuHeight - verticalGap;
    }

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeMenu,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: menuLeft,
              top: menuTop,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: _buildMenu(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final defaultBorderColor =
    isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300;

    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.maxMenuWidth ?? 150,
        minWidth: widget.maxMenuWidth ?? 150,
      ),
      decoration: BoxDecoration(
        color: widget.menuBackgroundColor ?? defaultBgColor,
        borderRadius: widget.menuBorderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: defaultBorderColor, width: 1),
        boxShadow: [
          widget.menuShadow ??
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final isLast = index == widget.items.length - 1;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    item.onTap();
                    _closeMenu();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: widget.menuPadding ??
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 16,
                          color: item.iconColor ??
                              (isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: item.textColor ??
                                  (isDark
                                      ? Colors.white
                                      : Colors.black87),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withAlpha(15)
                        : Colors.grey.shade200,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleMenu,
        child: Icon(
          Icons.more_vert,
          size: widget.dotsSize,
          color: widget.dotsColor ??
              (isDark ? Colors.white70 : Colors.grey.shade600),
        ),
      ),
    );
  }
}