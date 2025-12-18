#!/bin/bash

#################################################################################
# SystemMonitor Comprehensive Audit & Debug Verification Script
# Purpose: Identify all issues and generate detailed debug reports
# Usage:   ./audit_system_monitor.sh [--verbose] [--fix-suggestions]
#################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Output files
AUDIT_LOG="audit_log.txt"
DEBUG_REPORT="DEBUG_REPORT.md"
HTML_REPORT="audit_report.html"
JSON_REPORT="audit_report.json"

# Tracking variables
VERBOSE=false
SHOW_FIX_SUGGESTIONS=false
ERROR_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0
CRITICAL_ISSUES=()
HIGH_ISSUES=()
MEDIUM_ISSUES=()
LOW_ISSUES=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --fix-suggestions)
            SHOW_FIX_SUGGESTIONS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

#################################################################################
# Utility Functions
#################################################################################

log_info() {
    local msg="$1"
    echo -e "${GREEN}[INFO]${NC} $msg"
    echo "[INFO] $msg" >> "$AUDIT_LOG"
    ((INFO_COUNT++))
}

log_warning() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} $msg"
    echo "[WARN] $msg" >> "$AUDIT_LOG"
    ((WARNING_COUNT++))
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg"
    echo "[ERROR] $msg" >> "$AUDIT_LOG"
    ((ERROR_COUNT++))
}

log_section() {
    local section="$1"
    echo -e "\n${CYAN}=== $section ===${NC}"
    echo "" >> "$AUDIT_LOG"
    echo "=== $section ===" >> "$AUDIT_LOG"
}

log_verbose() {
    local msg="$1"
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $msg"
    fi
    echo "[VERBOSE] $msg" >> "$AUDIT_LOG"
}

add_critical_issue() {
    local title="$1"
    local description="$2"
    local file="${3:-}"
    local line="${4:-}"
    CRITICAL_ISSUES+=("$title|$description|$file|$line")
}

add_high_issue() {
    local title="$1"
    local description="$2"
    local file="${3:-}"
    local line="${4:-}"
    HIGH_ISSUES+=("$title|$description|$file|$line")
}

add_medium_issue() {
    local title="$1"
    local description="$2"
    local file="${3:-}"
    local line="${4:-}"
    MEDIUM_ISSUES+=("$title|$description|$file|$line")
}

add_low_issue() {
    local title="$1"
    local description="$2"
    local file="${3:-}"
    local line="${4:-}"
    LOW_ISSUES+=("$title|$description|$file|$line")
}

#################################################################################
# Check Functions
#################################################################################

check_swift_version() {
    log_section "Swift Version & Toolchain"
    
    # Check if Swift is installed
    if ! command -v swift &> /dev/null; then
        log_error "Swift is not installed or not in PATH"
        add_critical_issue "Swift Not Found" "Swift compiler not available in PATH" "" ""
        return 1
    fi
    
    local swift_version=$(swift --version)
    log_info "Swift version: $swift_version"
    
    # Check for Swift 5.9+
    local version_number=$(echo "$swift_version" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    log_info "Version number: $version_number"
    
    # Check SwiftPM
    if ! command -v swift package &> /dev/null; then
        log_error "Swift Package Manager not available"
        add_high_issue "SwiftPM Missing" "Swift Package Manager not properly installed" "" ""
        return 1
    fi
    
    log_info "Swift Package Manager available"
    return 0
}

check_project_structure() {
    log_section "Project Structure Verification"
    
    local required_files=(
        "Package.swift"
        "Sources/Core/SystemMonitorCore.swift"
        "Sources/App/SystemMonitorApp.swift"
        "Sources/App/AppDelegate.swift"
    )
    
    local required_dirs=(
        "Sources/Core/Models"
        "Sources/Core/Services"
        "Sources/Core/Utils"
        "Sources/App/Views"
        "Sources/App/ViewModels"
        "Tests"
    )
    
    # Check required files
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "✓ Found: $file"
        else
            log_error "✗ Missing: $file"
            add_critical_issue "Missing File" "Required file not found: $file" "$file" ""
        fi
    done
    
    # Check required directories
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "✓ Found: $dir"
        else
            log_error "✗ Missing: $dir"
            add_high_issue "Missing Directory" "Required directory not found: $dir" "$dir" ""
        fi
    done
    
    # Count source files
    local swift_files=$(find Sources -name "*.swift" | wc -l)
    log_info "Found $swift_files Swift source files"
    
    local test_files=$(find Tests -name "*.swift" 2>/dev/null | wc -l)
    log_info "Found $test_files Swift test files"
}

check_swift_syntax() {
    log_section "Swift Syntax Validation"
    
    local swift_files=$(find Sources -name "*.swift" -type f)
    local syntax_errors=0
    
    for file in $swift_files; do
        # Try to compile just this file to check syntax
        if ! swift -parse "$file" &>/dev/null; then
            log_error "Syntax error in: $file"
            add_high_issue "Swift Syntax Error" "File has syntax errors" "$file" ""
            ((syntax_errors++))
        else
            log_verbose "✓ Syntax OK: $file"
        fi
    done
    
    if [[ $syntax_errors -eq 0 ]]; then
        log_info "All Swift files have valid syntax"
    else
        log_warning "Found $syntax_errors file(s) with syntax errors"
    fi
}

check_swift6_compatibility() {
    log_section "Swift 6 Compatibility Analysis"
    
    log_info "Checking for common Swift 6 issues..."
    
    # Check for usage patterns that might cause issues
    local pattern_count=0
    
    # Check for NSLock usage (should use nonisolated(unsafe))
    if grep -r "NSLock" Sources/ --include="*.swift" 2>/dev/null | grep -v "nonisolated(unsafe)"; then
        log_warning "Found NSLock usage - may need conversion to nonisolated(unsafe)"
        ((pattern_count++))
    fi
    
    # Check for @unchecked Sendable without justification
    if grep -r "@unchecked Sendable" Sources/ --include="*.swift" 2>/dev/null; then
        log_warning "Found @unchecked Sendable - verify thread safety"
        ((pattern_count++))
    fi
    
    # Check for actors with deinit
    local actor_files=$(grep -r "actor " Sources/ --include="*.swift" | cut -d: -f1 | sort -u)
    for file in $actor_files; do
        if grep -q "deinit" "$file"; then
            log_warning "Actor has deinit - may cause concurrency issues: $file"
            add_medium_issue "Actor Deinit" "Actor with deinit may have concurrency issues" "$file" ""
            ((pattern_count++))
        fi
    done
    
    # Check for DispatchQueue usage
    if grep -r "DispatchQueue\|dispatch_async\|dispatch_sync" Sources/ --include="*.swift" 2>/dev/null | grep -v "DispatchQueue.main.async"; then
        log_info "Found DispatchQueue usage - verify proper thread safety"
    fi
    
    # Check for nonisolated(unsafe) usage
    local unsafe_count=$(grep -r "nonisolated(unsafe)" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Found $unsafe_count nonisolated(unsafe) declarations"
    
    # Check for missing Sendable conformance in published models
    local published_files=$(grep -r "@Published" Sources/ --include="*.swift" 2>/dev/null | cut -d: -f1 | sort -u)
    for file in $published_files; do
        if ! grep -q "Sendable" "$file"; then
            log_warning "@Published properties may need Sendable conformance: $file"
            add_medium_issue "@Published Without Sendable" "Published properties should conform to Sendable" "$file" ""
        fi
    done
    
    log_info "Swift 6 compatibility check complete"
}

check_concurrency_patterns() {
    log_section "Concurrency & Thread Safety Analysis"
    
    # Check for proper @MainActor usage
    local main_thread_ui_files=$(grep -r "@State\|@Published\|View" Sources/ --include="*.swift" | cut -d: -f1 | sort -u)
    log_info "Checking ${#main_thread_ui_files[@]} UI-related files..."
    
    # Check for manual DispatchQueue.main usage
    local manual_dispatch=$(grep -r "DispatchQueue.main.async" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Found $manual_dispatch manual main thread dispatches"
    
    if [[ $manual_dispatch -gt 0 ]]; then
        log_info "Manual main thread dispatches detected - verifying proper usage"
        # This is expected in this codebase based on memory
    fi
    
    # Check for proper actor isolation
    local actor_count=$(grep -r "actor " Sources/ --include="*.swift" | wc -l)
    log_info "Found $actor_count actor declarations"
    
    # Check for task creation
    local task_count=$(grep -r "Task\|async let" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Found $task_count Task/async declarations"
}

check_memory_safety() {
    log_section "Memory Safety Analysis"
    
    # Check for force unwrapping
    local force_unwraps=$(grep -r "!{1}" Sources/ --include="*.swift" 2>/dev/null | grep -v "// " | wc -l)
    if [[ $force_unwraps -gt 5 ]]; then
        log_warning "Found $force_unwraps force unwraps - verify safety"
        add_low_issue "Force Unwraps" "Multiple force unwraps detected" "Multiple files" ""
    else
        log_info "Force unwraps: $force_unwraps (acceptable)"
    fi
    
    # Check for force casts
    local force_casts=$(grep -r " as! " Sources/ --include="*.swift" 2>/dev/null | wc -l)
    if [[ $force_casts -gt 3 ]]; then
        log_warning "Found $force_casts force casts - verify safety"
        add_low_issue "Force Casts" "Multiple force casts detected" "Multiple files" ""
    else
        log_info "Force casts: $force_casts (acceptable)"
    fi
    
    # Check for memory leaks patterns
    local retain_cycle_patterns=$(grep -r "\[weak\|unowned" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Found $retain_cycle_patterns weak/unowned references"
    
    # Check for proper cleanup
    local deinit_count=$(grep -r "deinit" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Found $deinit_count deinit implementations"
}

check_imports_and_dependencies() {
    log_section "Imports & Dependencies Validation"
    
    # Check for missing Foundation imports
    local foundation_usage=$(grep -r "Foundation" Sources/ --include="*.swift" | wc -l)
    log_info "Foundation imports: $foundation_usage references"
    
    # Check for Darwin API usage
    local darwin_usage=$(grep -r "Darwin\|Libc\|import Darwin" Sources/ --include="*.swift" | wc -l)
    log_info "Darwin/Libc imports: $darwin_usage references"
    
    # Check for SwiftUI imports in app target
    local swiftui_usage=$(grep -r "SwiftUI\|import SwiftUI" Sources/App/ --include="*.swift" | wc -l)
    log_info "SwiftUI imports in App: $swiftui_usage references"
    
    # Check for circular dependencies
    log_info "Checking for circular dependencies..."
    # This is hard to automate, so we'll check the structure
    
    # Verify Core doesn't import from App
    if grep -r "import SystemMonitor\|from App" Sources/Core/ --include="*.swift" 2>/dev/null; then
        log_error "Core module imports from App (circular dependency)"
        add_critical_issue "Circular Dependency" "Core module imports from App" "Sources/Core" ""
    else
        log_info "✓ No circular dependencies detected (Core → App)"
    fi
}

check_build() {
    log_section "Build Verification"
    
    log_info "Attempting to build project..."
    
    # Clean build artifacts first
    if [[ -d ".build" ]]; then
        log_verbose "Cleaning .build directory..."
        rm -rf ".build"
    fi
    
    # Attempt build with captured output
    local build_output_file=".build_output.txt"
    local build_success=true
    
    if swift build -c debug 2>&1 | tee "$build_output_file"; then
        log_info "✓ Build successful"
    else
        log_error "Build failed"
        build_success=false
        add_critical_issue "Build Failed" "Project does not build successfully" "" ""
    fi
    
    # Parse build output for warnings
    local warnings=$(grep -i "warning:" "$build_output_file" | wc -l)
    if [[ $warnings -gt 0 ]]; then
        log_warning "Found $warnings build warning(s)"
        echo "=== Build Warnings ===" >> "$AUDIT_LOG"
        grep -i "warning:" "$build_output_file" >> "$AUDIT_LOG"
        # Try to categorize
        grep -i "warning:" "$build_output_file" | head -5 | while read -r warning; do
            add_medium_issue "Build Warning" "$warning" "" ""
        done
    fi
    
    # Parse build output for errors
    local errors=$(grep -i "error:" "$build_output_file" | wc -l)
    if [[ $errors -gt 0 ]]; then
        log_error "Found $errors build error(s)"
        echo "=== Build Errors ===" >> "$AUDIT_LOG"
        grep -i "error:" "$build_output_file" >> "$AUDIT_LOG"
        grep -i "error:" "$build_output_file" | head -5 | while read -r error; do
            add_high_issue "Build Error" "$error" "" ""
        done
    fi
    
    # Cleanup
    rm -f "$build_output_file"
    
    return $([ "$build_success" = true ] && echo 0 || echo 1)
}

check_tests() {
    log_section "Test Execution"
    
    log_info "Running tests..."
    
    local test_output_file=".test_output.txt"
    local test_success=true
    
    if swift test 2>&1 | tee "$test_output_file"; then
        log_info "✓ All tests passed"
    else
        log_warning "Some tests failed"
        test_success=false
        add_medium_issue "Test Failure" "Some tests did not pass" "" ""
    fi
    
    # Parse test results
    local passed_tests=$(grep -c "passed" "$test_output_file" 2>/dev/null || echo 0)
    local failed_tests=$(grep -c "failed" "$test_output_file" 2>/dev/null || echo 0)
    
    log_info "Test results: $passed_tests passed, $failed_tests failed"
    
    rm -f "$test_output_file"
    
    return $([ "$test_success" = true ] && echo 0 || echo 1)
}

check_code_patterns() {
    log_section "Code Pattern Analysis"
    
    # Check for proper error handling
    local try_count=$(grep -r "try\|do {" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Error handling: $try_count try/do blocks"
    
    # Check for guard statements
    local guard_count=$(grep -r "^[[:space:]]*guard " Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Guard statements: $guard_count"
    
    # Check for proper nil coalescing
    local nil_coal=$(grep -r " ?? " Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Nil coalescing operators: $nil_coal"
    
    # Check for TODO/FIXME comments
    local todos=$(grep -r "TODO\|FIXME" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    if [[ $todos -gt 0 ]]; then
        log_warning "Found $todos TODO/FIXME comments"
        add_low_issue "TODO/FIXME Comments" "Code contains TODO/FIXME comments" "Multiple files" ""
    fi
    
    # Check code complexity (simple heuristic)
    log_info "Checking function complexity..."
    local large_functions=$(grep -r "^[[:space:]]*func " Sources/ --include="*.swift" -A 20 | grep -c "^--$" | head -10)
    log_info "Large functions detected: $large_functions"
}

check_performance_patterns() {
    log_section "Performance Pattern Analysis"
    
    log_info "Checking for performance issues..."
    
    # Check for inefficient loops
    local nested_loops=$(grep -r "for.*for\|while.*while" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    if [[ $nested_loops -gt 2 ]]; then
        log_warning "Found nested loops that might impact performance: $nested_loops"
        add_low_issue "Nested Loops" "Multiple nested loops may impact performance" "Multiple files" ""
    fi
    
    # Check for synchronous I/O in main code
    local sync_operations=$(grep -r "synchronous\|blocking" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Potential synchronous operations: $sync_operations"
    
    # Check for Timer/DispatchSourceTimer usage
    local timer_usage=$(grep -r "Timer\|DispatchSourceTimer" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Timer usage: $timer_usage"
}

check_file_analysis() {
    log_section "Detailed File Analysis"
    
    local swift_files=$(find Sources -name "*.swift" -type f | sort)
    
    echo "File-by-file compilation check:" >> "$AUDIT_LOG"
    
    for file in $swift_files; do
        log_verbose "Analyzing: $file"
        
        # Get file size
        local size=$(wc -l < "$file")
        
        # Count functions
        local func_count=$(grep -c "^[[:space:]]*func " "$file" || echo 0)
        
        # Count classes/structs
        local class_count=$(grep -c "^[[:space:]]*\(class\|struct\|enum\|actor\) " "$file" || echo 0)
        
        # Count imports
        local import_count=$(grep -c "^import " "$file" || echo 0)
        
        echo "$file: $size lines, $func_count functions, $class_count types, $import_count imports" >> "$AUDIT_LOG"
        
        # Check for extremely large files
        if [[ $size -gt 500 ]]; then
            log_warning "Large file: $file ($size lines) - consider refactoring"
            add_low_issue "Large File" "File is quite large and may benefit from refactoring" "$file" ""
        fi
    done
}

check_documentation() {
    log_section "Documentation Analysis"
    
    log_info "Checking for documentation..."
    
    # Check for README
    if [[ -f "README.md" ]]; then
        log_info "✓ README.md present"
    else
        log_warning "README.md not found"
        add_low_issue "Missing README" "Project README.md not found" "" ""
    fi
    
    # Check for doc comments
    local doc_comments=$(grep -r "///" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Found $doc_comments documentation comments"
    
    # Check for inline comments
    local comments=$(grep -r "^[[:space:]]*//[^/]" Sources/ --include="*.swift" 2>/dev/null | wc -l)
    log_info "Found $comments inline comments"
}

#################################################################################
# Report Generation
#################################################################################

generate_markdown_report() {
    log_info "Generating Markdown report..."
    
    cat > "$DEBUG_REPORT" << 'EOF'
# SystemMonitor Debug & Audit Report

**Report Generated:** $(date)

## Table of Contents
1. [Environment Information](#environment-information)
2. [Build Status](#build-status)
3. [Issues Summary](#issues-summary)
4. [Critical Issues](#critical-issues)
5. [High Priority Issues](#high-priority-issues)
6. [Medium Priority Issues](#medium-priority-issues)
7. [Low Priority Issues](#low-priority-issues)
8. [Recommended Fixes](#recommended-fixes)

## Environment Information

EOF

    # Add environment info
    {
        echo "### System Information"
        echo "- **Architecture:** $(uname -m)"
        echo "- **OS Version:** $(sw_vers -productVersion || uname -a)"
        echo "- **Swift Version:** $(swift --version)"
        echo "- **Swift Path:** $(which swift)"
        echo ""
        echo "### Project Information"
        echo "- **Project Root:** $(pwd)"
        echo "- **Swift Source Files:** $(find Sources -name "*.swift" -type f | wc -l)"
        echo "- **Test Files:** $(find Tests -name "*.swift" -type f | wc -l)"
        echo "- **Total Lines of Code:** $(find Sources -name "*.swift" -type f -exec wc -l {} + | tail -1 | awk '{print $1}')"
    } >> "$DEBUG_REPORT"
    
    # Add summary statistics
    {
        echo ""
        echo "## Issues Summary"
        echo ""
        echo "| Severity | Count |"
        echo "|----------|-------|"
        echo "| Critical | ${#CRITICAL_ISSUES[@]} |"
        echo "| High | ${#HIGH_ISSUES[@]} |"
        echo "| Medium | ${#MEDIUM_ISSUES[@]} |"
        echo "| Low | ${#LOW_ISSUES[@]} |"
        echo "| **Total** | **$((ERROR_COUNT + WARNING_COUNT))** |"
        echo ""
    } >> "$DEBUG_REPORT"
    
    # Add critical issues
    {
        echo "## Critical Issues"
        echo ""
        if [[ ${#CRITICAL_ISSUES[@]} -eq 0 ]]; then
            echo "✓ No critical issues found"
        else
            for issue in "${CRITICAL_ISSUES[@]}"; do
                IFS='|' read -r title desc file line <<< "$issue"
                echo "### $title"
                echo "**Description:** $desc"
                if [[ -n "$file" && "$file" != "" ]]; then
                    echo "**File:** \`$file\`"
                fi
                if [[ -n "$line" && "$line" != "" ]]; then
                    echo "**Line:** $line"
                fi
                echo ""
            done
        fi
        echo ""
    } >> "$DEBUG_REPORT"
    
    # Add high priority issues
    {
        echo "## High Priority Issues"
        echo ""
        if [[ ${#HIGH_ISSUES[@]} -eq 0 ]]; then
            echo "✓ No high priority issues found"
        else
            for issue in "${HIGH_ISSUES[@]}"; do
                IFS='|' read -r title desc file line <<< "$issue"
                echo "### $title"
                echo "**Description:** $desc"
                if [[ -n "$file" && "$file" != "" ]]; then
                    echo "**File:** \`$file\`"
                fi
                if [[ -n "$line" && "$line" != "" ]]; then
                    echo "**Line:** $line"
                fi
                echo ""
            done
        fi
        echo ""
    } >> "$DEBUG_REPORT"
    
    # Add medium priority issues
    {
        echo "## Medium Priority Issues"
        echo ""
        if [[ ${#MEDIUM_ISSUES[@]} -eq 0 ]]; then
            echo "✓ No medium priority issues found"
        else
            for issue in "${MEDIUM_ISSUES[@]}"; do
                IFS='|' read -r title desc file line <<< "$issue"
                echo "### $title"
                echo "**Description:** $desc"
                if [[ -n "$file" && "$file" != "" ]]; then
                    echo "**File:** \`$file\`"
                fi
                if [[ -n "$line" && "$line" != "" ]]; then
                    echo "**Line:** $line"
                fi
                echo ""
            done
        fi
        echo ""
    } >> "$DEBUG_REPORT"
    
    # Add low priority issues
    {
        echo "## Low Priority Issues"
        echo ""
        if [[ ${#LOW_ISSUES[@]} -eq 0 ]]; then
            echo "✓ No low priority issues found"
        else
            for issue in "${LOW_ISSUES[@]}"; do
                IFS='|' read -r title desc file line <<< "$issue"
                echo "### $title"
                echo "**Description:** $desc"
                if [[ -n "$file" && "$file" != "" ]]; then
                    echo "**File:** \`$file\`"
                fi
                if [[ -n "$line" && "$line" != "" ]]; then
                    echo "**Line:** $line"
                fi
                echo ""
            done
        fi
        echo ""
    } >> "$DEBUG_REPORT"
    
    # Add recommendations
    if [[ "$SHOW_FIX_SUGGESTIONS" == true ]]; then
        {
            echo "## Recommended Fixes"
            echo ""
            echo "### General Recommendations"
            echo ""
            echo "1. **Enable Swift Strict Concurrency Mode**"
            echo "   - Add \`-strict-concurrency=complete\` to build settings"
            echo "   - This will catch more concurrency issues at compile time"
            echo ""
            echo "2. **Run Swift Format**"
            echo "   \`\`\`bash"
            echo "   swift format -i -r Sources/"
            echo "   \`\`\`"
            echo ""
            echo "3. **Enable All Warnings**"
            echo "   - Use \`-Weverything\` flag in build settings"
            echo ""
            echo "4. **Code Review**"
            echo "   - Review all flagged issues before production release"
            echo ""
        } >> "$DEBUG_REPORT"
    fi
    
    log_info "Markdown report generated: $DEBUG_REPORT"
}

generate_json_report() {
    log_info "Generating JSON report..."
    
    # Build JSON arrays for issues
    local critical_json="[]"
    local high_json="[]"
    local medium_json="[]"
    local low_json="[]"
    
    if [[ ${#CRITICAL_ISSUES[@]} -gt 0 ]]; then
        local items=()
        for issue in "${CRITICAL_ISSUES[@]}"; do
            items+=("\"$issue\"")
        done
        critical_json="[$(IFS=,; echo "${items[*]}")]"
    fi
    
    if [[ ${#HIGH_ISSUES[@]} -gt 0 ]]; then
        local items=()
        for issue in "${HIGH_ISSUES[@]}"; do
            items+=("\"$issue\"")
        done
        high_json="[$(IFS=,; echo "${items[*]}")]"
    fi
    
    if [[ ${#MEDIUM_ISSUES[@]} -gt 0 ]]; then
        local items=()
        for issue in "${MEDIUM_ISSUES[@]}"; do
            items+=("\"$issue\"")
        done
        medium_json="[$(IFS=,; echo "${items[*]}")]"
    fi
    
    if [[ ${#LOW_ISSUES[@]} -gt 0 ]]; then
        local items=()
        for issue in "${LOW_ISSUES[@]}"; do
            items+=("\"$issue\"")
        done
        low_json="[$(IFS=,; echo "${items[*]}")]"
    fi
    
    cat > "$JSON_REPORT" << EOF
{
  "report_generated": "$(date)",
  "summary": {
    "critical_issues": ${#CRITICAL_ISSUES[@]},
    "high_issues": ${#HIGH_ISSUES[@]},
    "medium_issues": ${#MEDIUM_ISSUES[@]},
    "low_issues": ${#LOW_ISSUES[@]},
    "total_errors": $ERROR_COUNT,
    "total_warnings": $WARNING_COUNT,
    "total_info": $INFO_COUNT
  },
  "environment": {
    "swift_version": "$(swift --version 2>/dev/null | head -1 || echo 'Not installed')",
    "arch": "$(uname -m)",
    "os": "$(sw_vers -productVersion 2>/dev/null || uname -s)"
  },
  "issues": {
    "critical": $critical_json,
    "high": $high_json,
    "medium": $medium_json,
    "low": $low_json
  }
}
EOF

    log_info "JSON report generated: $JSON_REPORT"
}

generate_html_report() {
    log_info "Generating HTML report..."
    
    # Build issue arrays for embedding
    local critical_arr="[]"
    local high_arr="[]"
    local medium_arr="[]"
    local low_arr="[]"
    
    if [[ ${#CRITICAL_ISSUES[@]} -gt 0 ]]; then
        printf -v critical_arr '['
        for i in "${!CRITICAL_ISSUES[@]}"; do
            if [[ $i -gt 0 ]]; then critical_arr+=", "; fi
            critical_arr+="'$(echo "${CRITICAL_ISSUES[$i]}" | sed "s/'/'\\\\'/g")'"
        done
        critical_arr+=']'
    fi
    
    if [[ ${#HIGH_ISSUES[@]} -gt 0 ]]; then
        printf -v high_arr '['
        for i in "${!HIGH_ISSUES[@]}"; do
            if [[ $i -gt 0 ]]; then high_arr+=", "; fi
            high_arr+="'$(echo "${HIGH_ISSUES[$i]}" | sed "s/'/'\\\\'/g")'"
        done
        high_arr+=']'
    fi
    
    if [[ ${#MEDIUM_ISSUES[@]} -gt 0 ]]; then
        printf -v medium_arr '['
        for i in "${!MEDIUM_ISSUES[@]}"; do
            if [[ $i -gt 0 ]]; then medium_arr+=", "; fi
            medium_arr+="'$(echo "${MEDIUM_ISSUES[$i]}" | sed "s/'/'\\\\'/g")'"
        done
        medium_arr+=']'
    fi
    
    if [[ ${#LOW_ISSUES[@]} -gt 0 ]]; then
        printf -v low_arr '['
        for i in "${!LOW_ISSUES[@]}"; do
            if [[ $i -gt 0 ]]; then low_arr+=", "; fi
            low_arr+="'$(echo "${LOW_ISSUES[$i]}" | sed "s/'/'\\\\'/g")'"
        done
        low_arr+=']'
    fi
    
    local swift_ver="$(swift --version 2>/dev/null | head -1 || echo 'Not installed')"
    local arch="$(uname -m)"
    local os_ver="$(sw_vers -productVersion 2>/dev/null || uname -s)"
    
    cat > "$HTML_REPORT" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SystemMonitor Audit Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            line-height: 1.6;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        
        .content {
            padding: 40px;
        }
        
        .section {
            margin-bottom: 40px;
        }
        
        h2 {
            color: #667eea;
            font-size: 1.8em;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .stat-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid;
            text-align: center;
        }
        
        .stat-card.critical {
            border-color: #dc3545;
        }
        
        .stat-card.high {
            border-color: #fd7e14;
        }
        
        .stat-card.medium {
            border-color: #ffc107;
        }
        
        .stat-card.low {
            border-color: #17a2b8;
        }
        
        .stat-card.success {
            border-color: #28a745;
        }
        
        .stat-card h3 {
            font-size: 2em;
            margin-bottom: 5px;
        }
        
        .stat-card p {
            font-size: 0.9em;
            color: #666;
        }
        
        .issue-list {
            list-style: none;
        }
        
        .issue-item {
            background: #f8f9fa;
            padding: 15px;
            margin: 10px 0;
            border-radius: 6px;
            border-left: 4px solid;
        }
        
        .issue-item.critical {
            border-color: #dc3545;
            background: #fff5f5;
        }
        
        .issue-item.high {
            border-color: #fd7e14;
            background: #fffaf0;
        }
        
        .issue-item.medium {
            border-color: #ffc107;
            background: #fffff0;
        }
        
        .issue-item.low {
            border-color: #17a2b8;
            background: #f0f9ff;
        }
        
        .issue-title {
            font-weight: bold;
            font-size: 1.1em;
            margin-bottom: 5px;
        }
        
        .issue-desc {
            color: #555;
            margin-bottom: 5px;
        }
        
        .issue-file {
            font-family: monospace;
            font-size: 0.9em;
            color: #666;
        }
        
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: bold;
            margin-right: 10px;
        }
        
        .badge.critical {
            background: #dc3545;
            color: white;
        }
        
        .badge.high {
            background: #fd7e14;
            color: white;
        }
        
        .badge.medium {
            background: #ffc107;
            color: black;
        }
        
        .badge.low {
            background: #17a2b8;
            color: white;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        
        th {
            background: #667eea;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: bold;
        }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            border-top: 1px solid #ddd;
        }
        
        .success {
            color: #28a745;
        }
        
        .error {
            color: #dc3545;
        }
        
        .warning {
            color: #fd7e14;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔍 SystemMonitor Audit Report</h1>
            <p>Comprehensive Debug & Verification Analysis</p>
        </header>
        
        <div class="content">
            <!-- Summary Statistics -->
            <div class="section">
                <h2>Summary</h2>
                <div class="stats">
                    <div class="stat-card critical">
                        <h3 id="critical-count">0</h3>
                        <p>Critical Issues</p>
                    </div>
                    <div class="stat-card high">
                        <h3 id="high-count">0</h3>
                        <p>High Priority</p>
                    </div>
                    <div class="stat-card medium">
                        <h3 id="medium-count">0</h3>
                        <p>Medium Priority</p>
                    </div>
                    <div class="stat-card low">
                        <h3 id="low-count">0</h3>
                        <p>Low Priority</p>
                    </div>
                    <div class="stat-card success">
                        <h3 id="info-count">0</h3>
                        <p>Info/Notices</p>
                    </div>
                </div>
            </div>
            
            <!-- Environment Information -->
            <div class="section">
                <h2>Environment Information</h2>
                <table>
                    <tr>
                        <td><strong>Swift Version:</strong></td>
                        <td id="swift-version">-</td>
                    </tr>
                    <tr>
                        <td><strong>Architecture:</strong></td>
                        <td id="architecture">-</td>
                    </tr>
                    <tr>
                        <td><strong>OS Version:</strong></td>
                        <td id="os-version">-</td>
                    </tr>
                </table>
            </div>
            
            <!-- Issues by Severity -->
            <div class="section">
                <h2>Critical Issues</h2>
                <ul class="issue-list" id="critical-list">
                    <li style="padding: 20px; text-align: center; color: #28a745;">✓ No critical issues found</li>
                </ul>
            </div>
            
            <div class="section">
                <h2>High Priority Issues</h2>
                <ul class="issue-list" id="high-list">
                    <li style="padding: 20px; text-align: center; color: #28a745;">✓ No high priority issues found</li>
                </ul>
            </div>
            
            <div class="section">
                <h2>Medium Priority Issues</h2>
                <ul class="issue-list" id="medium-list">
                    <li style="padding: 20px; text-align: center; color: #28a745;">✓ No medium priority issues found</li>
                </ul>
            </div>
            
            <div class="section">
                <h2>Low Priority Issues</h2>
                <ul class="issue-list" id="low-list">
                    <li style="padding: 20px; text-align: center; color: #28a745;">✓ No low priority issues found</li>
                </ul>
            </div>
        </div>
        
        <footer>
            <p>Report generated on <span id="report-date">-</span></p>
            <p>SystemMonitor Audit & Debug Verification Tool</p>
        </footer>
    </div>
    
    <script>
        // Data embedded from the audit script
        const reportData = {
            critical_issues: REPORT_CRITICAL_PLACEHOLDER,
            high_issues: REPORT_HIGH_PLACEHOLDER,
            medium_issues: REPORT_MEDIUM_PLACEHOLDER,
            low_issues: REPORT_LOW_PLACEHOLDER,
            total_info: REPORT_INFO_PLACEHOLDER,
            swift_version: 'REPORT_SWIFT_VERSION_PLACEHOLDER',
            architecture: 'REPORT_ARCH_PLACEHOLDER',
            os_version: 'REPORT_OS_PLACEHOLDER'
        };
        
        document.addEventListener('DOMContentLoaded', function() {
            updateReport();
        });
        
        function updateReport() {
            // Update counts
            document.getElementById('critical-count').textContent = reportData.critical_issues.length;
            document.getElementById('high-count').textContent = reportData.high_issues.length;
            document.getElementById('medium-count').textContent = reportData.medium_issues.length;
            document.getElementById('low-count').textContent = reportData.low_issues.length;
            document.getElementById('info-count').textContent = reportData.total_info;
            
            // Update environment
            document.getElementById('swift-version').textContent = reportData.swift_version;
            document.getElementById('architecture').textContent = reportData.architecture;
            document.getElementById('os-version').textContent = reportData.os_version;
            document.getElementById('report-date').textContent = new Date().toLocaleString();
            
            // Update issue lists
            populateIssueList('critical', reportData.critical_issues);
            populateIssueList('high', reportData.high_issues);
            populateIssueList('medium', reportData.medium_issues);
            populateIssueList('low', reportData.low_issues);
        }
        
        function populateIssueList(severity, issues) {
            const listId = severity + '-list';
            const listElement = document.getElementById(listId);
            
            if (!issues || issues.length === 0) {
                listElement.innerHTML = '<li style="padding: 20px; text-align: center; color: #28a745;">✓ No ' + severity + ' priority issues found</li>';
                return;
            }
            
            listElement.innerHTML = issues.map(issue => {
                const [title, desc, file, line] = issue.split('|');
                return `
                    <li class="issue-item ${severity}">
                        <div class="issue-title">
                            <span class="badge ${severity}">${severity.toUpperCase()}</span>
                            ${title || 'Unknown Issue'}
                        </div>
                        <div class="issue-desc">${desc || ''}</div>
                        ${file && file !== '' ? `<div class="issue-file">📁 ${file}${line && line !== '' ? ':' + line : ''}</div>` : ''}
                    </li>
                `;
            }).join('');
        }
    </script>
</body>
</html>
EOF

    # Replace placeholders with actual data
    sed -i '' "s|REPORT_CRITICAL_PLACEHOLDER|$critical_arr|g" "$HTML_REPORT"
    sed -i '' "s|REPORT_HIGH_PLACEHOLDER|$high_arr|g" "$HTML_REPORT"
    sed -i '' "s|REPORT_MEDIUM_PLACEHOLDER|$medium_arr|g" "$HTML_REPORT"
    sed -i '' "s|REPORT_LOW_PLACEHOLDER|$low_arr|g" "$HTML_REPORT"
    sed -i '' "s|REPORT_INFO_PLACEHOLDER|$INFO_COUNT|g" "$HTML_REPORT"
    sed -i '' "s|REPORT_SWIFT_VERSION_PLACEHOLDER|$swift_ver|g" "$HTML_REPORT"
    sed -i '' "s|REPORT_ARCH_PLACEHOLDER|$arch|g" "$HTML_REPORT"
    sed -i '' "s|REPORT_OS_PLACEHOLDER|$os_ver|g" "$HTML_REPORT"
    
    log_info "HTML report generated: $HTML_REPORT"
}

#################################################################################
# Main Execution
#################################################################################

main() {
    # Clear log file
    > "$AUDIT_LOG"
    
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  SystemMonitor Comprehensive Audit & Debug Script          ║"
    echo "║  Version 1.0                                               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Starting comprehensive audit..."
    log_info "Verbose: $VERBOSE"
    log_info "Show fix suggestions: $SHOW_FIX_SUGGESTIONS"
    
    # Run all checks
    check_swift_version || true
    check_project_structure || true
    check_swift_syntax || true
    check_swift6_compatibility || true
    check_concurrency_patterns || true
    check_memory_safety || true
    check_imports_and_dependencies || true
    check_code_patterns || true
    check_performance_patterns || true
    check_file_analysis || true
    check_documentation || true
    
    # Build and test checks
    check_build || true
    check_tests || true
    
    # Generate reports
    generate_markdown_report
    generate_json_report
    generate_html_report
    
    # Final Summary
    log_section "Audit Complete"
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Audit Summary:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo "  Info Messages:      $INFO_COUNT"
    echo "  Warnings:           $WARNING_COUNT"
    echo "  Errors:             $ERROR_COUNT"
    echo -e "  ${RED}Critical Issues:    ${#CRITICAL_ISSUES[@]}${NC}"
    echo -e "  ${YELLOW}High Issues:        ${#HIGH_ISSUES[@]}${NC}"
    echo -e "  Medium Issues:      ${#MEDIUM_ISSUES[@]}"
    echo -e "  Low Issues:         ${#LOW_ISSUES[@]}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    
    # List generated reports
    echo ""
    echo -e "${GREEN}Generated Reports:${NC}"
    echo "  📄 Markdown:  $DEBUG_REPORT"
    echo "  📊 JSON:      $JSON_REPORT"
    echo "  🌐 HTML:      $HTML_REPORT"
    echo "  📝 Log:       $AUDIT_LOG"
    
    echo ""
    
    # Determine exit code
    if [[ ${#CRITICAL_ISSUES[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Audit failed: Critical issues found${NC}"
        return 1
    elif [[ ${#HIGH_ISSUES[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Audit completed with high priority issues${NC}"
        return 0
    else
        echo -e "${GREEN}✅ Audit completed successfully${NC}"
        return 0
    fi
}

# Run main function
main
