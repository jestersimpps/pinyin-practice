#!/usr/bin/env python3
"""
Script to add tone numbers (tn) field to flattened vocabulary JSON files
by extracting them from the original nested structure files.
"""

import json
import sys
from pathlib import Path

def extract_tone_numbers_from_original(original_file_path):
    """Extract tone numbers from original nested structure file"""
    with open(original_file_path, 'r', encoding='utf-8') as f:
        original_data = json.load(f)
    
    tone_map = {}
    
    for item in original_data:
        simplified = item['s']
        
        # Get the first form's tone numbers (usually the most common pronunciation)
        if item.get('f') and len(item['f']) > 0:
            first_form = item['f'][0]
            if 'i' in first_form and 'n' in first_form['i']:
                tone_numbers = first_form['i']['n']
                tone_map[simplified] = tone_numbers
    
    return tone_map

def add_tone_numbers_to_flattened(flattened_file_path, tone_map):
    """Add tone numbers to flattened JSON file"""
    with open(flattened_file_path, 'r', encoding='utf-8') as f:
        flattened_data = json.load(f)
    
    # Add tone numbers to each item
    for item in flattened_data:
        simplified = item['s']
        if simplified in tone_map:
            item['tn'] = tone_map[simplified]
        else:
            # Fallback: try to extract from pronunciation hint if available
            print(f"Warning: No tone numbers found for '{simplified}', skipping...")
    
    return flattened_data

def main():
    """Main function to process both HSK level files"""
    base_path = Path('/Users/jovinkenroye/Sites/pinyinpractice')
    
    # File paths
    files_to_process = [
        {
            'original': base_path / 'data' / '1.min.json',
            'flattened': base_path / 'pinyinpractice' / 'pinyinpractice' / 'Resources' / 'Data' / '1.min.json'
        },
        {
            'original': base_path / 'data' / '2.min.json', 
            'flattened': base_path / 'pinyinpractice' / 'pinyinpractice' / 'Resources' / 'Data' / '2.min.json'
        }
    ]
    
    for file_info in files_to_process:
        print(f"Processing {file_info['flattened'].name}...")
        
        # Extract tone numbers from original file
        tone_map = extract_tone_numbers_from_original(file_info['original'])
        print(f"  Extracted tone numbers for {len(tone_map)} characters")
        
        # Add tone numbers to flattened file
        updated_data = add_tone_numbers_to_flattened(file_info['flattened'], tone_map)
        
        # Write back to flattened file
        with open(file_info['flattened'], 'w', encoding='utf-8') as f:
            json.dump(updated_data, f, ensure_ascii=False, separators=(',', ':'))
        
        print(f"  Updated {file_info['flattened'].name} with tone numbers")
    
    print("\nDone! Both files now have tone numbers (tn) field added.")
    print("\nExample of added field:")
    print("  \"tn\": \"ba1\"  // for single character")
    print("  \"tn\": \"ba4 ba5\"  // for multi-character words")

if __name__ == "__main__":
    main()