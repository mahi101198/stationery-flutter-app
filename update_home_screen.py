import sys

# Add imports to home_screen.dart
file_path = r'd:\backup rps\rps-stationery-main\lib\features\home\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports if not already present
if 'subcategory_filter_controller' not in content:
    content = content.replace(
        "import 'controllers/home_section_controller.dart';",
        "import 'controllers/home_section_controller.dart';\nimport 'controllers/subcategory_filter_controller.dart';\nimport 'components/subcategory_filter_row.dart';"
    )
    print("✅ Added imports")
else:
    print("⏭️  Imports already exist")

# Add controller variable if not present
if '_subcategoryFilterController' not in content:
    content = content.replace(
        'late HomeSectionController _homeSectionController;',
        'late HomeSectionController _homeSectionController;\n  late SubcategoryFilterController _subcategoryFilterController;'
    )
    print("✅ Added controller variable")
else:
    print("⏭️  Controller variable already exists")

# Initialize controller in initState
if 'SubcategoryFilterController()' not in content:
    content = content.replace(
        "print('🏠 HomeScreen: Home section controller initialized');",
        "print('🏠 HomeScreen: Home section controller initialized');\n    \n    _subcategoryFilterController = Get.put(SubcategoryFilterController());\n    print('🏷️ HomeScreen: Subcategory filter controller initialized');"
    )
    print("✅ Added controller initialization")
else:
    print("⏭️  Controller initialization already exists")

# Add background color
if 'backgroundColor: const Color(0xFAFAFAFA)' not in content:
    content = content.replace(
        'return Scaffold(\n      body: Stack(',
        'return Scaffold(\n      backgroundColor: const Color(0xFAFAFAFA),\n      body: Stack('
    )
    print("✅ Added background color")
else:
    print("⏭️  Background color already exists")

# Remove CategoryCards import if present
if "import 'components/category_cards.dart';" in content:
    content = content.replace("import 'components/category_cards.dart';\n", "")
    print("✅ Removed CategoryCards import")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ HomeScreen updates completed!")
