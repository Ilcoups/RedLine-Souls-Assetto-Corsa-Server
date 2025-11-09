# Production Readiness Test Suite

Modular, maintainable test framework for verifying production readiness.

## 🏗️ Architecture

```
tests/
├── run_tests.sh              # Main test runner (orchestrator)
├── lib/
│   └── test_framework.sh     # Reusable test functions
├── checks/                   # Individual test modules
│   ├── 01_processes.sh       # Process health checks
│   ├── 02_network.sh         # Network & port checks
│   ├── 03_hub.sh             # Hub integration checks
│   ├── 04_config.sh          # Configuration validation
│   ├── 05_filesystem.sh      # File system checks
│   ├── 06_logs.sh            # Log health analysis
│   ├── 07_performance.sh     # Performance metrics
│   └── 08_connectivity.sh    # Connectivity tests
└── README.md                 # This file
```

## ✨ Benefits

### Modular Design
- Each test category in its own file
- Easy to add/remove/modify specific tests
- Better organization and maintainability

### Reusable Framework
- Common functions in `lib/test_framework.sh`
- Consistent test output format
- Less code duplication

### Reliable Testing
- Proper error handling
- Safe command execution
- No false positives

### Easy Debugging
- Run individual test modules
- Clear separation of concerns
- Verbose output when needed

## 🚀 Usage

### Run All Tests
```bash
./tests/run_tests.sh
```

### Run via Restart Script (Automatic)
```bash
./restart_all.sh
```

### Skip Tests During Restart
```bash
./restart_all.sh --skip-tests
```

### Run Individual Test Module
```bash
cd /home/acserver/server
source tests/lib/test_framework.sh
source tests/checks/01_processes.sh
```

## 📝 Test Categories

### 1. Process Health (`01_processes.sh`)
- Game Server, Hub, Player Stats, Audio, Announcer
- CPU and memory usage
- Process IDs and status

### 2. Network & Ports (`02_network.sh`)
- Game port (9600)
- HTTP port (8081)
- Hub gRPC (5085)
- Hub Web (8000)
- Audio Server (8082)

### 3. Hub Integration (`03_hub.sh`)
- Server-Hub connection
- Discord bot status
- Database integrity

### 4. Configuration (`04_config.sh`)
- Environment variables
- Server configs
- Optimization verification (42Hz AI, 25Hz distant players)

### 5. File System (`05_filesystem.sh`)
- Directory permissions
- Log files
- Disk space

### 6. Log Health (`06_logs.sh`)
- Error count analysis
- Warning level checks
- Recent log health

### 7. Performance (`07_performance.sh`)
- System load
- Memory usage
- Zombie processes

### 8. Connectivity (`08_connectivity.sh`)
- Hub web interface
- DNS resolution

## 🔧 Adding New Tests

### 1. Create a New Test Module

```bash
nano tests/checks/09_mynewtest.sh
```

```bash
#!/usr/bin/env bash
# My New Test Description

section "TEST 9: My New Test Category"

# Use framework functions
check_file "path/to/file" "Description"
check_process "process_name" "Display Name"
check_port "1234" "TCP" "My Service"

# Custom logic
if [ condition ]; then
    pass "Check passed"
else
    fail "Check failed"
fi
```

### 2. Make It Executable

```bash
chmod +x tests/checks/09_mynewtest.sh
```

### 3. Test It

```bash
./tests/run_tests.sh
```

The runner automatically discovers and executes all `*.sh` files in `tests/checks/` in alphabetical order.

## 📚 Framework Functions

### Test Result Functions
- `pass "message"` - Mark test as passed (green ✅)
- `fail "message"` - Mark test as failed (red ❌)
- `warn "message"` - Mark test as warning (yellow ⚠️)
- `info "message"` - Display information (blue ℹ️)
- `section "title"` - Display section header

### Process Checks
- `check_process "pattern" "name"` - Check if process running
- `get_cpu_usage "pid"` - Get CPU usage percentage
- `get_mem_usage "pid"` - Get memory usage percentage

### Network Checks
- `check_port "port" "protocol" "description"` - Check if port listening

### File System Checks
- `check_file "path" "description"` - Check if file exists
- `check_writable_dir "path" "description"` - Check if directory writable
- `check_in_file "pattern" "file" "description"` - Check if pattern in file

### System Checks
- `check_systemd_service "name" "description"` - Check systemd service
- `get_disk_usage "path"` - Get disk usage percentage
- `get_disk_available "path"` - Get available disk space
- `count_log_errors "file" "lines" "pattern"` - Count errors in log

### Utility Functions
- `check_threshold "value" "threshold" "desc" "comparison"` - Compare values
- `safe_exec command` - Execute command safely (suppress errors)

## 🎯 Exit Codes

- `0` - All tests passed (or passed with warnings)
- `1` - One or more critical tests failed

## 🔒 Production Safety

These tests are **read-only** and **non-destructive**:
- Never modify server state
- Never restart services
- Never change configurations
- Only verify and report

Perfect for production environments!

## 📊 Example Output

```
========================================
  PRODUCTION READINESS TEST SUITE
========================================

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 1: Process Health Checks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PASS: Game Server running (PID: 12345)
ℹ️  INFO: Game Server CPU: 28.3%
ℹ️  INFO: Game Server Memory: 3.1%
✅ PASS: Hub running (PID: 12346)
...

========================================
  TEST RESULTS SUMMARY
========================================

ℹ️  INFO: Total checks: 35
  Passed:   32
  Warnings: 2
  Errors:   0

🎉 ALL TESTS PASSED!

Server is PRODUCTION READY ✅
```

## 🆚 Comparison with Old System

| Feature | Old System | New System |
|---------|-----------|------------|
| Architecture | Monolithic (377 lines) | Modular (9 files, ~20-40 lines each) |
| Maintainability | Hard to modify | Easy to extend |
| Code Reuse | Lots of duplication | Shared framework library |
| Debugging | Run all or nothing | Run individual modules |
| Adding Tests | Edit large file | Create new file |
| Total LOC | ~380 lines | ~350 lines (more features!) |

## 💡 Pro Tips

1. **Run tests after any server change** to ensure nothing broke
2. **Check individual modules** when debugging specific issues
3. **Add custom checks** for your specific monitoring needs
4. **Use in CI/CD** pipelines for automated deployment verification
5. **Monitor trends** by logging test results over time

---

**Need Help?** Check the test framework source: `tests/lib/test_framework.sh`
