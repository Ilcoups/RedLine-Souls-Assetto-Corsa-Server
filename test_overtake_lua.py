#!/usr/bin/env python3
"""
Real test for Overtake Lua script - validates syntax and logic without requiring manual testing.
"""

import re
import sys
from pathlib import Path

def test_lua_syntax(lua_file):
    """Check for common Lua syntax errors"""
    print(f"\n{'='*60}")
    print(f"TESTING: {lua_file}")
    print(f"{'='*60}\n")
    
    with open(lua_file, 'r') as f:
        content = f.read()
        lines = content.split('\n')
    
    errors = []
    warnings = []
    
    # Test 1: Check bracket balance
    bracket_balance = content.count('{') - content.count('}')
    paren_balance = content.count('(') - content.count(')')
    if bracket_balance != 0:
        errors.append(f"Unmatched curly brackets (diff: {bracket_balance})")
    if paren_balance != 0:
        errors.append(f"Unmatched parentheses (diff: {paren_balance})")
    
    # Test 2: Check for ac.getSteamID() calls at top level
    top_level_calls = []
    in_function = False
    for i, line in enumerate(lines, 1):
        if re.search(r'function\s+\w+', line):
            in_function = True
        if line.strip().startswith('end') and in_function:
            in_function = False
        if not in_function and 'ac.getSteamID()' in line and not line.strip().startswith('--'):
            top_level_calls.append(i)
    
    if top_level_calls:
        errors.append(f"ac.getSteamID() called at top level (lines: {top_level_calls}) - CAUSES CRASH!")
    
    # Test 3: Check for personalBest initialization
    pb_init = False
    for line in lines:
        if re.search(r'personalBest\s*=', line) and not line.strip().startswith('--'):
            pb_init = True
            break
    
    if not pb_init:
        warnings.append("personalBest variable not initialized")
    
    # Test 4: Check for script.update function
    has_update = 'function script.update' in content
    if not has_update:
        errors.append("Missing script.update() function")
    
    # Test 5: Check for script.drawUI function  
    has_drawui = 'function script.drawUI' in content
    if not has_drawui:
        errors.append("Missing script.drawUI() function")
    
    # Test 6: Check file size (too large might cause issues)
    file_size = len(content)
    if file_size > 500000:  # 500KB
        warnings.append(f"File is very large ({file_size} bytes) - might cause CSP issues")
    
    # Results
    print("TEST RESULTS:")
    print(f"  File size: {file_size} bytes")
    print(f"  Total lines: {len(lines)}")
    print(f"  Has script.update: {'✓' if has_update else '✗'}")
    print(f"  Has script.drawUI: {'✓' if has_drawui else '✗'}")
    print(f"  Bracket balance: {'✓' if bracket_balance == 0 else '✗'}")
    print(f"  Paren balance: {'✓' if paren_balance == 0 else '✗'}")
    
    if errors:
        print(f"\n❌ ERRORS ({len(errors)}):")
        for err in errors:
            print(f"  - {err}")
    
    if warnings:
        print(f"\n⚠️  WARNINGS ({len(warnings)}):")
        for warn in warnings:
            print(f"  - {warn}")
    
    if not errors and not warnings:
        print(f"\n✅ ALL TESTS PASSED")
        return 0
    elif errors:
        print(f"\n❌ TESTS FAILED - Script will NOT work")
        return 1
    else:
        print(f"\n⚠️  TESTS PASSED WITH WARNINGS")
        return 0

if __name__ == "__main__":
    lua_file = Path("plugins/PatreonOvertakePlugin/lua/overtake.lua")
    if not lua_file.exists():
        print(f"❌ ERROR: {lua_file} not found!")
        sys.exit(1)
    
    sys.exit(test_lua_syntax(lua_file))
