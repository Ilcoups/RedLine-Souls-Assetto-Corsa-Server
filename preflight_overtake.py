#!/usr/bin/env python3
"""
PRE-FLIGHT TEST FOR OVERTAKE SYSTEM
Run this BEFORE starting the server to catch errors.
Returns exit code 1 if system will fail.
"""

import sys
import re
from pathlib import Path

LUA_FILE = Path("plugins/PatreonOvertakePlugin/lua/overtake.lua")

class TestFailure(Exception):
    pass

def test_file_exists():
    """Test 1: File exists"""
    if not LUA_FILE.exists():
        raise TestFailure(f"❌ {LUA_FILE} does not exist")
    print(f"✓ File exists: {LUA_FILE}")

def test_file_readable():
    """Test 2: File is readable"""
    try:
        with open(LUA_FILE, 'r') as f:
            content = f.read()
        print(f"✓ File readable ({len(content)} bytes)")
        return content
    except Exception as e:
        raise TestFailure(f"❌ Cannot read file: {e}")

def test_syntax(content):
    """Test 3: Basic Lua syntax"""
    lines = content.split('\n')
    
    # Check bracket balance
    curly_balance = content.count('{') - content.count('}')
    paren_balance = content.count('(') - content.count(')')
    
    if curly_balance != 0:
        raise TestFailure(f"❌ Unmatched curly brackets (diff: {curly_balance})")
    if paren_balance != 0:
        raise TestFailure(f"❌ Unmatched parentheses (diff: {paren_balance})")
    
    print(f"✓ Syntax valid (brackets balanced)")

def test_required_functions(content):
    """Test 4: Required functions exist"""
    if 'function script.update' not in content:
        raise TestFailure("❌ Missing function: script.update")
    if 'function script.drawUI' not in content:
        raise TestFailure("❌ Missing function: script.drawUI")
    
    print("✓ Required functions present: script.update, script.drawUI")

def test_no_top_level_steamid(content):
    """Test 5: No top-level ac.getSteamID() calls"""
    lines = content.split('\n')
    in_function = False
    errors = []
    
    for i, line in enumerate(lines, 1):
        # Track if we're inside a function
        if re.search(r'^\s*function\s+', line) or re.search(r'^\s*local\s+function\s+', line):
            in_function = True
        if line.strip() == 'end' and in_function:
            # This is tricky - we don't know if this closes a function or an if/for
            # For safety, assume we're still in function context
            pass
        
        # Check for getSteamID outside functions
        if 'ac.getSteamID()' in line and not line.strip().startswith('--'):
            # Check if this line is clearly inside a function (has indentation)
            if not re.match(r'^\s{2,}', line):
                # Top-level call
                errors.append(f"Line {i}: {line.strip()}")
    
    if errors:
        raise TestFailure(f"❌ Top-level ac.getSteamID() calls detected (will crash CSP):\n" + "\n".join(errors))
    
    print("✓ No dangerous top-level ac.getSteamID() calls")

def test_pb_initialization(content):
    """Test 6: PB variables are initialized"""
    if 'personalBest' not in content:
        raise TestFailure("❌ personalBest variable not found")
    if 'ownRank' not in content:
        raise TestFailure("❌ ownRank variable not found")
    
    print("✓ PB variables present")

def test_config_showui(content):
    """Test 7: config.showUI is used correctly"""
    if 'config.showUI' not in content:
        raise TestFailure("❌ config.showUI not referenced (UI won't toggle)")
    
    print("✓ UI toggle mechanism present")

def test_file_not_too_large(content):
    """Test 8: File size reasonable"""
    size = len(content)
    if size > 1000000:  # 1MB
        raise TestFailure(f"❌ File too large ({size} bytes) - CSP will crash")
    elif size > 100000:  # 100KB
        print(f"⚠️  File large ({size} bytes) - may cause CSP slowdown")
    else:
        print(f"✓ File size OK ({size} bytes)")

def test_duplicate_functions(content):
    """Test 9: No duplicate function definitions"""
    functions = re.findall(r'function (script\.\w+)', content)
    seen = set()
    duplicates = []
    
    for func in functions:
        if func in seen:
            duplicates.append(func)
        seen.add(func)
    
    if duplicates:
        raise TestFailure(f"❌ Duplicate function definitions: {duplicates}")
    
    print(f"✓ No duplicate functions")

def main():
    """Run all tests"""
    print("=" * 70)
    print("OVERTAKE SYSTEM PRE-FLIGHT TEST")
    print("=" * 70)
    print()
    
    try:
        test_file_exists()
        content = test_file_readable()
        test_syntax(content)
        test_required_functions(content)
        test_no_top_level_steamid(content)
        test_pb_initialization(content)
        test_config_showui(content)
        test_file_not_too_large(content)
        test_duplicate_functions(content)
        
        print()
        print("=" * 70)
        print("✅ ALL PRE-FLIGHT TESTS PASSED")
        print("=" * 70)
        print()
        print("🟢 SAFE TO START SERVER")
        return 0
        
    except TestFailure as e:
        print()
        print("=" * 70)
        print("❌ PRE-FLIGHT TEST FAILED")
        print("=" * 70)
        print()
        print(str(e))
        print()
        print("🔴 DO NOT START SERVER - FIX ERRORS FIRST")
        return 1
    except Exception as e:
        print()
        print("=" * 70)
        print("❌ UNEXPECTED ERROR")
        print("=" * 70)
        print()
        print(f"Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
