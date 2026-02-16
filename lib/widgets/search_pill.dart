import 'package:flutter/material.dart';

class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onSearchTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_list_bulleted, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Search Dua For.....',
                hintStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearchTap,
          ),
        ],
      ),
    );
  }
}
