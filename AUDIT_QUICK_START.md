# Audit Script - Quick Start Guide

## TL;DR - Just Run It!

```bash
./audit_system_monitor.sh
```

Three files will be generated:
- 📄 **DEBUG_REPORT.md** - Read this first!
- 🌐 **audit_report.html** - Open in browser
- 📝 **audit_log.txt** - Detailed log

## Command Cheat Sheet

| Command | Purpose |
|---------|---------|
| `./audit_system_monitor.sh` | Basic audit |
| `./audit_system_monitor.sh --verbose` | Detailed output |
| `./audit_system_monitor.sh --fix-suggestions` | Show fixes |
| `./audit_system_monitor.sh --verbose --fix-suggestions` | Everything |

## What Gets Checked

✅ Swift installation  
✅ Project structure  
✅ Code syntax  
✅ Swift 6 compatibility  
✅ Concurrency patterns  
✅ Memory safety  
✅ Dependencies  
✅ Code quality  
✅ Performance  
✅ Build success  
✅ Tests pass  

## Understanding Results

| Severity | Count | Action |
|----------|-------|--------|
| 🔴 Critical | 0+ | Fix immediately |
| 🟠 High | 0+ | Fix soon |
| 🟡 Medium | 0+ | Fix eventually |
| 🔵 Low | 0+ | Nice to fix |

## Troubleshooting

### Script won't run
```bash
chmod +x audit_system_monitor.sh
```

### Swift not found
```bash
xcode-select --install
```

### Permission denied on reports
```bash
ls -la audit_report.html
# Should see -rw-r--r-- permissions
```

### HTML report has no data
- Open `audit_report.json` to check format
- Try regenerating: `rm audit_report.html && ./audit_system_monitor.sh`

## Next Steps After Running

1. **Read** `DEBUG_REPORT.md`
2. **Check** `audit_report.html` in browser
3. **Fix** any critical or high issues
4. **Re-run** audit to verify: `./audit_system_monitor.sh`
5. **Commit** when all checks pass

## Output Files Explained

| File | Type | Open With |
|------|------|-----------|
| DEBUG_REPORT.md | Markdown | Any text editor or GitHub |
| audit_report.html | HTML | Web browser |
| audit_report.json | JSON | Text editor or `jq` |
| audit_log.txt | Text | `tail -f audit_log.txt` |

## Common Issues & Quick Fixes

### Build fails
```bash
rm -rf .build
swift build -c debug
```

### Tests fail
```bash
swift test -v
```

### Too much output (verbose mode)
```bash
./audit_system_monitor.sh 2>&1 | grep ERROR
```

## Full Documentation

See `AUDIT_SCRIPT_README.md` for complete documentation.

---

**Pro Tip:** Add this to your pre-commit hook:
```bash
./audit_system_monitor.sh && \
jq '.summary.critical_issues' audit_report.json | \
grep -q '0' && echo "✅ Audit passed"
```
