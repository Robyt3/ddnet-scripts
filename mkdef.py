#!/usr/bin/env python3
"""Turn `objdump -p some.dll` output into a .def file (stdin -> stdout)."""
import re
import sys

dllname = sys.argv[1]
print(f"LIBRARY {dllname}")
print("EXPORTS")
in_table = False
count = 0
for line in sys.stdin:
    if "[Ordinal/Name Pointer] Table" in line:
        in_table = True
        continue
    if in_table:
        m = re.match(r"\s+\[\s*\d+\]\s+(\S+)\s*$", line)
        if m:
            print(m.group(1))
            count += 1
        elif line.strip():
            in_table = False
if count == 0:
    sys.exit("no exports found in objdump output")
