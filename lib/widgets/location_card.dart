import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearify/models/location_model.dart';

class LocationCard extends StatefulWidget {
  final LocationModel? location;
  final String title;
  final VoidCallback? onTap;
  final bool showCoordinates;
  final bool isCollapsible;
  final IconData? customIcon;
  final Color? accentColor;

  const LocationCard({
    super.key,
    this.location,
    required this.title,
    this.onTap,
    this.showCoordinates = true,
    this.isCollapsible = false,
    this.customIcon,
    this.accentColor,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _copyCoordinates() {
    if (widget.location != null) {
      final coordinates = '${widget.location!.latitude}, ${widget.location!.longitude}';
      Clipboard.setData(ClipboardData(text: coordinates));

      setState(() => _isLoading = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Coordinates copied: $coordinates'),
            ],
          ),
          backgroundColor: widget.accentColor ?? Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  Color get _accentColor => widget.accentColor ?? Colors.blue;

  IconData get _iconData {
    if (widget.customIcon != null) return widget.customIcon!;
    return widget.title.toLowerCase().contains('current')
        ? Icons.my_location
        : Icons.location_on;
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.location != null;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: hasLocation
              ? Border.all(color: _accentColor.withOpacity(0.1), width: 1)
              : null,
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasLocation
                          ? _accentColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: hasLocation
                        ? Icon(_iconData, color: _accentColor, size: 20)
                        : SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: hasLocation ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasLocation ? 'Located' : 'Locating...',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasLocation ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  if (hasLocation) ...[
                    if (widget.showCoordinates)
                      IconButton(
                        icon: _isLoading
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                          ),
                        )
                            : Icon(Icons.copy, size: 18, color: Colors.grey[600]),
                        onPressed: _isLoading ? null : _copyCoordinates,
                        tooltip: 'Copy Coordinates',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),

                    if (widget.isCollapsible)
                      IconButton(
                        icon: AnimatedRotation(
                          turns: _isExpanded ? 0.0 : 0.5,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.expand_less,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                        onPressed: _toggleExpanded,
                        tooltip: _isExpanded ? 'Collapse' : 'Expand',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                  ],
                ],
              ),
            ),

            // Content Section
            if (hasLocation)
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Location Name
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.place, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.location?.name ?? 'Unknown Location',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Address
                      if (widget.location?.address != null &&
                          widget.location?.address != widget.location?.name) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.map, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.location!.address!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Coordinates
                      if (widget.showCoordinates) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _accentColor.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.gps_fixed, size: 16, color: _accentColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Coordinates',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _accentColor,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${widget.location!.latitude.toStringAsFixed(6)}, ${widget.location!.longitude.toStringAsFixed(6)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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