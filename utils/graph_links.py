#!/usr/bin/env python3
import re
import os
from datetime import datetime

months = []
counts = []

with open("links.md") as f:
    current_count = 0
    current_month = None
    for line in f:
        m = re.match(r'^# (\w+ \d{4})', line)
        if m:
            if current_month is not None:
                months.append(current_month)
                counts.append(current_count)
            try:
                current_month = datetime.strptime(m.group(1), "%B %Y")
            except ValueError:
                fixed = m.group(1).replace("Februrary", "February")
                current_month = datetime.strptime(fixed, "%B %Y")
            current_count = 0
        elif line.startswith("*"):
            current_count += 1
    if current_month is not None:
        months.append(current_month)
        counts.append(current_count)

# Sort chronologically
months, counts = zip(*sorted(zip(months, counts)))

max_count = max(counts)
try:
    cols = os.get_terminal_size().columns
except OSError:
    cols = 80
label_width = 9  # "Jan 2025 "
bar_width = cols - label_width - 5  # room for count label

for month, count in zip(months, counts):
    label = month.strftime("%b %Y")
    bar_len = int(count / max_count * bar_width) if max_count else 0
    print(f"{label:>8} {'█' * bar_len} {count}")
