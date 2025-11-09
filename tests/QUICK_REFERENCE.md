# Quick Reference Guide

## 🚀 Common Commands

```bash
# Run all tests
./tests/run_tests.sh

# Restart with testing
./restart_all.sh

# Restart without testing (faster)
./restart_all.sh --skip-tests
```

## 📝 Add New Test (3 Steps)

```bash
# 1. Create file
nano tests/checks/09_mytest.sh

# 2. Add content
#!/usr/bin/env bash
section "TEST 9: My Test"
check_process "myprocess" "My Service"
check_port "1234" "TCP" "My Port"

# 3. Make executable
chmod +x tests/checks/09_mytest.sh
# Done! Auto-discovered on next run
```

## 🔧 Framework Functions Cheat Sheet

### Test Output
```bash
pass "Test passed"      # ✅ Green
fail "Test failed"      # ❌ Red  
warn "Warning message"  # ⚠️  Yellow
info "Info message"     # ℹ️  Blue
section "Header Text"   # Section divider
```

### Process Checks
```bash
check_process "pattern" "Name"
check_systemd_service "service-name" "Display Name"
get_cpu_usage "$PID"
get_mem_usage "$PID"
```

### Network Checks
```bash
check_port "9600" "TCP" "Game Port"
```

### File Checks
```bash
check_file "/path/to/file" "Description"
check_writable_dir "/path" "Description"
check_in_file "pattern" "/path/file" "Description"
```

### System Checks
```bash
get_disk_usage "/path"      # Returns percentage
get_disk_available "/path"  # Returns size (e.g., "59G")
count_log_errors "file.log" 100 "\[ERR\]"  # Count errors
```

## 🐛 Debugging

### Run specific test module
```bash
cd /home/acserver/server
source tests/lib/test_framework.sh
source tests/checks/01_processes.sh
```

### Check test discovery
```bash
ls -la tests/checks/*.sh
```

### Verify framework functions
```bash
source tests/lib/test_framework.sh
declare -F | grep -E "pass|fail|warn|info|check"
```

## 📂 File Structure

```
tests/
├── run_tests.sh              ← Main entry point
├── lib/test_framework.sh     ← Shared functions
└── checks/                   ← Auto-discovered tests
    ├── 01_processes.sh
    ├── 02_network.sh
    └── ...
```

## ✅ Test Result Exit Codes

- `0` = All tests passed (or passed with warnings)
- `1` = Critical tests failed

## 💡 Pro Tips

1. **Number your test files** (01_, 02_, etc.) to control execution order
2. **Keep test modules under 50 lines** for maintainability
3. **Use descriptive function names** from the framework
4. **Test locally first** before deploying
5. **Document complex checks** with comments

## 🔒 Safety

All tests are **read-only**:
- Never modify server state
- Never restart services  
- Never change configs
- Only verify and report

Perfect for production! ✨

