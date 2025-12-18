# SystemMonitor Comprehensive Audit & Debug Verification Script

## Overview

The `audit_system_monitor.sh` script is a comprehensive auditing tool designed to identify all issues in the SystemMonitor codebase and generate detailed debug reports.

## Quick Start

### Basic Audit

```bash
# Make the script executable (first time only)
chmod +x audit_system_monitor.sh

# Run the basic audit
./audit_system_monitor.sh
```

This command will:
1. Check Swift version and toolchain
2. Verify project structure
3. Validate Swift syntax
4. Check Swift 6 compatibility
5. Analyze concurrency patterns
6. Check memory safety
7. Verify imports and dependencies
8. Analyze code patterns
9. Check performance patterns
10. Perform detailed file analysis
11. Check documentation
12. Attempt to build the project
13. Run tests
14. Generate comprehensive reports

### Verbose Mode

```bash
# Get detailed output for each check
./audit_system_monitor.sh --verbose
```

This shows additional details for each validation step as it runs.

### With Fix Suggestions

```bash
# Show recommended fixes for all issues
./audit_system_monitor.sh --fix-suggestions
```

This includes detailed recommendations in the Markdown report.

### Combined Options

```bash
# Full analysis with all details and recommendations
./audit_system_monitor.sh --verbose --fix-suggestions
```

## Output Files

The script generates four types of reports:

### 1. **DEBUG_REPORT.md** (Markdown)

- **Purpose:** Human-readable comprehensive report
- **Content:**
  - Environment information
  - Build status
  - Issues organized by priority
  - File-by-file analysis
  - Recommended fixes
  - Testing information
  - Links to specific files and line numbers

- **Usage:** Open in any text editor or view on GitHub/GitLab
- **Example:** `cat DEBUG_REPORT.md` or open in VS Code

### 2. **audit_report.html** (Visual Report)

- **Purpose:** Beautiful interactive HTML report
- **Content:**
  - Color-coded issue severity
  - Summary statistics with cards
  - Environment information table
  - Interactive issue lists
  - Responsive design

- **Usage:** Open in web browser
- **Example:** `open audit_report.html` (macOS) or `xdg-open audit_report.html` (Linux)

### 3. **audit_report.json** (Machine-Readable)

- **Purpose:** Programmatic access to results
- **Content:**
  - Report metadata
  - All issues in structured format
  - Environment details
  - Summary statistics

- **Usage:** Parse with JSON tools or scripts
- **Example:** `jq . audit_report.json`

### 4. **audit_log.txt** (Detailed Log)

- **Purpose:** Complete execution log
- **Content:**
  - All checks and their results
  - Verbose output if `--verbose` flag was used
  - Raw command outputs
  - Timestamps

- **Usage:** Debugging script execution
- **Example:** `tail -f audit_log.txt`

## Issue Severity Levels

Issues are classified into four categories:

### 🔴 Critical

**Severity:** Highest  
**Action:** Must fix immediately  
**Examples:**
- Project doesn't build
- Missing required files
- Swift not installed
- Syntax errors

**How to fix:** Address in order, verify fixes with re-run

### 🟠 High

**Severity:** High  
**Action:** Should fix before release  
**Examples:**
- Build warnings
- Test failures
- Deprecated API usage
- Memory leaks

**How to fix:** Schedule for next sprint, test thoroughly

### 🟡 Medium

**Severity:** Medium  
**Action:** Consider fixing  
**Examples:**
- Code quality issues
- Actor deinit warnings
- Force unwrapping
- Performance concerns

**How to fix:** Add to backlog, refactor over time

### 🔵 Low

**Severity:** Low  
**Action:** Nice to have  
**Examples:**
- TODO/FIXME comments
- Documentation gaps
- Large files
- Force casts

**How to fix:** Consider in refactoring, document decision

## Detailed Check Descriptions

### 1. Swift Version & Toolchain

**What it checks:**
- Swift is installed and in PATH
- Swift version meets requirements (5.9+)
- Swift Package Manager is available

**Output:** Swift version information

**If it fails:**
```bash
# Install Swift
xcode-select --install
# Or download from swift.org
```

### 2. Project Structure Verification

**What it checks:**
- All required files exist
- All required directories exist
- Correct number of Swift files

**Output:** List of found/missing files and directories

**If it fails:**
- Restore missing files from git
- Verify you're in the project root

### 3. Swift Syntax Validation

**What it checks:**
- Each Swift file has valid syntax
- No parse errors

**Output:** Syntax status for each file

**If it fails:**
- Fix syntax errors in the reported files
- Use Xcode or a Swift editor for help

### 4. Swift 6 Compatibility Analysis

**What it checks:**
- Proper concurrency patterns (actors, async/await)
- Sendable conformance
- NSLock usage (should use nonisolated(unsafe))
- Thread safety patterns
- @unchecked Sendable usage

**Output:** Compatibility issues and suggestions

**If it fails:**
- See SWIFT_6_MIGRATION_GUIDE.md (included)
- Focus on Sendable conformance first

### 5. Concurrency & Thread Safety Analysis

**What it checks:**
- @MainActor usage
- DispatchQueue usage
- Actor isolation
- Task creation
- Race condition patterns

**Output:** Concurrency patterns found

### 6. Memory Safety Analysis

**What it checks:**
- Force unwrapping (!) usage
- Force casting (as!) usage
- Weak/unowned reference patterns
- Potential memory leaks
- Proper cleanup in deinit

**Output:** Memory safety assessment

### 7. Imports & Dependencies Validation

**What it checks:**
- Required imports present
- No circular dependencies
- Proper module isolation
- External dependency usage

**Output:** Import structure analysis

### 8. Code Pattern Analysis

**What it checks:**
- Error handling (try/catch, guard)
- Nil coalescing usage
- TODO/FIXME comments
- Function complexity

**Output:** Code quality metrics

### 9. Performance Pattern Analysis

**What it checks:**
- Inefficient loops
- Synchronous operations in async context
- Timer usage
- Resource allocation

**Output:** Performance concerns

### 10. File-by-File Analysis

**What it checks:**
- File size and complexity
- Function and type count
- Import dependencies
- Refactoring candidates

**Output:** Detailed metrics for each file

### 11. Documentation Analysis

**What it checks:**
- README.md exists
- Documentation comments (///)
- Inline comments

**Output:** Documentation metrics

### 12. Build Verification

**What it checks:**
- Project builds successfully
- No build errors
- Build warning count
- Build time

**Output:** Build status and issues

**If it fails:**
```bash
# Try clean build
swift package clean
swift build -c debug
```

### 13. Test Execution

**What it checks:**
- All tests pass
- No test failures
- Test coverage

**Output:** Test results

**If it fails:**
```bash
# Run tests with verbose output
swift test -v

# Run specific test
swift test --test-target SystemMonitorTests
```

## Common Issues and Solutions

### Swift Not Found

**Error:**
```
[ERROR] Swift is not installed or not in PATH
```

**Solution:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Or set PATH if Swift is installed elsewhere
export PATH="/usr/local/swift/bin:$PATH"

# Verify
swift --version
```

### Build Fails

**Error:**
```
[ERROR] Build failed
```

**Solution:**
```bash
# Clear and rebuild
rm -rf .build
swift package resolve
swift build -c debug

# Or check the detailed error
swift build -v
```

### Tests Fail

**Error:**
```
[WARN] Some tests failed
```

**Solution:**
```bash
# Run with verbose output
swift test -v

# Run specific failing test
swift test --test-target [TestName]

# Check test logs
cat audit_log.txt
```

### Permission Denied

**Error:**
```
bash: ./audit_system_monitor.sh: Permission denied
```

**Solution:**
```bash
chmod +x audit_system_monitor.sh
./audit_system_monitor.sh
```

### HTML Report Not Displaying

**Error:** Report opens but shows "No issues found" or doesn't have data

**Solution:**
```bash
# Check JSON report was created
cat audit_report.json

# Verify HTML file exists
ls -la audit_report.html

# Open in different browser
# Check browser console for errors (F12)
```

## Advanced Usage

### Using Reports Programmatically

#### Parse JSON Report

```bash
# Get all critical issues
jq '.issues.critical' audit_report.json

# Get issue count
jq '.summary.critical_issues' audit_report.json

# Export to CSV-like format
jq -r '.issues.critical[] | @csv' audit_report.json
```

#### Extract Build Errors

```bash
grep "error:" audit_log.txt | head -10
```

#### Generate Custom Report

```bash
# Create a custom script that uses the JSON output
#!/bin/bash
CRITICAL=$(jq '.summary.critical_issues' audit_report.json)
if [[ $CRITICAL -gt 0 ]]; then
    echo "CRITICAL: Found $CRITICAL critical issues!"
    exit 1
fi
```

### Integration with CI/CD

#### GitHub Actions Example

```yaml
- name: Run SystemMonitor Audit
  run: |
    chmod +x audit_system_monitor.sh
    ./audit_system_monitor.sh
    
- name: Check Critical Issues
  run: |
    CRITICAL=$(jq '.summary.critical_issues' audit_report.json)
    if [[ $CRITICAL -gt 0 ]]; then
      echo "Build failed: $CRITICAL critical issues found"
      cat DEBUG_REPORT.md
      exit 1
    fi
```

#### GitLab CI Example

```yaml
audit:
  script:
    - chmod +x audit_system_monitor.sh
    - ./audit_system_monitor.sh
  artifacts:
    paths:
      - DEBUG_REPORT.md
      - audit_report.html
      - audit_report.json
      - audit_log.txt
    reports:
      junit: test_results.xml
```

### Scheduled Audits

```bash
# Run audit daily at 2 AM
0 2 * * * cd /path/to/project && ./audit_system_monitor.sh >> /var/log/audit.log 2>&1
```

## Interpreting Results

### No Issues Found

**Meaning:** Project is in good shape!

**Next steps:**
- Commit your changes
- Merge to main branch
- Deploy with confidence

### Only Low Priority Issues

**Meaning:** Project is ready for production

**Next steps:**
- Address low priority items in backlog
- Schedule refactoring session
- Monitor for regressions

### Medium Priority Issues

**Meaning:** Project needs some fixes

**Next steps:**
1. Review each issue in DEBUG_REPORT.md
2. Fix high-impact issues first
3. Add to sprint planning
4. Re-run audit after fixes

### High or Critical Issues

**Meaning:** Project cannot be released

**Next steps:**
1. Stop deployment
2. Review DEBUG_REPORT.md in detail
3. Fix critical issues first
4. Test thoroughly
5. Re-run audit to verify
6. Consider post-mortem if issues are critical

## Performance Notes

The audit script performs comprehensive checks which may take:

- **2-3 minutes** for basic syntax and structure checks
- **5-10 minutes** including build and tests
- **10-15 minutes** with `--verbose` flag
- **15-20 minutes** with full analysis and fix suggestions

### Optimization Tips

```bash
# Skip build and tests for faster checks
# Edit audit_system_monitor.sh and comment out:
# check_build || true
# check_tests || true

# Run specific checks manually
check_swift_version
check_project_structure
```

## Troubleshooting the Script

### Script Syntax Error

**Error:**
```
audit_system_monitor.sh: line X: syntax error
```

**Solution:**
```bash
# Check script syntax
bash -n audit_system_monitor.sh

# Re-download script from repository
git checkout audit_system_monitor.sh
```

### Placeholder Not Replaced

**Error:** HTML report shows placeholder text like `REPORT_CRITICAL_PLACEHOLDER`

**Solution:**
```bash
# Manually generate reports
swift build -c debug
swift test

# Re-run audit
./audit_system_monitor.sh
```

### Log File Not Writing

**Error:**
```
Permission denied: audit_log.txt
```

**Solution:**
```bash
# Remove existing log file
rm audit_log.txt

# Re-run audit
./audit_system_monitor.sh

# Or run with sudo if permissions issue
sudo ./audit_system_monitor.sh
```

## Updating the Script

To get the latest version of the audit script:

```bash
git pull origin feat-audit-debug-verification-script
git checkout audit_system_monitor.sh
chmod +x audit_system_monitor.sh
```

## Contributing Improvements

Have suggestions for the audit script?

1. Create a GitHub issue with your suggestion
2. Include example output or error case
3. Provide proposed fix or improvement
4. Submit a pull request with changes

## License

The audit script is part of the SystemMonitor project and follows the same license.

## Support

For issues with the audit script:

1. Check this README
2. Review DEBUG_REPORT.md for details
3. Check audit_log.txt for error messages
4. Create an issue on GitHub with:
   - Output of `swift --version`
   - Contents of audit_log.txt
   - Description of the problem
   - Steps to reproduce

## Additional Resources

- [DEBUG_REPORT.md](DEBUG_REPORT.md) - Template and guide
- [Swift 6 Migration Guide](https://www.swift.org/migration/)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Memory Safety](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/memorysafety/)

---

**Version:** 1.0  
**Last Updated:** 2024  
**Maintained by:** SystemMonitor Team
