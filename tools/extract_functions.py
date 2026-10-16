#!/usr/bin/env python3
"""
tools/extract_functions.py

Extracts function declarations, signatures, line numbers, and preceding comment headers
from all Defold Lua files (.lua, .script, .gui_script, .render_script).

Designed for AI agent indexing and rapid developer lookups without opening full files.
"""

import os
import sys
import re
import json
import argparse
from typing import List, Dict, Any, Optional

DEFOLD_EXTENSIONS = {".lua", ".script", ".gui_script", ".render_script"}

# Regex patterns for Lua / Defold functions:
# 1. Standard / Method / Local: [local] function [table.[:]]name(params)
FUNC_DECL_PATTERN = re.compile(
    r"^\s*(?:(local)\s+)?function\s+([A-Za-z0-9_.:]+)\s*\((.*?)\)"
)
# 2. Assignment syntax: [local] name = function(params) or table.name = function(params)
FUNC_ASSIGN_PATTERN = re.compile(
    r"^\s*(?:(local)\s+)?([A-Za-z0-9_.:]+)\s*=\s*function\s*\((.*?)\)"
)

# Pattern to track block depth for 'function ... end'
BLOCK_START_PATTERN = re.compile(r"\b(function|then|do|repeat)\b")
BLOCK_END_PATTERN = re.compile(r"\b(end|until)\b")


def extract_comments_preceding(lines: List[str], func_line_idx: int) -> List[str]:
    """Collects comments immediately above the function definition."""
    comments = []
    idx = func_line_idx - 1
    while idx >= 0:
        line = lines[idx].strip()
        if line.startswith("--"):
            # Strip comment prefix
            clean = line.lstrip("-").strip()
            comments.insert(0, clean)
            idx -= 1
        elif line == "":
            # Stop if there's an empty line separating comments from function
            break
        else:
            break
    return comments


def find_function_end(lines: List[str], start_idx: int) -> int:
    """Finds the matching 'end' line for the function starting at start_idx."""
    depth = 0
    total_lines = len(lines)
    for i in range(start_idx, total_lines):
        line = lines[i]
        # Ignore comments
        code = re.sub(r"--.*$", "", line).strip()
        if not code:
            continue

        # Count starts
        # Match standalone 'function', 'if ... then', 'do', 'repeat'
        starts = len(BLOCK_START_PATTERN.findall(code))
        ends = len(BLOCK_END_PATTERN.findall(code))

        depth += starts - ends
        if depth <= 0 and i > start_idx:
            return i + 1  # 1-indexed line
    return start_idx + 1


def parse_defold_file(file_path: str) -> List[Dict[str, Any]]:
    """Parses a single Defold Lua/script file and returns all extracted functions."""
    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except Exception as e:
        return [{"error": f"Failed to read file: {e}", "file": file_path}]

    functions = []

    for i, line in enumerate(lines):
        decl_match = FUNC_DECL_PATTERN.match(line)
        assign_match = FUNC_ASSIGN_PATTERN.match(line) if not decl_match else None

        match = decl_match or assign_match
        if match:
            is_local = bool(match.group(1))
            name = match.group(2)
            params = match.group(3).strip()
            start_line = i + 1
            end_line = find_function_end(lines, i)
            comments = extract_comments_preceding(lines, i)

            # Classify function scope/type
            if is_local:
                fn_type = "local"
            elif ":" in name:
                fn_type = "method"
            elif "." in name:
                fn_type = "table_function"
            elif name in {"init", "final", "update", "fixed_update", "on_message", "on_input", "on_reload"}:
                fn_type = "defold_lifecycle"
            else:
                fn_type = "global"

            functions.append({
                "name": name,
                "params": params,
                "signature": f"{'local ' if is_local else ''}function {name}({params})",
                "type": fn_type,
                "file": os.path.abspath(file_path).replace("\\", "/"),
                "relative_file": os.path.relpath(file_path).replace("\\", "/"),
                "start_line": start_line,
                "end_line": end_line,
                "doc": " ".join(comments) if comments else "",
                "doc_lines": comments
            })

    return functions


def scan_directory(root_dir: str, name_filter: Optional[str] = None) -> List[Dict[str, Any]]:
    """Scans root_dir recursively for all Defold code files."""
    results = []
    regex_filter = re.compile(name_filter, re.IGNORECASE) if name_filter else None

    for root, dirs, files in os.walk(root_dir):
        # Exclude hidden or build directories
        dirs[:] = [d for d in dirs if not d.startswith(".") and d not in {"build", ".git", "tmp"}]
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in DEFOLD_EXTENSIONS:
                full_path = os.path.join(root, file)
                file_funcs = parse_defold_file(full_path)
                for fn in file_funcs:
                    if regex_filter:
                        if not (regex_filter.search(fn.get("name", "")) or regex_filter.search(fn.get("signature", ""))):
                            continue
                    results.append(fn)

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Extract functions and docstrings from Defold Lua files."
    )
    parser.add_argument(
        "--path",
        "-p",
        default=".",
        help="Path to a file or directory to scan (default: current directory)"
    )
    parser.add_argument(
        "--search",
        "-s",
        default=None,
        help="Optional search string or regex to filter function names"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results in JSON format"
    )

    args = parser.parse_args()
    target_path = os.path.abspath(args.path)

    if not os.path.exists(target_path):
        print(f"Error: Target path does not exist: {target_path}", file=sys.stderr)
        sys.exit(1)

    if os.path.isfile(target_path):
        results = parse_defold_file(target_path)
        if args.search:
            pattern = re.compile(args.search, re.IGNORECASE)
            results = [r for r in results if pattern.search(r.get("name", "")) or pattern.search(r.get("signature", ""))]
    else:
        results = scan_directory(target_path, name_filter=args.search)

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        if not results:
            print(f"No functions found matching query (path='{args.path}', search='{args.search or ''}').")
            return

        print(f"{'FILE':<35} | {'LINE':<8} | {'SIGNATURE':<40} | {'DOC SUMMARY'}")
        print("-" * 110)
        for r in results:
            rel = r.get("relative_file", r.get("file", ""))
            if len(rel) > 34:
                rel = "..." + rel[-31:]
            sig = r.get("signature", "")
            if len(sig) > 39:
                sig = sig[:36] + "..."
            doc = r.get("doc", "")
            if len(doc) > 40:
                doc = doc[:37] + "..."
            print(f"{rel:<35} | L{r.get('start_line', 0):<7} | {sig:<40} | {doc}")


if __name__ == "__main__":
    main()
