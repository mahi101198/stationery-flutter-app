#!/usr/bin/env python3
"""
Comprehensive Flutter Dart File Usage Analyzer
More thorough analysis including route definitions, string references, etc.
"""
import os
import re
from typing import Dict, List, Set
from pathlib import Path

def get_all_dart_files(lib_path: str) -> List[str]:
    """Get all .dart files in the lib directory"""
    dart_files = []
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file).replace('\\', '/')
                dart_files.append(filepath)
    return dart_files

def extract_all_references_from_file(filepath: str) -> Set[str]:
    """Extract all possible references to other dart files"""
    references = set()
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 1. Import/export statements
        import_pattern = r"(?:import|export)\s+['\"]([^'\"]+)['\"]"
        for match in re.finditer(import_pattern, content):
            references.add(match.group(1))
        
        # 2. Part/part of statements
        part_pattern = r"part\s+['\"]([^'\"]+)['\"]"
        for match in re.finditer(part_pattern, content):
            references.add(match.group(1))
        
        # 3. GetPage page references (common in route files)
        # Look for patterns like: page: () => SomeScreen()
        page_pattern = r"page:\s*\(\)\s*=>\s*(?:const\s+)?(\w+)\("
        for match in re.finditer(page_pattern, content):
            class_name = match.group(1)
            references.add(f"class:{class_name}")
        
        # 4. Binding references
        binding_pattern = r"binding:\s*(\w+)\("
        for match in re.finditer(binding_pattern, content):
            class_name = match.group(1)
            references.add(f"binding:{class_name}")
        
        # 5. Widget/class instantiation patterns
        # Look for new ClassName() or ClassName()
        class_pattern = r"(?:new\s+)?([A-Z]\w+)\s*\("
        for match in re.finditer(class_pattern, content):
            class_name = match.group(1)
            # Skip common Flutter widgets
            if not class_name in {'Widget', 'State', 'StatefulWidget', 'StatelessWidget', 'Container', 'Column', 'Row', 'Text', 'Scaffold', 'AppBar'}:
                references.add(f"class:{class_name}")
        
        # 6. String references that might be file paths
        string_pattern = r"['\"]([^'\"]*\.dart)['\"]"
        for match in re.finditer(string_pattern, content):
            references.add(match.group(1))
            
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
    
    return references

def find_class_definitions(filepath: str) -> Set[str]:
    """Find all class definitions in a file"""
    classes = set()
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find class definitions
        class_pattern = r"class\s+(\w+)(?:\s+extends|\s+implements|\s+with|\s*\{)"
        for match in re.finditer(class_pattern, content):
            classes.add(match.group(1))
            
        # Find enum definitions  
        enum_pattern = r"enum\s+(\w+)\s*\{"
        for match in re.finditer(enum_pattern, content):
            classes.add(match.group(1))
            
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
    
    return classes

def comprehensive_analysis(lib_path: str):
    """Perform comprehensive analysis of dart file usage"""
    all_files = get_all_dart_files(lib_path)
    file_to_classes = {}  # filepath -> set of classes defined
    class_to_file = {}    # class name -> filepath
    all_references = {}   # filepath -> set of references
    used_files = set()    # files that are definitely used
    
    print(f"Analyzing {len(all_files)} .dart files...")
    
    # First pass: collect all class definitions
    for filepath in all_files:
        classes = find_class_definitions(filepath)
        file_to_classes[filepath] = classes
        for class_name in classes:
            if class_name not in class_to_file:
                class_to_file[class_name] = []
            class_to_file[class_name].append(filepath)
    
    # Second pass: collect all references
    for filepath in all_files:
        references = extract_all_references_from_file(filepath)
        all_references[filepath] = references
        
        # Process each reference
        for ref in references:
            # Handle direct file imports
            if ref.endswith('.dart'):
                # Convert package imports to file paths
                if ref.startswith('package:rps_stationery/'):
                    file_path = os.path.join(lib_path, ref[len('package:rps_stationery/'):]).replace('\\', '/')
                    if file_path in all_files:
                        used_files.add(file_path)
                elif ref.startswith('./') or ref.startswith('../') or (not ref.startswith('package:') and not ref.startswith('dart:')):
                    # Handle relative imports
                    dir_path = os.path.dirname(filepath)
                    file_path = os.path.normpath(os.path.join(dir_path, ref)).replace('\\', '/')
                    if file_path in all_files:
                        used_files.add(file_path)
            
            # Handle class references
            elif ref.startswith('class:') or ref.startswith('binding:'):
                class_name = ref.split(':', 1)[1]
                if class_name in class_to_file:
                    for file_path in class_to_file[class_name]:
                        used_files.add(file_path)
    
    # Always mark certain files as used
    core_patterns = [
        'main.dart',
        'app.dart',
        'firebase_options.dart',
        'constants.dart'
    ]
    
    for filepath in all_files:
        filename = os.path.basename(filepath)
        if any(pattern in filename for pattern in core_patterns):
            used_files.add(filepath)
    
    # Files in certain directories are often used indirectly
    indirect_patterns = ['/routes/', '/bindings/', '/config/']
    for filepath in all_files:
        if any(pattern in filepath for pattern in indirect_patterns):
            used_files.add(filepath)
    
    # Find potentially unused files
    unused_files = []
    for filepath in all_files:
        if filepath not in used_files:
            unused_files.append(filepath)
    
    return all_files, used_files, unused_files, file_to_classes, all_references

def print_detailed_analysis(lib_path: str):
    """Print detailed analysis results"""
    all_files, used_files, unused_files, file_to_classes, all_references = comprehensive_analysis(lib_path)
    
    print("=" * 80)
    print("COMPREHENSIVE FLUTTER DART FILE USAGE ANALYSIS")
    print("=" * 80)
    
    print(f"\n📊 SUMMARY")
    print("-" * 40)
    print(f"Total .dart files: {len(all_files)}")
    print(f"Used files: {len(used_files)}")
    print(f"Potentially unused: {len(unused_files)}")
    print(f"Usage percentage: {(len(used_files)/len(all_files)*100):.1f}%")
    
    if unused_files:
        print(f"\n🚨 POTENTIALLY UNUSED FILES ({len(unused_files)})")
        print("-" * 60)
        
        # Categorize unused files
        categories = {
            'Components': [],
            'Screens/Features': [],
            'Utils/Helpers': [],
            'Models/Services': [],
            'Themes': [],
            'Others': []
        }
        
        for filepath in sorted(unused_files):
            relative_path = os.path.relpath(filepath, lib_path).replace('\\', '/')
            
            if '/components/' in relative_path:
                categories['Components'].append(relative_path)
            elif '/features/' in relative_path or '/screens/' in relative_path:
                categories['Screens/Features'].append(relative_path)
            elif '/utils/' in relative_path or '/helpers/' in relative_path:
                categories['Utils/Helpers'].append(relative_path)
            elif '/models/' in relative_path or '/services/' in relative_path or '/data/' in relative_path:
                categories['Models/Services'].append(relative_path)
            elif '/theme/' in relative_path:
                categories['Themes'].append(relative_path)
            else:
                categories['Others'].append(relative_path)
        
        for category, files in categories.items():
            if files:
                print(f"\n{category} ({len(files)} files):")
                for file_path in sorted(files):
                    classes = []
                    full_path = os.path.join(lib_path, file_path).replace('\\', '/')
                    if full_path in file_to_classes:
                        classes = list(file_to_classes[full_path])
                    
                    class_info = f" [Classes: {', '.join(classes)}]" if classes else ""
                    print(f"  • {file_path}{class_info}")
    
    # Show verification for a few "unused" files
    print(f"\n🔍 VERIFICATION SAMPLE (first 5 unused files)")
    print("-" * 60)
    for i, filepath in enumerate(sorted(unused_files)[:5]):
        relative_path = os.path.relpath(filepath, lib_path).replace('\\', '/')
        print(f"\n{i+1}. {relative_path}")
        
        # Show what classes this file defines
        if filepath in file_to_classes and file_to_classes[filepath]:
            classes = list(file_to_classes[filepath])
            print(f"   Classes defined: {', '.join(classes)}")
            
            # Check if these classes are referenced anywhere
            for class_name in classes:
                referenced_in = []
                for ref_file, refs in all_references.items():
                    if f"class:{class_name}" in refs or class_name in str(refs):
                        referenced_in.append(os.path.relpath(ref_file, lib_path).replace('\\', '/'))
                
                if referenced_in:
                    print(f"   Class '{class_name}' might be referenced in: {', '.join(referenced_in[:3])}")
                else:
                    print(f"   Class '{class_name}' - no direct references found")

def main():
    lib_path = r"d:\backup rps\rps-stationery-main\lib"
    
    if not os.path.exists(lib_path):
        print(f"Library path not found: {lib_path}")
        return
    
    print_detailed_analysis(lib_path)

if __name__ == "__main__":
    main()