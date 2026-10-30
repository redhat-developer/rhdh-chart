#!/bin/bash
set -euo pipefail

# Vendored from https://github.com/jCOTINEAU/chart-coverage
# File: helm-coverage.sh
# Commit: 18c41243aca54231d36905185f2f65c231b06a84
# Date:  27/10/2026
# License: Apache License 2.0 (same as this repository)
#
# Do not edit the tool logic here. To upgrade, replace this file from
# that commit and update this header.
#
# Upstream: https://github.com/jCOTINEAU/chart-coverage/blob/18c41243aca54231d36905185f2f65c231b06a84/helm-coverage.sh

# =============================================================================
# Helm Chart Coverage Tool
# Instruments Helm templates to track conditional branch execution
# =============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly HELPER_FILENAME="_coverage_helper.tpl"

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [options] <chart-path> [values-file-or-dir...]

Options:
    -s, --select <path>      Only instrument specific template(s). Can be repeated.
    --helm-args <args>       Extra arguments to pass to helm template (e.g. "--set key=val")
    --instrument-only        Stop after instrumentation (no cleanup)
    --json                   Output results in JSON format (to stdout)
    --cobertura <file>       Output Cobertura XML report (for GitLab integration)
    -h, --help               Show this help message

Arguments:
    chart-path          Path to the Helm chart directory
    values-file-or-dir  Values files (.yaml/.yml) or directories containing them

Examples:
    ${SCRIPT_NAME} ./my-chart
    ${SCRIPT_NAME} ./my-chart values.yaml
    ${SCRIPT_NAME} ./my-chart ./values-dir/
    ${SCRIPT_NAME} -s patterns/nested.yaml ./my-chart values.yaml
    ${SCRIPT_NAME} --helm-args "--set version=2025.10" ./my-chart values.yaml
    ${SCRIPT_NAME} --json ./my-chart ./values/ > coverage.json
    ${SCRIPT_NAME} --cobertura coverage.xml ./my-chart ./values/
EOF
    exit 1
}

# -----------------------------------------------------------------------------
# Logging (all to stderr to keep stdout clean for return values)
# -----------------------------------------------------------------------------
log_info()    { echo -e "${CYAN}[INFO]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[OK]${NC} $*" >&2; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------
validate_chart_path() {
    local chart_path="$1"
    
    if [[ ! -d "$chart_path" ]]; then
        log_error "Chart directory not found: $chart_path"
    exit 1
fi

    if [[ ! -d "$chart_path/templates" ]]; then
        log_error "No templates/ directory in: $chart_path"
        exit 1
    fi
    
    if [[ ! -f "$chart_path/Chart.yaml" ]]; then
        log_error "No Chart.yaml found in: $chart_path"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Create coverage helper template
# -----------------------------------------------------------------------------
create_helper_template() {
    local output_path="$1"
    
    cat > "$output_path" << 'HELPER_EOF'
{{- /*
Coverage Helper - Tracks executed template branches
Uses shared context ._cov to track across files and helpers
All tracking functions expect (list $context "marker")
*/ -}}

{{- define "coverage.init" -}}
{{- if not (hasKey . "_cov") -}}
{{- $_ := set . "_cov" (dict "files" (list) "helpers" (list)) -}}
{{- end -}}
{{- end -}}

{{- define "coverage.trackFile" -}}
{{- $ctx := index . 0 -}}
{{- $marker := index . 1 -}}
{{- $_ := set $ctx._cov "files" (append $ctx._cov.files $marker) -}}
{{- end -}}

{{- define "coverage.trackHelper" -}}
{{- $ctx := index . 0 -}}
{{- $marker := index . 1 -}}
{{- /* Try to find _cov in context - supports both direct and dict-with-context patterns */ -}}
{{- if and (kindIs "map" $ctx) (hasKey $ctx "_cov") -}}
  {{- /* Direct root context: include "helper" $ */ -}}
  {{- $_ := set $ctx._cov "helpers" (append $ctx._cov.helpers $marker) -}}
{{- else if and (kindIs "map" $ctx) (hasKey $ctx "context") -}}
  {{- /* Dict with context key: include "helper" (dict "key" "val" "context" $) */ -}}
  {{- if and (kindIs "map" $ctx.context) (hasKey $ctx.context "_cov") -}}
    {{- $_ := set $ctx.context._cov "helpers" (append $ctx.context._cov.helpers $marker) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "coverage.printReport" -}}
{{- $ctx := index . 0 -}}
{{- $total := index . 1 -}}
{{- $fileCount := len $ctx._cov.files -}}
{{- $helperCount := len $ctx._cov.helpers -}}
{{- $totalCovered := add $fileCount $helperCount -}}
# COVERAGE_REPORT: {{ $totalCovered }}/{{ $total }}
# FILES_COVERED: {{ $fileCount }}
{{- range $ctx._cov.files }}
# COVERED_FILE: {{ . }}
{{- end }}
# HELPERS_COVERED: {{ $helperCount }}
{{- range $ctx._cov.helpers }}
# COVERED_HELPER: {{ . }}
{{- end }}
{{- end -}}
HELPER_EOF
}

# -----------------------------------------------------------------------------
# Instrument a single .yaml template file
# Returns the number of injected markers via stdout
# -----------------------------------------------------------------------------
instrument_yaml_template() {
    local template_file="$1"
    local relative_name="$2"
    
    local temp_file count_file
    temp_file=$(mktemp)
    count_file=$(mktemp)
    
    awk -v fname="$relative_name" -v countfile="$count_file" '
    # Function to check if position is inside a string literal passed to tpl/cat/printf
    # Returns 1 if inside a function string argument, 0 otherwise
    function is_in_tpl_string(str, pos,    quote_count, i, c, prev, before_quotes) {
        # First check if line contains tpl, cat, or printf with string args
        if (str !~ /(tpl|cat|printf)[[:space:]]*\(/) {
            return 0
        }
        # Count quotes before position
        quote_count = 0
        before_quotes = substr(str, 1, pos - 1)
        for (i = 1; i < pos; i++) {
            c = substr(str, i, 1)
            if (i > 1) {
                prev = substr(str, i-1, 1)
            } else {
                prev = ""
            }
            if (c == "\"" && prev != "\\") {
                quote_count++
            }
        }
        # If odd number of quotes AND we have tpl/cat/printf, likely in string arg
        return (quote_count % 2 == 1)
    }
    
    BEGIN {
        marker_count = 0
        # Initialize shared coverage context
        print "{{- include \"coverage.init\" . -}}"
    }
    {
        # Reset inline occurrence counter for each line
        inline_occ = 0
        
        # Check if standalone end/else (on its own line)
        if ($0 ~ /^[[:space:]]*\{\{-?[[:space:]]*(end|else)[[:space:]]*-?\}\}[[:space:]]*$/ ||
            $0 ~ /^[[:space:]]*\{\{-?[[:space:]]*else[[:space:]]+if[[:space:]]+/) {
            # Standalone - inject before line (use line number)
            marker_count++
            marker_id = fname ":L" NR
            print "{{- include \"coverage.trackFile\" (list $ \"" marker_id "\") -}}"
            print $0
        } else if ($0 ~ /\{\{-?[[:space:]]*(end|else)/) {
            # Inline end/else - inject before each occurrence within the line
            line = $0
            original_line = $0
            result = ""
            pos_offset = 0
            while (match(line, /\{\{-?[[:space:]]*(end|else)[[:space:]]*([^}]*-?\}\})?/)) {
                abs_pos = pos_offset + RSTART
                # Check if this match is inside a tpl/cat/printf string argument
                if (is_in_tpl_string(original_line, abs_pos)) {
                    # Inside tpl/cat string - do not inject, just copy as-is
                    result = result substr(line, 1, RSTART + RLENGTH - 1)
                } else {
                    # Normal template code - inject marker with line number
                    marker_count++
                    inline_occ++
                    # Use L<line>.<occurrence> for inline multiples
                    if (inline_occ == 1) {
                        marker_id = fname ":L" NR
                    } else {
                        marker_id = fname ":L" NR "." inline_occ
                    }
                    marker = "{{- include \"coverage.trackFile\" (list $ \"" marker_id "\") -}}"
                    result = result substr(line, 1, RSTART-1) marker substr(line, RSTART, RLENGTH)
                }
                pos_offset = pos_offset + RSTART + RLENGTH - 1
                line = substr(line, RSTART + RLENGTH)
            }
            result = result line
            print result
        } else {
            print $0
        }
    }
    END {
        # Print coverage report as comments (no new YAML document)
        print ""
        print "{{ include \"coverage.printReport\" (list $ " marker_count ") }}"
        
        # Write marker count to separate file
        print marker_count > countfile
    }
    ' "$template_file" > "$temp_file"
    
    # Read marker count from file
    local marker_count
    marker_count=$(cat "$count_file")
    
    mv "$temp_file" "$template_file"
    rm -f "$count_file"
    
    echo "$marker_count"
}

# -----------------------------------------------------------------------------
# Instrument a single .yaml template file (Cobertura mode with line ranges)
# Returns the number of injected markers via stdout
# Uses a stack-based approach to track block start lines
# -----------------------------------------------------------------------------
instrument_yaml_template_cobertura() {
    local template_file="$1"
    local relative_name="$2"
    
    local temp_file count_file
    temp_file=$(mktemp)
    count_file=$(mktemp)
    
    awk -v fname="$relative_name" -v countfile="$count_file" '
    # Function to check if position is inside a string literal passed to tpl/cat/printf
    function is_in_tpl_string(str, pos,    quote_count, i, c, prev) {
        if (str !~ /(tpl|cat|printf)[[:space:]]*\(/) {
            return 0
        }
        quote_count = 0
        for (i = 1; i < pos; i++) {
            c = substr(str, i, 1)
            if (i > 1) {
                prev = substr(str, i-1, 1)
            } else {
                prev = ""
            }
            if (c == "\"" && prev != "\\") {
                quote_count++
            }
        }
        return (quote_count % 2 == 1)
    }
    
    BEGIN {
        marker_count = 0
        stack_top = 0
        # Initialize shared coverage context
        print "{{- include \"coverage.init\" . -}}"
    }
    
    {
        lines[NR] = $0
        line_count = NR
    }
    
    END {
        # Process all lines to find block structures
        for (ln = 1; ln <= line_count; ln++) {
            line = lines[ln]
            inline_occ = 0
            
            # Process line character by character to find template tags
            pos = 1
            result = ""
            
            while (pos <= length(line)) {
                # Look for opening {{
                rest = substr(line, pos)
                
                if (match(rest, /^\{\{-?[[:space:]]*(if|with|range)[[:space:]]+/)) {
                    # Found an opening block - push to stack
                    stack_top++
                    stack_line[stack_top] = ln
                    stack_pos[stack_top] = pos
                    result = result substr(rest, 1, RLENGTH)
                    pos = pos + RLENGTH
                }
                else if (match(rest, /^\{\{-?[[:space:]]*else[[:space:]]+if[[:space:]]+/)) {
                    # else if: close previous block, open new one
                    if (stack_top > 0) {
                        start_line = stack_line[stack_top]
                        stack_top--
                    } else {
                        start_line = ln
                    }
                    
                    # Calculate end line: line before the else if (content lines only)
                    end_line = (ln > start_line) ? ln - 1 : start_line
                    
                    # Check if inside tpl string
                    abs_pos = pos
                    if (!is_in_tpl_string(line, abs_pos)) {
                        marker_count++
                        inline_occ++
                        if (inline_occ == 1) {
                            marker_id = fname ":L" start_line "-L" end_line
                        } else {
                            marker_id = fname ":L" start_line "-L" end_line "." inline_occ
                        }
                        marker = "{{- include \"coverage.trackFile\" (list $ \"" marker_id "\") -}}"
                        result = result marker
                    }
                    
                    # Push new block start
                    stack_top++
                    stack_line[stack_top] = ln
                    stack_pos[stack_top] = pos
                    
                    result = result substr(rest, 1, RLENGTH)
                    pos = pos + RLENGTH
                }
                else if (match(rest, /^\{\{-?[[:space:]]*else[[:space:]]*-?\}\}/)) {
                    # Standalone else: close previous block, open new one
                    if (stack_top > 0) {
                        start_line = stack_line[stack_top]
                        stack_top--
                    } else {
                        start_line = ln
                    }
                    
                    # Calculate end line: line before the else (content lines only)
                    end_line = (ln > start_line) ? ln - 1 : start_line
                    
                    abs_pos = pos
                    if (!is_in_tpl_string(line, abs_pos)) {
                        marker_count++
                        inline_occ++
                        if (inline_occ == 1) {
                            marker_id = fname ":L" start_line "-L" end_line
                        } else {
                            marker_id = fname ":L" start_line "-L" end_line "." inline_occ
                        }
                        marker = "{{- include \"coverage.trackFile\" (list $ \"" marker_id "\") -}}"
                        result = result marker
                    }
                    
                    # Push new block start for the else branch
                    stack_top++
                    stack_line[stack_top] = ln
                    stack_pos[stack_top] = pos
                    
                    result = result substr(rest, 1, RLENGTH)
                    pos = pos + RLENGTH
                }
                else if (match(rest, /^\{\{-?[[:space:]]*end[[:space:]]*-?\}\}/)) {
                    # End block: close current block
                    if (stack_top > 0) {
                        start_line = stack_line[stack_top]
                        stack_top--
                    } else {
                        start_line = ln
                    }
                    
                    # Calculate end line: line before the end (content lines only)
                    end_line = (ln > start_line) ? ln - 1 : start_line
                    
                    abs_pos = pos
                    if (!is_in_tpl_string(line, abs_pos)) {
                        marker_count++
                        inline_occ++
                        if (inline_occ == 1) {
                            marker_id = fname ":L" start_line "-L" end_line
                        } else {
                            marker_id = fname ":L" start_line "-L" end_line "." inline_occ
                        }
                        marker = "{{- include \"coverage.trackFile\" (list $ \"" marker_id "\") -}}"
                        result = result marker
                    }
                    
                    result = result substr(rest, 1, RLENGTH)
                    pos = pos + RLENGTH
                }
                else {
                    # No special pattern, copy one character
                    result = result substr(rest, 1, 1)
                    pos = pos + 1
                }
            }
            
            processed_lines[ln] = result
        }
        
        # Output all processed lines
        for (ln = 1; ln <= line_count; ln++) {
            print processed_lines[ln]
        }
        
        # Print coverage report
        print ""
        print "{{ include \"coverage.printReport\" (list $ " marker_count ") }}"
        
        # Write marker count to separate file
        print marker_count > countfile
    }
    ' "$template_file" > "$temp_file"
    
    # Read marker count from file
    local marker_count
    marker_count=$(cat "$count_file")
    
    mv "$temp_file" "$template_file"
    rm -f "$count_file"
    
    echo "$marker_count"
}

# -----------------------------------------------------------------------------
# Instrument a single .tpl helper file
# Returns the number of injected markers via stdout
# -----------------------------------------------------------------------------
instrument_tpl_template() {
    local template_file="$1"
    local relative_name="$2"
    
    local temp_file count_file
    temp_file=$(mktemp)
    count_file=$(mktemp)
    
    awk -v fname="$relative_name" -v countfile="$count_file" '
    # Function to check if position is inside a string literal passed to tpl/cat/printf
    function is_in_tpl_string(str, pos,    quote_count, i, c, prev, before_quotes) {
        if (str !~ /(tpl|cat|printf)[[:space:]]*\(/) {
            return 0
        }
        quote_count = 0
        for (i = 1; i < pos; i++) {
            c = substr(str, i, 1)
            if (i > 1) {
                prev = substr(str, i-1, 1)
            } else {
                prev = ""
            }
            if (c == "\"" && prev != "\\") {
                quote_count++
            }
        }
        return (quote_count % 2 == 1)
    }
    
    BEGIN { 
        marker_count = 0
        in_define = 0
        current_define = ""
    }
    {
        # Reset inline occurrence counter for each line
        inline_occ = 0
        
        # Track define blocks to get helper names
        if ($0 ~ /\{\{-?[[:space:]]*define[[:space:]]+"([^"]+)"/) {
            in_define = 1
            # Extract define name
            match($0, /define[[:space:]]+"([^"]+)"/)
            temp = substr($0, RSTART, RLENGTH)
            gsub(/define[[:space:]]+"/, "", temp)
            gsub(/"/, "", temp)
            current_define = temp
        }
        
        # Only instrument inside define blocks
        if (in_define) {
            # Check if standalone end/else (on its own line)
            if ($0 ~ /^[[:space:]]*\{\{-?[[:space:]]*(end|else)[[:space:]]*-?\}\}[[:space:]]*$/) {
                # Check if this is likely the define-closing end (simple heuristic: no else)
                if ($0 ~ /else/) {
                    marker_count++
                    marker_id = fname ":" current_define ":L" NR
                    print "{{- include \"coverage.trackHelper\" (list $ \"" marker_id "\") -}}"
                    print $0
                } else {
                    # Could be define-closing or block-closing end
                    # We inject anyway, but it wont break if its the define end
                    marker_count++
                    marker_id = fname ":" current_define ":L" NR
                    print "{{- include \"coverage.trackHelper\" (list $ \"" marker_id "\") -}}"
                    print $0
                    # Check if this closes the define
                    if ($0 ~ /end[[:space:]]*-?\}\}[[:space:]]*$/) {
                        # Might be closing define, reset
                        in_define = 0
                        current_define = ""
                    }
                }
            } else if ($0 ~ /^[[:space:]]*\{\{-?[[:space:]]*else[[:space:]]+if[[:space:]]+/) {
                marker_count++
                marker_id = fname ":" current_define ":L" NR
                print "{{- include \"coverage.trackHelper\" (list $ \"" marker_id "\") -}}"
                print $0
            } else if ($0 ~ /\{\{-?[[:space:]]*(end|else)/) {
                # Inline end/else
                line = $0
                original_line = $0
                result = ""
                pos_offset = 0
                while (match(line, /\{\{-?[[:space:]]*(end|else)[[:space:]]*([^}]*-?\}\})?/)) {
                    abs_pos = pos_offset + RSTART
                    # Check if inside tpl/cat/printf string argument
                    if (is_in_tpl_string(original_line, abs_pos)) {
                        # Inside tpl/cat string - do not inject, just copy as-is
                        result = result substr(line, 1, RSTART + RLENGTH - 1)
                    } else {
                        # Normal template code - inject marker with line number
                        marker_count++
                        inline_occ++
                        if (inline_occ == 1) {
                            marker_id = fname ":" current_define ":L" NR
                        } else {
                            marker_id = fname ":" current_define ":L" NR "." inline_occ
                        }
                        marker = "{{- include \"coverage.trackHelper\" (list $ \"" marker_id "\") -}}"
                        result = result substr(line, 1, RSTART-1) marker substr(line, RSTART, RLENGTH)
                    }
                    pos_offset = pos_offset + RSTART + RLENGTH - 1
                    line = substr(line, RSTART + RLENGTH)
                }
                result = result line
                print result
            } else {
                print $0
            }
        } else {
            print $0
        }
    }
    END {
        # Write marker count to separate file
        print marker_count > countfile
    }
    ' "$template_file" > "$temp_file"
    
    # Read marker count from file
    local marker_count
    marker_count=$(cat "$count_file")
    
    mv "$temp_file" "$template_file"
    rm -f "$count_file"
    
    echo "$marker_count"
}

# -----------------------------------------------------------------------------
# Instrument a single .tpl helper file (Cobertura mode with line ranges)
# Returns the number of injected markers via stdout
# Uses define line as start for all branches within that helper
# -----------------------------------------------------------------------------
instrument_tpl_template_cobertura() {
    local template_file="$1"
    local relative_name="$2"
    
    local temp_file count_file
    temp_file=$(mktemp)
    count_file=$(mktemp)
    
    awk -v fname="$relative_name" -v countfile="$count_file" '
    # Function to check if position is inside a string literal passed to tpl/cat/printf
    function is_in_tpl_string(str, pos,    quote_count, i, c, prev) {
        if (str !~ /(tpl|cat|printf)[[:space:]]*\(/) {
            return 0
        }
        quote_count = 0
        for (i = 1; i < pos; i++) {
            c = substr(str, i, 1)
            if (i > 1) {
                prev = substr(str, i-1, 1)
            } else {
                prev = ""
            }
            if (c == "\"" && prev != "\\") {
                quote_count++
            }
        }
        return (quote_count % 2 == 1)
    }
    
    BEGIN { 
        marker_count = 0
        in_define = 0
        current_define = ""
        define_line = 0
    }
    {
        # Reset inline occurrence counter for each line
        inline_occ = 0
        
        # Track define blocks to get helper names and start line
        if ($0 ~ /\{\{-?[[:space:]]*define[[:space:]]+"([^"]+)"/) {
            in_define = 1
            define_line = NR
            # Extract define name
            match($0, /define[[:space:]]+"([^"]+)"/)
            temp = substr($0, RSTART, RLENGTH)
            gsub(/define[[:space:]]+"/, "", temp)
            gsub(/"/, "", temp)
            current_define = temp
        }
        
        # Only instrument inside define blocks
        if (in_define) {
            # Check if standalone end/else (on its own line)
            if ($0 ~ /^[[:space:]]*\{\{-?[[:space:]]*(end|else)[[:space:]]*-?\}\}[[:space:]]*$/) {
                # Check if this is likely the define-closing end (simple heuristic: no else)
                if ($0 ~ /else/) {
                    marker_count++
                    marker_id = fname ":" current_define ":L" define_line "-L" NR
                    print "{{- include \"coverage.trackHelper\" (list $ \"" marker_id "\") -}}"
                    print $0
                } else {
                    # Could be define-closing or block-closing end
                    # We inject anyway, but it wont break if its the define end
                    marker_count++
                    marker_id = fname ":" current_define ":L" define_line "-L" NR
                    print "{{- include \"coverage.trackHelper\" (list $ \"" marker_id "\") -}}"
                    print $0
                    # Check if this closes the define
                    if ($0 ~ /end[[:space:]]*-?\}\}[[:space:]]*$/) {
                        # Might be closing define, reset
                        in_define = 0
                        current_define = ""
                        define_line = 0
                    }
                }
            } else if ($0 ~ /^[[:space:]]*\{\{-?[[:space:]]*else[[:space:]]+if[[:space:]]+/) {
                marker_count++
                marker_id = fname ":" current_define ":L" define_line "-L" NR
                print "{{- include \"coverage.trackHelper\" (list $ \"" marker_id "\") -}}"
                print $0
            } else if ($0 ~ /\{\{-?[[:space:]]*(end|else)/) {
                # Inline end/else
                line = $0
                original_line = $0
                result = ""
                pos_offset = 0
                while (match(line, /\{\{-?[[:space:]]*(end|else)[[:space:]]*([^}]*-?\}\})?/)) {
                    abs_pos = pos_offset + RSTART
                    # Check if inside tpl/cat/printf string argument
                    if (is_in_tpl_string(original_line, abs_pos)) {
                        # Inside tpl/cat string - do not inject, just copy as-is
                        result = result substr(line, 1, RSTART + RLENGTH - 1)
                    } else {
                        # Normal template code - inject marker
                        marker_count++
                        inline_occ++
                        if (inline_occ == 1) {
                            marker_id = fname ":" current_define ":L" define_line "-L" NR
                        } else {
                            marker_id = fname ":" current_define ":L" define_line "-L" NR "." inline_occ
                        }
                        marker = "{{- include \"coverage.trackHelper\" (list $ \"" marker_id "\") -}}"
                        result = result substr(line, 1, RSTART-1) marker substr(line, RSTART, RLENGTH)
                    }
                    pos_offset = pos_offset + RSTART + RLENGTH - 1
                    line = substr(line, RSTART + RLENGTH)
                }
                result = result line
                print result
            } else {
                print $0
            }
        } else {
            print $0
        }
    }
    END {
        # Write marker count to separate file
        print marker_count > countfile
    }
    ' "$template_file" > "$temp_file"
    
    # Read marker count from file
    local marker_count
    marker_count=$(cat "$count_file")
    
    mv "$temp_file" "$template_file"
    rm -f "$count_file"
    
    echo "$marker_count"
}

# -----------------------------------------------------------------------------
# Check if a template path matches any of the select filters
# -----------------------------------------------------------------------------
matches_filter() {
    local path="$1"
    shift
    local filters=("$@")
    
    # If no filters, everything matches
    if [[ ${#filters[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Check each filter
    for filter in "${filters[@]}"; do
        # Match if path starts with filter or equals filter
        if [[ "$path" == "$filter" ]] || [[ "$path" == "$filter"* ]] || [[ "$path" == *"/$filter" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Instrument all templates in chart
# -----------------------------------------------------------------------------
# Usage: instrument_chart <instrumented_dir> <cobertura_mode> [filter1] [filter2] ...
instrument_chart() {
    local instrumented_dir="$1"
    local cobertura_mode="$2"
    shift 2
    local select_filters=("$@")
    local total_file_markers=0
    local total_helper_markers=0
    
    # Log filter info
    if [[ ${#select_filters[@]} -gt 0 ]]; then
        log_info "Filtering templates: ${select_filters[*]}"
    fi
    
    # Create coverage helper template
    create_helper_template "${instrumented_dir}/templates/${HELPER_FILENAME}"
    log_info "Created helper: ${HELPER_FILENAME}"
    
    # Select instrumentation functions based on mode
    local yaml_instrument_func="instrument_yaml_template"
    local tpl_instrument_func="instrument_tpl_template"
    if [[ "$cobertura_mode" == "true" ]]; then
        yaml_instrument_func="instrument_yaml_template_cobertura"
        tpl_instrument_func="instrument_tpl_template_cobertura"
        log_info "Using Cobertura mode (line ranges L<start>-L<end>)"
    fi
    
    # Find and instrument all .yaml files
    while IFS= read -r -d '' template || [[ -n "$template" ]]; do
        local relative_path="${template#${instrumented_dir}/templates/}"
        local filename
        filename=$(basename "$template")
        
        # Skip our coverage helper
        [[ "$filename" == "$HELPER_FILENAME" ]] && continue
        # Skip other helper files (start with _)
        [[ "$filename" == _* ]] && continue
        
        # Check filter
        if ! matches_filter "$relative_path" ${select_filters[@]+"${select_filters[@]}"}; then
            continue
        fi
        
        local markers
        markers=$($yaml_instrument_func "$template" "$relative_path")
        total_file_markers=$((total_file_markers + markers))
        
        log_info "Instrumented file: ${relative_path} (${markers} branches)"
    done < <(find "${instrumented_dir}/templates" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0)
    
    # Find and instrument all .tpl files (except our coverage helper)
    while IFS= read -r -d '' template || [[ -n "$template" ]]; do
        local relative_path="${template#${instrumented_dir}/templates/}"
        local filename
        filename=$(basename "$template")
        
        # Skip our coverage helper
        [[ "$filename" == "$HELPER_FILENAME" ]] && continue
        
        local markers
        markers=$($tpl_instrument_func "$template" "$relative_path")
        total_helper_markers=$((total_helper_markers + markers))
        
        if [[ "$markers" -gt 0 ]]; then
            log_info "Instrumented helper: ${relative_path} (${markers} branches)"
        fi
    done < <(find "${instrumented_dir}/templates" -type f -name "*.tpl" -print0)
    
    local total=$((total_file_markers + total_helper_markers))
    echo "$total"
}

# -----------------------------------------------------------------------------
# Extract all branch markers from instrumented templates
# Writes to provided files: one for file branches, one for helper branches
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Extract all branch markers from instrumented templates
# Writes to provided files: one for file branches, one for helper branches
# Uses find -exec grep for BusyBox/Alpine compatibility (no --include or xargs)
# -----------------------------------------------------------------------------
extract_all_branches() {
    local instrumented_dir="$1"
    local all_file_branches_file="$2"
    local all_helper_branches_file="$3"
    
    # Extract file branch markers from .yaml/.yml templates
    # Use find -exec for maximum portability (works on BusyBox, BSD, GNU)
    find "${instrumented_dir}/templates" -type f \( -name "*.yaml" -o -name "*.yml" \) \
        -exec grep -oE 'coverage\.trackFile" \(list \$ "[^"]+"\)' {} + 2>/dev/null | \
        sed 's/.*"\([^"]*\)".*/\1/' | sort -u >> "$all_file_branches_file" || true
    
    # Extract helper branch markers from .tpl files (excluding our coverage helper)
    find "${instrumented_dir}/templates" -type f -name "*.tpl" ! -name "$HELPER_FILENAME" \
        -exec grep -oE 'coverage\.trackHelper" \(list \$ "[^"]+"\)' {} + 2>/dev/null | \
        sed 's/.*"\([^"]*\)".*/\1/' | sort -u >> "$all_helper_branches_file" || true
}
# -----------------------------------------------------------------------------
# Run helm template and parse coverage
# Outputs covered branches to provided accumulator files
# -----------------------------------------------------------------------------
run_coverage() {
    local instrumented_dir="$1"
    local total_branches="$2"
    local all_files_accumulator="$3"
    local all_helpers_accumulator="$4"
    local values_file="$5"
    local helm_extra_args="${6:-}"
    
    local helm_args=("template" "coverage-test" "$instrumented_dir")
    
    # Add values file if provided
    [[ -n "$values_file" ]] && helm_args+=("-f" "$values_file")
    
    # Add extra helm args if provided (split by spaces)
    if [[ -n "$helm_extra_args" ]]; then
        # shellcheck disable=SC2206
        helm_args+=($helm_extra_args)
    fi
    
    local output
    output=$(mktemp)
    
    log_info "Starting helm template..."
    local start_time
    start_time=$(date +%s.%N)
    
    if ! helm "${helm_args[@]}" > "$output" 2>&1; then
        log_error "Helm template failed:"
        cat "$output" >&2
        rm -f "$output"
        return 1
    fi
    
    local end_time elapsed
    end_time=$(date +%s.%N)
    elapsed=$(echo "$end_time - $start_time" | bc)
    log_info "Helm template completed in ${elapsed}s"
    
    # Parse coverage from output - extract unique branches
    local temp_files temp_helpers
    temp_files=$(mktemp)
    temp_helpers=$(mktemp)
    
    log_info "Parsing coverage output..."
    local parse_start parse_end
    parse_start=$(date +%s.%N)
    
    # Use grep to find coverage markers - be flexible with whitespace/format
    # The markers look like: # COVERED_FILE: <branch_id>
    grep 'COVERED_FILE:' "$output" | sed 's/.*COVERED_FILE:[[:space:]]*//' >> "$temp_files" || true
    grep 'COVERED_HELPER:' "$output" | sed 's/.*COVERED_HELPER:[[:space:]]*//' >> "$temp_helpers" || true
    
    parse_end=$(date +%s.%N)
    log_info "Parsing completed in $(echo "$parse_end - $parse_start" | bc)s"
    
    rm -f "$output"
    
    # Get unique branches only
    local covered_files=()
    local covered_helpers=()
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "$line" ]] && covered_files+=("$line")
        echo "$line" >> "$all_files_accumulator"
    done < <(sort -u "$temp_files")
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "$line" ]] && covered_helpers+=("$line")
        echo "$line" >> "$all_helpers_accumulator"
    done < <(sort -u "$temp_helpers")
    
    rm -f "$temp_files" "$temp_helpers"
    
    local file_count=${#covered_files[@]}
    local helper_count=${#covered_helpers[@]}
    local total_covered=$((file_count + helper_count))
    
    # Display results
echo ""
    echo "========================================"
    echo "Coverage Report"
echo "========================================"
    
    if [[ ${#covered_files[@]} -gt 0 ]]; then
        echo ""
        echo "📄 Covered file branches (${file_count}):"
        for line in "${covered_files[@]}"; do
            echo -e "  ${GREEN}✓${NC} $line"
        done
    fi
    
    if [[ ${#covered_helpers[@]} -gt 0 ]]; then
        echo ""
        echo "🔧 Covered helper branches (${helper_count}):"
        for line in "${covered_helpers[@]}"; do
            echo -e "  ${GREEN}✓${NC} $line"
        done
    fi
    
    echo ""
    
    # Calculate percentage
    local percent=0
    if [[ "$total_branches" -gt 0 ]]; then
        percent=$((total_covered * 100 / total_branches))
    fi
    
    # Color based on coverage
    local color icon
    if [[ "$percent" -eq 100 ]]; then
        color=$GREEN
        icon="✓"
    elif [[ "$percent" -ge 50 ]]; then
        color=$YELLOW
        icon="~"
    else
        color=$RED
        icon="✗"
    fi
    
    echo "----------------------------------------"
    printf "📄 Files:   %d branches covered\n" "$file_count"
    printf "🔧 Helpers: %d branches covered\n" "$helper_count"
    echo "----------------------------------------"
    printf "${color}${icon} Total: %d/%d branches (%d%%)${NC}\n" \
        "$total_covered" "$total_branches" "$percent"
    
    return 0
}

# -----------------------------------------------------------------------------
# Print cumulative coverage summary
# -----------------------------------------------------------------------------
print_cumulative_summary() {
    local all_files_accumulator="$1"
    local all_helpers_accumulator="$2"
    local total_branches="$3"
    local all_file_branches_file="${4:-}"
    local all_helper_branches_file="${5:-}"
    
    # Get unique covered branches (disable pipefail temporarily)
    local unique_files unique_helpers
    unique_files=$(set +o pipefail; sort -u "$all_files_accumulator" 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')
    unique_helpers=$(set +o pipefail; sort -u "$all_helpers_accumulator" 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')
    [[ -z "$unique_files" || "$unique_files" == "0" ]] && unique_files=0
    [[ -z "$unique_helpers" || "$unique_helpers" == "0" ]] && unique_helpers=0
    local total_covered=$((unique_files + unique_helpers))
    
    # Calculate percentage
    local percent=0
    if [[ "$total_branches" -gt 0 ]]; then
        percent=$((total_covered * 100 / total_branches))
    fi
    
    # Color based on coverage
    local color icon
    if [[ "$percent" -eq 100 ]]; then
        color=$GREEN
        icon="✓"
    elif [[ "$percent" -ge 50 ]]; then
        color=$YELLOW
        icon="~"
    else
        color=$RED
        icon="✗"
    fi
    
    echo ""
    echo "========================================"
    echo "📊 CUMULATIVE COVERAGE (all values files)"
    echo "========================================"
    echo ""
    echo "📄 Unique file branches covered:"
    sort -u "$all_files_accumulator" 2>/dev/null | while read -r line; do
        [[ -n "$line" ]] && echo -e "  ${GREEN}✓${NC} $line"
    done
    echo ""
    echo "🔧 Unique helper branches covered:"
    sort -u "$all_helpers_accumulator" 2>/dev/null | while read -r line; do
        [[ -n "$line" ]] && echo -e "  ${GREEN}✓${NC} $line"
    done
    
    # Show uncovered branches if we have the all-branches files
    if [[ -n "$all_file_branches_file" ]] && [[ -f "$all_file_branches_file" ]]; then
        local uncovered_files
        uncovered_files=$(set +o pipefail; comm -23 <(sort -u "$all_file_branches_file") <(sort -u "$all_files_accumulator") 2>/dev/null | wc -l | tr -d ' ')
        [[ -z "$uncovered_files" ]] && uncovered_files=0
        
        if [[ "$uncovered_files" -gt 0 ]]; then
            echo ""
            echo "❌ Uncovered file branches:"
            comm -23 <(sort -u "$all_file_branches_file") <(sort -u "$all_files_accumulator") 2>/dev/null | while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${RED}✗${NC} $line"
            done
        fi
    fi
    
    if [[ -n "$all_helper_branches_file" ]] && [[ -f "$all_helper_branches_file" ]]; then
        local uncovered_helpers
        uncovered_helpers=$(set +o pipefail; comm -23 <(sort -u "$all_helper_branches_file") <(sort -u "$all_helpers_accumulator") 2>/dev/null | wc -l | tr -d ' ')
        [[ -z "$uncovered_helpers" ]] && uncovered_helpers=0
        
        if [[ "$uncovered_helpers" -gt 0 ]]; then
            echo ""
            echo "❌ Uncovered helper branches:"
            comm -23 <(sort -u "$all_helper_branches_file") <(sort -u "$all_helpers_accumulator") 2>/dev/null | while read -r line; do
                [[ -n "$line" ]] && echo -e "  ${RED}✗${NC} $line"
            done
        fi
    fi
    
echo ""
    echo "----------------------------------------"
    printf "📄 Files:   %d unique branches\n" "$unique_files"
    printf "🔧 Helpers: %d unique branches\n" "$unique_helpers"
    echo "----------------------------------------"
    printf "${color}${icon} TOTAL: %d/%d branches (%d%%)${NC}\n" \
        "$total_covered" "$total_branches" "$percent"
}

# -----------------------------------------------------------------------------
# Generate JSON coverage report
# -----------------------------------------------------------------------------
generate_json_report() {
    local all_files_accumulator="$1"
    local all_helpers_accumulator="$2"
    local total_branches="$3"
    local chart_path="$4"
    
    # Get unique covered branches
    local unique_files unique_helpers
    unique_files=$(sort -u "$all_files_accumulator" 2>/dev/null | wc -l | tr -d ' ')
    unique_helpers=$(sort -u "$all_helpers_accumulator" 2>/dev/null | wc -l | tr -d ' ')
    local total_covered=$((unique_files + unique_helpers))
    
    # Calculate percentage
    local percent=0
    if [[ "$total_branches" -gt 0 ]]; then
        percent=$(awk "BEGIN {printf \"%.2f\", ($total_covered / $total_branches) * 100}")
    fi
    
    # Build JSON
    # Build file branches JSON array
    local files_json
    files_json=$(sort -u "$all_files_accumulator" 2>/dev/null | grep -v '^$' | sed 's/.*/"&"/' | paste -sd ',' - | sed 's/,/, /g' || true)
    
    # Build helper branches JSON array
    local helpers_json
    helpers_json=$(sort -u "$all_helpers_accumulator" 2>/dev/null | grep -v '^$' | sed 's/.*/"&"/' | paste -sd ',' - | sed 's/,/, /g' || true)
    
    cat << EOF
{
  "version": "1.0",
  "chart": "$(basename "$chart_path")",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "summary": {
    "total_branches": $total_branches,
    "covered_branches": $total_covered,
    "coverage_percent": $percent,
    "file_branches_covered": $unique_files,
    "helper_branches_covered": $unique_helpers
  },
  "covered": {
    "files": [${files_json}],
    "helpers": [${helpers_json}]
  }
}
EOF
}

# -----------------------------------------------------------------------------
# Generate Cobertura XML coverage report
# Uses awk for grouping to avoid bash associative arrays compatibility issues
# -----------------------------------------------------------------------------
generate_cobertura_report() {
    local all_files_accumulator="$1"
    local all_helpers_accumulator="$2"
    local all_file_branches_file="$3"
    local all_helper_branches_file="$4"
    local total_branches="$5"
    local chart_path="$6"
    local output_file="$7"
    
    # Get unique covered branches
    local covered_files_list covered_helpers_list
    covered_files_list=$(mktemp)
    covered_helpers_list=$(mktemp)
    sort -u "$all_files_accumulator" 2>/dev/null | grep -v '^$' > "$covered_files_list" || true
    sort -u "$all_helpers_accumulator" 2>/dev/null | grep -v '^$' > "$covered_helpers_list" || true
    
    local unique_files unique_helpers total_covered
    unique_files=$(wc -l < "$covered_files_list" | tr -d ' ')
    unique_helpers=$(wc -l < "$covered_helpers_list" | tr -d ' ')
    total_covered=$((unique_files + unique_helpers))
    
    # Calculate rates
    local line_rate branch_rate
    if [[ "$total_branches" -gt 0 ]]; then
        line_rate=$(awk "BEGIN {printf \"%.4f\", $total_covered / $total_branches}")
        branch_rate="$line_rate"
    else
        line_rate="1.0"
        branch_rate="1.0"
    fi
    
    local timestamp
    timestamp=$(date +%s)
    
    # Create intermediate file with all branches and their coverage status
    # Format: filename|start_line|end_line|hits|branch_id
    local branches_data
    branches_data=$(mktemp)
    
    # Process all file branches
    while IFS= read -r branch || [[ -n "$branch" ]]; do
        [[ -z "$branch" ]] && continue
        # Parse branch format: filename:L<start>-L<end> or filename:L<start>-L<end>.<occurrence>
        local filename start_line end_line hits
        filename=$(echo "$branch" | sed 's/:L[0-9].*$//')
        # Extract start line: L<start>-L<end> -> start
        start_line=$(echo "$branch" | sed 's/.*:L\([0-9]*\)-L.*/\1/')
        # Extract end line: L<start>-L<end> -> end (remove any trailing .N occurrence)
        end_line=$(echo "$branch" | sed 's/.*-L\([0-9]*\).*/\1/')
        
        hits=0
        if grep -qxF "$branch" "$covered_files_list" 2>/dev/null; then
            hits=1
        fi
        
        echo "${filename}|${start_line}|${end_line}|${hits}|${branch}" >> "$branches_data"
    done < <(cat "$all_file_branches_file" 2>/dev/null)
    
    # Process helper branches
    while IFS= read -r branch || [[ -n "$branch" ]]; do
        [[ -z "$branch" ]] && continue
        # Parse branch format: filename:helper_name:L<start>-L<end>
        local filename start_line end_line hits
        filename=$(echo "$branch" | cut -d: -f1)
        # Extract start line
        start_line=$(echo "$branch" | sed 's/.*:L\([0-9]*\)-L.*/\1/')
        # Extract end line (remove any trailing .N occurrence)
        end_line=$(echo "$branch" | sed 's/.*-L\([0-9]*\).*/\1/')
        
        hits=0
        if grep -qxF "$branch" "$covered_helpers_list" 2>/dev/null; then
            hits=1
        fi
        
        echo "${filename}|${start_line}|${end_line}|${hits}|${branch}" >> "$branches_data"
    done < <(cat "$all_helper_branches_file" 2>/dev/null)
    
    # Generate XML using awk to group by filename
    {
        echo '<?xml version="1.0" ?>'
        echo '<!DOCTYPE coverage SYSTEM "http://cobertura.sourceforge.net/xml/coverage-04.dtd">'
        echo "<coverage line-rate=\"${line_rate}\" branch-rate=\"${branch_rate}\" lines-covered=\"${total_covered}\" lines-valid=\"${total_branches}\" branches-covered=\"${total_covered}\" branches-valid=\"${total_branches}\" complexity=\"0\" version=\"1.0\" timestamp=\"${timestamp}\">"
        echo "  <sources>"
        echo "    <source>templates</source>"
        echo "  </sources>"
        echo "  <packages>"
        echo "    <package name=\".\" line-rate=\"${line_rate}\" branch-rate=\"${branch_rate}\" complexity=\"0\">"
        echo "      <classes>"
        
        # Process branches data for both line coverage and branch coverage
        # Input format: filename|start_line|end_line|hits|branch_id
        
        local expanded_data branch_stats
        expanded_data=$(mktemp)
        branch_stats=$(mktemp)
        
        # Step 1: Calculate branch coverage stats per line (condition-coverage)
        # Group branches by filename|start_line and count total/covered
        sort -t'|' -k1,1 -k2,2n "$branches_data" 2>/dev/null | awk -F'|' '
        {
            filename = $1
            start_line = int($2)
            hits = int($4)
            key = filename "|" start_line
            
            total[key]++
            if (hits == 1) covered[key]++
            file[key] = filename
            line[key] = start_line
        }
        END {
            for (key in total) {
                cov = (key in covered) ? covered[key] : 0
                print file[key] "|" line[key] "|" total[key] "|" cov
            }
        }
        ' | sort -t'|' -k1,1 -k2,2n > "$branch_stats"
        
        # Step 2: Expand line ranges for line coverage (use max - line is covered if ANY branch touching it is covered)
        sort -t'|' -k1,1 -k2,2n "$branches_data" 2>/dev/null | awk -F'|' '
        {
            filename = $1
            start_line = int($2)
            end_line = int($3)
            hits = int($4)
            
            # Output one line per line number in range
            for (line_num = start_line; line_num <= end_line; line_num++) {
                print filename "|" line_num "|" hits
            }
        }
        ' | sort -t'|' -k1,1 -k2,2n | awk -F'|' '
        # Deduplicate: keep MAXIMUM hits for each file+line combination
        # A line is covered if ANY branch that includes it was executed
        {
            key = $1 "|" $2
            hits = int($3)
            if (!(key in seen) || hits > seen[key]) {
                seen[key] = hits
                file[key] = $1
                line[key] = $2
            }
        }
        END {
            for (key in seen) {
                print file[key] "|" line[key] "|" seen[key]
            }
        }
        ' | sort -t'|' -k1,1 -k2,2n > "$expanded_data"
        
        # Step 3: Generate XML combining line coverage and branch coverage
        awk -F'|' -v branch_file="$branch_stats" '
        BEGIN {
            current_file = ""
            file_lines_total = 0
            file_lines_covered = 0
            file_branches_total = 0
            file_branches_covered = 0
            lines_xml = ""
            
            # Load branch stats into arrays
            while ((getline branch_line < branch_file) > 0) {
                split(branch_line, parts, "|")
                bkey = parts[1] "|" parts[2]
                branch_total[bkey] = parts[3]
                branch_covered[bkey] = parts[4]
            }
            close(branch_file)
        }
        
        function output_class() {
            if (current_file != "") {
                if (file_lines_total > 0) {
                    line_rate = sprintf("%.4f", file_lines_covered / file_lines_total)
                } else {
                    line_rate = "1.0"
                }
                if (file_branches_total > 0) {
                    branch_rate = sprintf("%.4f", file_branches_covered / file_branches_total)
                } else {
                    branch_rate = "1.0"
                }
                print "        <class name=\"" current_file "\" filename=\"templates/" current_file "\" line-rate=\"" line_rate "\" branch-rate=\"" branch_rate "\" complexity=\"0\">"
                print "          <methods/>"
                print "          <lines>"
                print lines_xml
                print "          </lines>"
                print "        </class>"
            }
        }
        
        {
            filename = $1
            line_num = $2
            hits = $3
            
            if (filename != current_file) {
                output_class()
                current_file = filename
                file_lines_total = 0
                file_lines_covered = 0
                file_branches_total = 0
                file_branches_covered = 0
                lines_xml = ""
            }
            
            # Check if this line has branch conditions
            bkey = filename "|" line_num
            if (bkey in branch_total) {
                bt = branch_total[bkey]
                bc = branch_covered[bkey]
                pct = (bt > 0) ? int(bc * 100 / bt) : 100
                cond_cov = pct "% (" bc "/" bt ")"
                lines_xml = lines_xml "            <line number=\"" line_num "\" hits=\"" hits "\" branch=\"true\" condition-coverage=\"" cond_cov "\"/>\n"
                file_branches_total += bt
                file_branches_covered += bc
            } else {
                lines_xml = lines_xml "            <line number=\"" line_num "\" hits=\"" hits "\" branch=\"false\"/>\n"
            }
            
            file_lines_total++
            if (hits >= 1) {
                file_lines_covered++
            }
        }
        
        END {
            output_class()
        }
        ' "$expanded_data"
        
        rm -f "$expanded_data" "$branch_stats"
        
        echo "      </classes>"
        echo "    </package>"
        echo "  </packages>"
        echo "</coverage>"
    } > "$output_file"
    
    rm -f "$covered_files_list" "$covered_helpers_list" "$branches_data"
    
    log_success "Cobertura report written to: $output_file"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    local instrument_only=false
    local json_output=false
    local cobertura_file=""
    local chart_path=""
    local values_files=()
    local select_filters=()
    local helm_extra_args=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--select)
                if [[ -z "${2:-}" ]]; then
                    log_error "Option $1 requires an argument"
                    usage
                fi
                select_filters+=("$2")
                shift 2
                ;;
            --helm-args)
                if [[ -z "${2:-}" ]]; then
                    log_error "Option $1 requires an argument"
                    usage
                fi
                helm_extra_args="$2"
                shift 2
                ;;
            --instrument-only)
                instrument_only=true
                shift
                ;;
            --json)
                json_output=true
                shift
                ;;
            --cobertura)
                if [[ -z "${2:-}" ]]; then
                    log_error "Option $1 requires a file path argument"
                    usage
                fi
                cobertura_file="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$chart_path" ]]; then
                    chart_path="$1"
                else
                    values_files+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    [[ -z "$chart_path" ]] && usage
    
    # Expand directories to their .yaml files
    if [[ ${#values_files[@]} -gt 0 ]]; then
        local expanded_values=()
        for item in "${values_files[@]}"; do
            if [[ -d "$item" ]]; then
                # It's a directory - find all .yaml files
                local count=0
                while IFS= read -r -d '' yaml_file || [[ -n "$yaml_file" ]]; do
                    expanded_values+=("$yaml_file")
                    ((count++)) || true
                done < <(find "$item" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0 | sort -z)
                log_info "Expanded directory $item: $count yaml files (recursive)"
            elif [[ -f "$item" ]]; then
                expanded_values+=("$item")
            else
                log_warn "Skipping invalid path: $item"
            fi
        done
        values_files=("${expanded_values[@]}")
    fi
    
    # Validate
    validate_chart_path "$chart_path"
    
    log_info "Helm Coverage Analysis"
    log_info "Chart: $chart_path"
    
    # Create instrumented copy in a readable location
    local instrumented_dir
    if [[ "$instrument_only" == true ]]; then
        instrumented_dir="${chart_path}-instrumented"
        rm -rf "$instrumented_dir"
        mkdir -p "$instrumented_dir"
    else
        instrumented_dir=$(mktemp -d)
    fi
    cp -r "$chart_path"/* "$instrumented_dir/"
    
    # Determine if cobertura mode is enabled
    local cobertura_mode="false"
    [[ -n "$cobertura_file" ]] && cobertura_mode="true"
    
    # Instrument
    log_info "Instrumenting templates..."
    local total_branches
    total_branches=$(instrument_chart "$instrumented_dir" "$cobertura_mode" ${select_filters[@]+"${select_filters[@]}"})
    
    if [[ "$total_branches" -eq 0 ]]; then
        log_warn "No conditional branches found"
        [[ "$instrument_only" == false ]] && rm -rf "$instrumented_dir"
        exit 0
    fi
    
    log_success "Found $total_branches total branches"
    
    # Stop here if instrument-only mode
    if [[ "$instrument_only" == true ]]; then
        echo "" >&2
        log_success "Instrumented chart saved to: $instrumented_dir"
        log_info "You can inspect the files or run manually:"
        log_info "  helm template $instrumented_dir -f <values>"
        exit 0
    fi
    
    # Create accumulator files for cumulative coverage
    local all_files_accumulator all_helpers_accumulator
    all_files_accumulator=$(mktemp)
    all_helpers_accumulator=$(mktemp)
    
    # Extract all branch markers for uncovered reporting
    local all_file_branches all_helper_branches
    all_file_branches=$(mktemp)
    all_helper_branches=$(mktemp)
    extract_all_branches "$instrumented_dir" "$all_file_branches" "$all_helper_branches"
    
    # Determine if we should suppress per-file verbose output
    local quiet_mode=false
    [[ "$json_output" == true || -n "$cobertura_file" ]] && quiet_mode=true
    
    # Run coverage for each values file or default
    if [[ ${#values_files[@]} -eq 0 ]]; then
        log_info "Running with default values..."
        if [[ "$quiet_mode" == true ]]; then
            run_coverage "$instrumented_dir" "$total_branches" "$all_files_accumulator" "$all_helpers_accumulator" "" "$helm_extra_args" > /dev/null
        else
            run_coverage "$instrumented_dir" "$total_branches" "$all_files_accumulator" "$all_helpers_accumulator" "" "$helm_extra_args"
        fi
    else
        for vf in "${values_files[@]}"; do
            log_info "Running with: $(basename "$vf")"
            if [[ "$quiet_mode" == true ]]; then
                run_coverage "$instrumented_dir" "$total_branches" "$all_files_accumulator" "$all_helpers_accumulator" "$vf" "$helm_extra_args" > /dev/null
            else
                run_coverage "$instrumented_dir" "$total_branches" "$all_files_accumulator" "$all_helpers_accumulator" "$vf" "$helm_extra_args"
            fi
        done
    fi
    
    # Show summary with uncovered branches (not in JSON/Cobertura mode)
    if [[ "$quiet_mode" == false ]]; then
        print_cumulative_summary "$all_files_accumulator" "$all_helpers_accumulator" "$total_branches" "$all_file_branches" "$all_helper_branches"
    fi
    
    # Generate JSON output if requested
    if [[ "$json_output" == true ]]; then
        generate_json_report "$all_files_accumulator" "$all_helpers_accumulator" "$total_branches" "$chart_path"
    fi
    
    # Generate Cobertura XML output if requested
    if [[ -n "$cobertura_file" ]]; then
        generate_cobertura_report "$all_files_accumulator" "$all_helpers_accumulator" \
            "$all_file_branches" "$all_helper_branches" \
            "$total_branches" "$chart_path" "$cobertura_file"
    fi
    
    # Cleanup
    rm -rf "$instrumented_dir"
    rm -f "$all_files_accumulator" "$all_helpers_accumulator"
    rm -f "$all_file_branches" "$all_helper_branches"
    
    echo "" >&2
    log_success "Done"
}

main "$@"
