import re

# Remove CategoryCards section and add SubcategoryFilterRow
file_path = r'd:\backup rps\rps-stationery-main\lib\features\home\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to match the entire Categories Section
# From "// Categories Section" to the SizedBox before "// Home Sections"
pattern = r'          // Categories Section - Minimalist Header.*?const SliverToBoxAdapter\(child: SizedBox\(height: 32\)\),\r?\n\r?\n'

replacement = '''          // Subcategory Filter Row
          const SliverToBoxAdapter(
            child: SubcategoryFilterRow(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

'''

# Replace the section
content_new = re.sub(pattern, replacement, content, flags=re.DOTALL)

if content_new != content:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content_new)
    print("✅ Replaced Categories Section with SubcategoryFilterRow")
else:
    print("⚠️  Pattern not found, trying alternative approach...")
    
    # Alternative: Just remove CategoryCards widget
    if 'const CategoryCards()' in content:
        # Find and replace the CategoryCards section
        lines = content.split('\n')
        new_lines = []
        skip_until_home_sections = False
        
        for i, line in enumerate(lines):
            if '// Categories Section' in line:
                # Add SubcategoryFilterRow instead
                new_lines.append('          // Subcategory Filter Row')
                new_lines.append('          const SliverToBoxAdapter(')
                new_lines.append('            child: SubcategoryFilterRow(),')
                new_lines.append('          ),')
                new_lines.append('          const SliverToBoxAdapter(child: SizedBox(height: 20)),')
                new_lines.append('')
                skip_until_home_sections = True
                continue
            
            if skip_until_home_sections:
                if '// Home Sections' in line:
                    skip_until_home_sections = False
                    new_lines.append(line)
                continue
            
            new_lines.append(line)
        
        content_new = '\n'.join(new_lines)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content_new)
        print("✅ Replaced Categories Section with SubcategoryFilterRow (alternative method)")
    else:
        print("⏭️  CategoryCards already removed")

print("\n✅ HomeScreen layout update completed!")
