"""
Helper script to complete home page redesign implementation.
Adds the remaining code changes that couldn't be automated due to file encoding issues.
"""

import os
import re

def add_filtering_method_to_controller():
    """Add getFilteredSectionItems method to HomeSectionController"""
    file_path = r'd:\backup rps\rps-stationery-main\lib\features\home\controllers\home_section_controller.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find the location after getSectionsByType method
    pattern = r'(  /// Get sections by type\r?\n  List<HomeSectionModel> getSectionsByType\(String type\) \{\r?\n    return activeSections\.where\(\(s\) => s\.type == type\)\.toList\(\);\r?\n  \}\r?\n)'
    
    new_method = r'''\1
  /// Get filtered section items by subcategory
  List<HomeSectionItemModel> getFilteredSectionItems(
    String sectionId,
    String? subcategoryId,
  ) {
    final allItems = getSectionItems(sectionId);
    
    // If no subcategory selected ("All"), return all items
    if (subcategoryId == null || subcategoryId.isEmpty) {
      return allItems;
    }
    
    // Filter by subcategory
    return allItems.where((item) => item.subcategoryId == subcategoryId).toList();
  }

'''
    
    if 'getFilteredSectionItems' not in content:
        content = re.sub(pattern, new_method, content)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("✅ Added getFilteredSectionItems method to HomeSectionController")
    else:
        print("⏭️  getFilteredSectionItems method already exists")

def update_home_sections_list():
    """Update HomeSectionsList to use filtering"""
    file_path = r'd:\backup rps\rps-stationery-main\lib\features\home\components\home_sections_list.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add import if not present
    if 'subcategory_filter_controller' not in content:
        import_line = "import 'package:rps_stationery/features/home/controllers/subcategory_filter_controller.dart';\n"
        content = content.replace(
            "import 'package:rps_stationery/data/models/home_section_model.dart';",
            "import 'package:rps_stationery/data/models/home_section_model.dart';\n" + import_line
        )
        print("✅ Added SubcategoryFilterController import")
    
    # Update _buildSection method to use filtering
    old_pattern = r'    return Obx\(\(\) \{\r?\n      final items = controller\.getSectionItems\(section\.sectionId\);\r?\n      final isLoading = controller\.isSectionLoading\(section\.sectionId\);'
    
    new_code = '''    return Obx(() {
      // Get subcategory filter controller
      final filterController = Get.find<SubcategoryFilterController>();
      final selectedSubcategoryId = filterController.selectedSubcategoryId.value;
      
      // Get filtered items
      final allItems = controller.getSectionItems(section.sectionId);
      final filteredItems = selectedSubcategoryId == null
          ? allItems
          : allItems.where((item) => item.subcategoryId == selectedSubcategoryId).toList();
      
      final isLoading = controller.isSectionLoading(section.sectionId);'''
    
    if 'filterController' not in content:
        content = re.sub(old_pattern, new_code, content)
        
        # Update items reference to filteredItems
        content = content.replace(
            'if (!isLoading && items.isEmpty)',
            'if (!isLoading && filteredItems.isEmpty)'
        )
        content = content.replace(
            '_buildSectionItems(context, items)',
            '_buildSectionItems(context, filteredItems)'
        )
        print("✅ Updated _buildSection method with filtering logic")
    else:
        print("⏭️  Filtering logic already added to _buildSection")
    
    # Update _buildSectionItems to calculate width for 4 cards
    old_items_pattern = r'  Widget _buildSectionItems\(BuildContext context, List items\) \{\r?\n    return SizedBox\(\r?\n      height: 240,\r?\n      child: ListView\.builder\(\r?\n        scrollDirection: Axis\.horizontal,\r?\n        padding: const EdgeInsets\.symmetric\(horizontal: 16\),\r?\n        itemCount: items\.length,\r?\n        itemBuilder: \(context, index\) \{\r?\n          final item = items\[index\];\r?\n          return SectionItemCard\(item: item\);'
    
    new_items_code = '''  Widget _buildSectionItems(BuildContext context, List items) {
    // Calculate width to show ~4 cards
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 4.2;
    
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return SectionItemCard(
            item: item,
            width: cardWidth,
          );'''
    
    if 'cardWidth' not in content:
        content = re.sub(old_items_pattern, new_items_code, content)
        print("✅ Updated _buildSectionItems with width calculation")
    else:
        print("⏭️  Width calculation already added to _buildSectionItems")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def update_section_item_card():
    """Update SectionItemCard design system styling"""
    file_path = r'd:\backup rps\rps-stationery-main\lib\components\home\section_item_card.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update main card border radius
    content = content.replace(
        'borderRadius: BorderRadius.circular(12),',
        'borderRadius: BorderRadius.circular(16),'
    )
    
    # Update shadow
    content = content.replace(
        'blurRadius: 8,\n              offset: const Offset(0, 2),',
        'blurRadius: 4,\n              offset: const Offset(0, 1),'
    )
    
    # Update badge border radius
    content = content.replace(
        'borderRadius: BorderRadius.circular(4),',
        'borderRadius: BorderRadius.circular(8),'
    )
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Updated SectionItemCard design system styling")

def update_home_screen():
    """Update HomeScreen layout"""
    file_path = r'd:\backup rps\rps-stationery-main\lib\features\home\home_screen.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add imports
    if 'subcategory_filter_controller' not in content:
        import_lines = """import 'package:rps_stationery/features/home/controllers/subcategory_filter_controller.dart';
import 'package:rps_stationery/features/home/components/subcategory_filter_row.dart';
"""
        content = content.replace(
            "import 'package:rps_stationery/features/home/controllers/home_section_controller.dart';",
            "import 'package:rps_stationery/features/home/controllers/home_section_controller.dart';\n" + import_lines
        )
        print("✅ Added imports to HomeScreen")
    
    # Add controller variable
    if '_subcategoryFilterController' not in content:
        content = content.replace(
            'late HomeSectionController _homeSectionController;',
            '''late HomeSectionController _homeSectionController;
  late SubcategoryFilterController _subcategoryFilterController;'''
        )
        print("✅ Added subcategory filter controller variable")
    
    # Initialize controller in initState
    if 'SubcategoryFilterController()' not in content:
        content = content.replace(
            "print('🏠 HomeScreen: Home section controller initialized');",
            """print('🏠 HomeScreen: Home section controller initialized');
    
    _subcategoryFilterController = Get.put(SubcategoryFilterController());
    print('🏷️ HomeScreen: Subcategory filter controller initialized');"""
        )
        print("✅ Added controller initialization")
    
    # Add background color to Scaffold
    if 'backgroundColor: const Color(0xFAFAFAFA)' not in content:
        content = content.replace(
            'return Scaffold(\n      body: Stack(',
            'return Scaffold(\n      backgroundColor: const Color(0xFAFAFAFA),\n      body: Stack('
        )
        print("✅ Added background color to Scaffold")
    
    # Remove CategoryCards section and add SubcategoryFilterRow
    # This is complex, so we'll provide instructions instead
    print("⚠️  Manual step required: Remove CategoryCards section and add SubcategoryFilterRow")
    print("    See walkthrough.md for detailed instructions")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    print("🚀 Starting home page redesign completion script...\n")
    
    try:
        add_filtering_method_to_controller()
        update_home_sections_list()
        update_section_item_card()
        update_home_screen()
        
        print("\n✅ Script completed successfully!")
        print("\n📝 Next steps:")
        print("1. Manually remove CategoryCards section from HomeScreen")
        print("2. Manually add SubcategoryFilterRow below banner in HomeScreen")
        print("3. Run: flutter analyze")
        print("4. Run: flutter run")
        print("\nSee walkthrough.md for detailed instructions")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("Please complete the changes manually using walkthrough.md")
