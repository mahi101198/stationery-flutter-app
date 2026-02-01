#!/usr/bin/env python3
"""
Final Dart File Usage Analysis with Manual Verification
"""
import os
import re
from typing import List, Set, Dict

def get_all_dart_files(lib_path: str) -> List[str]:
    """Get all .dart files in the lib directory"""
    dart_files = []
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file).replace('\\', '/')
                dart_files.append(filepath)
    return dart_files

def check_file_usage(target_file: str, all_files: List[str], lib_path: str) -> Dict:
    """Check if a specific file is used anywhere"""
    relative_path = os.path.relpath(target_file, lib_path).replace('\\', '/')
    filename = os.path.basename(target_file)
    base_name = filename.replace('.dart', '')
    
    usage_info = {
        'file_path': relative_path,
        'import_references': [],
        'class_references': [],
        'string_references': [],
        'part_references': [],
        'is_used': False,
        'classes_defined': []
    }
    
    # Get classes defined in this file
    try:
        with open(target_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        class_pattern = r"class\s+(\w+)(?:\s+extends|\s+implements|\s+with|\s*\{)"
        for match in re.finditer(class_pattern, content):
            usage_info['classes_defined'].append(match.group(1))
            
        enum_pattern = r"enum\s+(\w+)\s*\{"
        for match in re.finditer(enum_pattern, content):
            usage_info['classes_defined'].append(match.group(1))
    except:
        pass
    
    # Check all other files for references
    for other_file in all_files:
        if other_file == target_file:
            continue
            
        try:
            with open(other_file, 'r', encoding='utf-8') as f:
                other_content = f.read()
            
            other_relative = os.path.relpath(other_file, lib_path).replace('\\', '/')
            
            # Check for import statements
            if f"package:rps_stationery/{relative_path}" in other_content:
                usage_info['import_references'].append(other_relative)
                usage_info['is_used'] = True
            
            # Check for relative imports
            relative_import_patterns = [
                f"import '{relative_path}'",
                f'import "{relative_path}"',
                f"export '{relative_path}'",
                f'export "{relative_path}"'
            ]
            
            for pattern in relative_import_patterns:
                if pattern in other_content:
                    usage_info['import_references'].append(other_relative)
                    usage_info['is_used'] = True
            
            # Check for part statements
            if f"part '{filename}'" in other_content or f'part "{filename}"' in other_content:
                usage_info['part_references'].append(other_relative)
                usage_info['is_used'] = True
            
            # Check for class references
            for class_name in usage_info['classes_defined']:
                if re.search(rf'\b{class_name}\b', other_content):
                    usage_info['class_references'].append(f"{other_relative} -> {class_name}")
                    usage_info['is_used'] = True
            
            # Check for string references to the file name
            if filename in other_content or base_name in other_content:
                usage_info['string_references'].append(other_relative)
                # Note: Don't mark as used yet, need manual verification
                
        except Exception as e:
            continue
    
    return usage_info

def final_analysis(lib_path: str):
    """Perform final analysis with detailed verification"""
    all_files = get_all_dart_files(lib_path)
    
    # Files from comprehensive analysis that were marked as potentially unused
    potentially_unused = [
        "common/styles/spacing_styles.dart",
        "components/custom_modal_bottom_sheet.dart", 
        "data/services/cart_service.dart",
        "features/personalization/controllers/profile_controller.dart",
        "features/search/components/no_search_result.dart",
        "features/shop/controllers/promo_controller.dart",
        "services/navigation_service.dart",
        "utils/adapters/address_adapter.dart",
        "utils/adapters/order_item_adapter.dart",
        "utils/constants/app_gaps.dart",
        "utils/constants/app_padding.dart",
        "utils/constants/enums.dart",
        "utils/helpers/cloud_helper_functions.dart",
        "utils/helpers/image_manager.dart",
        "utils/helpers/referral_code_generator.dart",
        "utils/helpers/responsive_helper.dart",
        "utils/http/http_client.dart",
        "utils/logging/logger.dart",
        "utils/theme/component_themes.dart",
        "utils/theme/create_text_theme.dart",
        "utils/theme/custom_themes/button_theme.dart",
        "utils/theme/theme.dart",
        "utils/theme/widget_themes/appbar_theme.dart",
        "utils/theme/widget_themes/text_theme.dart",
        "utils/validators/spacing_validator_script.dart"
    ]
    
    truly_unused = []
    false_positives = []
    
    print("DETAILED VERIFICATION OF POTENTIALLY UNUSED FILES")
    print("=" * 80)
    
    for relative_path in potentially_unused:
        full_path = os.path.join(lib_path, relative_path).replace('\\', '/')
        if not os.path.exists(full_path):
            continue
            
        usage_info = check_file_usage(full_path, all_files, lib_path)
        
        print(f"\n📋 {relative_path}")
        print("-" * 50)
        
        if usage_info['classes_defined']:
            print(f"   Classes: {', '.join(usage_info['classes_defined'])}")
        
        if usage_info['import_references']:
            print(f"   ✅ Direct imports: {', '.join(usage_info['import_references'])}")
            false_positives.append(relative_path)
        elif usage_info['part_references']:
            print(f"   ✅ Part references: {', '.join(usage_info['part_references'])}")
            false_positives.append(relative_path)
        elif usage_info['class_references']:
            print(f"   ⚠️  Class references: {', '.join(usage_info['class_references'][:3])}")
            false_positives.append(relative_path)
        elif usage_info['string_references']:
            print(f"   ⚠️  String references: {', '.join(usage_info['string_references'][:3])}")
            print("       (Needs manual verification)")
        else:
            print("   ❌ No references found")
            truly_unused.append(relative_path)
    
    print("\n" + "=" * 80)
    print("FINAL RESULTS")
    print("=" * 80)
    
    print(f"\n✅ FALSE POSITIVES (Actually used): {len(false_positives)}")
    for fp in false_positives:
        print(f"   • {fp}")
    
    print(f"\n❌ TRULY UNUSED FILES (Safe to remove): {len(truly_unused)}")
    for unused in truly_unused:
        print(f"   • {unused}")
    
    print(f"\n📊 SUMMARY")
    print(f"   • Total analyzed: {len(potentially_unused)}")
    print(f"   • Actually used: {len(false_positives)}")  
    print(f"   • Truly unused: {len(truly_unused)}")
    print(f"   • Accuracy improvement: {((len(potentially_unused) - len(truly_unused)) / len(potentially_unused) * 100):.1f}%")
    
    return truly_unused

def main():
    lib_path = r"d:\backup rps\rps-stationery-main\lib"
    
    if not os.path.exists(lib_path):
        print(f"Library path not found: {lib_path}")
        return
    
    final_analysis(lib_path)

if __name__ == "__main__":
    main()