import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// View displaying locally saved recent searches and browse genre categories.
class RecentSearchesView extends StatelessWidget {
  final List<String> recentSearches;
  final void Function(String query) onSelectQuery;
  final void Function(String query) onRemoveQuery;
  final VoidCallback onClearAll;

  const RecentSearchesView({
    super.key,
    required this.recentSearches,
    required this.onSelectQuery,
    required this.onRemoveQuery,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...recentSearches.map((query) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(
                Icons.history,
                color: AppColors.textSecondary,
                size: 22,
              ),
              title: Text(
                query,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                onPressed: () => onRemoveQuery(query),
              ),
              onTap: () => onSelectQuery(query),
            );
          }),
          const SizedBox(height: 18),
        ],

        const Text(
          'Browse all',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Quick browse genre cards
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildCategoryCard('Pop Hits', Colors.deepOrange, () => onSelectQuery('Pop')),
            _buildCategoryCard('Filipino / OPM', Colors.purple, () => onSelectQuery('OPM')),
            _buildCategoryCard('Rock & Indie', Colors.teal, () => onSelectQuery('Rock')),
            _buildCategoryCard('Chillout', Colors.pink, () => onSelectQuery('Chill')),
            _buildCategoryCard('Hip-Hop', Colors.blueGrey, () => onSelectQuery('Hip-Hop')),
            _buildCategoryCard('Electronic', Colors.indigo, () => onSelectQuery('Electronic')),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
