import 'package:flutter/material.dart';
import 'package:nearify/models/location_model.dart';
import '../utils/constants.dart';

class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final List<LocationModel> suggestions;
  final Function(String) onSearch;
  final Function(LocationModel) onSuggestionSelected;
  final Function() onClear;
  final String? currentDestination;

  const SearchBar({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.onSearch,
    required this.onSuggestionSelected,
    required this.onClear,
    this.currentDestination,
  });

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && widget.suggestions.isNotEmpty;
    });
  }

  @override
  void didUpdateWidget(SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update suggestions visibility when suggestions list changes
    if (widget.suggestions != oldWidget.suggestions) {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && widget.suggestions.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onSuggestionTap(LocationModel suggestion) {
    widget.onSuggestionSelected(suggestion);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  void _onClear() {
    widget.controller.clear();
    widget.onClear();
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Input Field
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focusNode.hasFocus ? Colors.blue : Colors.grey.shade300,
                width: _focusNode.hasFocus ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.currentDestination != null
                    ? 'Change destination'
                    : 'Search for a destination (e.g., Kempegowda Airport)',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: Icon(
                  widget.currentDestination != null ? Icons.edit_location : Icons.search,
                  color: _focusNode.hasFocus ? Colors.blue : Colors.grey.shade400,
                ),
                suffixIcon: (widget.controller.text.isNotEmpty || widget.currentDestination != null)
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.currentDestination != null && widget.controller.text.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.currentDestination!.length > 20
                              ? '${widget.currentDestination!.substring(0, 20)}...'
                              : widget.currentDestination!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _onClear,
                    ),
                  ],
                )
                    : null,
              ),
              onChanged: (value) {
                widget.onSearch(value);
                // Force rebuild to show/hide clear button
                setState(() {});
              },
              onSubmitted: (value) {
                if (value.isNotEmpty && widget.suggestions.isNotEmpty) {
                  _onSuggestionTap(widget.suggestions.first);
                }
              },
            ),
          ),

          // Suggestions List
          if (_showSuggestions)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: widget.suggestions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = widget.suggestions[index];
                    return InkWell(
                      onTap: () => _onSuggestionTap(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    suggestion.name ?? suggestion.address ?? 'Unknown place',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (suggestion.address != null &&
                                      suggestion.address != suggestion.name)
                                    Text(
                                      suggestion.address!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_outward,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}