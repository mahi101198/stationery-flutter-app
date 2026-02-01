#!/usr/bin/env python3
"""
Flutter Dart File Usage Analyzer
Analyzes all .dart files in the lib directory to find unused files.
"""
import os
import re
import sys
from typing import Dict, List, Set, Tuple
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

def extract_imports_from_file(filepath: str) -> Set[str]:
    """Extract all import statements from a dart file"""
    imports = set()
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Find all import statements
        # Match: import 'path'; or import "path"; or import 'package:app/path';
        import_pattern = r"import\s+['\"]([^'\"]+)['\"]"
        export_pattern = r"export\s+['\"]([^'\"]+)['\"]"
        part_pattern = r"part\s+['\"]([^'\"]+)['\"]"
        
        for match in re.finditer(import_pattern, content, re.MULTILINE):
            imports.add(match.group(1))
        for match in re.finditer(export_pattern, content, re.MULTILINE):
            imports.add(match.group(1))
        for match in re.finditer(part_pattern, content, re.MULTILINE):
            imports.add(match.group(1))
            
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
    
    return imports

def normalize_import_path(import_path: str, base_lib_path: str) -> str:
    """Convert import path to absolute file path"""
    # Handle package imports
    if import_path.startswith('package:rps_stationery/'):
        # Remove package prefix and add lib path
        relative_path = import_path[len('package:rps_stationery/'):]
        return os.path.join(base_lib_path, relative_path).replace('\\', '/')
    
    # Handle relative imports
    elif import_path.startswith('./') or import_path.startswith('../') or not import_path.startswith('package:'):
        # For relative imports, we'd need the context of the importing file
        # For now, just return as is
        return import_path
    
    # Skip dart: and other package: imports
    return None

def analyze_file_usage(lib_path: str) -> Tuple[Dict[str, Set[str]], List[str]]:
    """Analyze which files are imported by which files"""
    all_files = get_all_dart_files(lib_path)
    file_imports = {}  # file -> set of files it imports
    imported_by = {}   # file -> set of files that import it
    
    print(f"Found {len(all_files)} .dart files")
    
    for filepath in all_files:
        imports = extract_imports_from_file(filepath)
        file_imports[filepath] = set()
        
        for import_path in imports:
            # Skip external packages
            if import_path.startswith('dart:') or (import_path.startswith('package:') and not import_path.startswith('package:rps_stationery/')):
                continue
                
            # Convert to absolute path
            abs_import_path = normalize_import_path(import_path, lib_path)
            if abs_import_path:
                if not abs_import_path.endswith('.dart'):
                    abs_import_path += '.dart'
                    
                if abs_import_path in all_files:
                    file_imports[filepath].add(abs_import_path)
                    if abs_import_path not in imported_by:
                        imported_by[abs_import_path] = set()
                    imported_by[abs_import_path].add(filepath)
    
    return file_imports, all_files, imported_by

def find_unused_files(file_imports: Dict[str, Set[str]], all_files: List[str], imported_by: Dict[str, Set[str]], lib_path: str) -> List[str]:
    """Find files that are not imported by any other file"""
    # Core files that should never be removed
    core_files = {
        'main.dart',
        'app.dart', 
        'firebase_options.dart',
        'constants.dart'
    }
    
    unused_files = []
    
    for filepath in all_files:
        filename = os.path.basename(filepath)
        relative_path = os.path.relpath(filepath, lib_path).replace('\\', '/')
        
        # Skip core files
        if filename in core_files:
            continue
            
        # Skip if it's in routes or bindings (these are usually referenced indirectly)
        if '/routes/' in relative_path or '/bindings/' in relative_path:
            continue
            
        # Check if file is imported by any other file
        if filepath not in imported_by or len(imported_by[filepath]) == 0:
            unused_files.append(filepath)
    
    return unused_files

def main():
    lib_path = r"d:\backup rps\rps-stationery-main\lib"
    
    if not os.path.exists(lib_path):
        print(f"Library path not found: {lib_path}")
        return
    
    print("Analyzing Flutter project for unused .dart files...")
    print("=" * 60)
    
    file_imports, all_files, imported_by = analyze_file_usage(lib_path)
    unused_files = find_unused_files(file_imports, all_files, imported_by, lib_path)
    
    print(f"\n📊 ANALYSIS SUMMARY")
    print("=" * 60)
    print(f"Total .dart files found: {len(all_files)}")
    print(f"Files that import others: {len([f for f in file_imports if file_imports[f]])}")
    print(f"Files imported by others: {len(imported_by)}")
    print(f"Potentially unused files: {len(unused_files)}")
    
    if unused_files:
        print(f"\n🚨 POTENTIALLY UNUSED FILES ({len(unused_files)})")
        print("=" * 60)
        for filepath in sorted(unused_files):
            relative_path = os.path.relpath(filepath, lib_path).replace('\\', '/')
            print(f"  • {relative_path}")
    
    # Show some usage statistics
    print(f"\n📈 MOST IMPORTED FILES")
    print("=" * 60)
    most_imported = sorted(imported_by.items(), key=lambda x: len(x[1]), reverse=True)[:10]
    for filepath, importers in most_imported:
        relative_path = os.path.relpath(filepath, lib_path).replace('\\', '/')
        print(f"  • {relative_path} (imported by {len(importers)} files)")
    
    return unused_files

if __name__ == "__main__":
    main()