#!/usr/bin/env python3
"""Update overtake messages in extra_cfg.yml"""

# Read file
with open('cfg/extra_cfg.yml', 'r') as f:
    lines = f.readlines()

# Define new messages
new_collision = [
    "  - Wall tap L\n",
    "  - 300HP to guardrail\n",
    "  - Insurance claim time\n",
    "  - Bodykit RIP\n",
    "  - Paint penalty\n",
    "  - Ramen fund hit\n",
    "  - Rails don't move\n",
    "  - GG widebody\n",
    "  - Aero delete\n",
    "  - Skill issue\n",
]

new_overtake = [
    "  - Styled on em\n",
    "  - Too easy\n",
    "  - Gap secured\n",
    "  - Gapped\n",
    "  - Outplayed\n",
    "  - Clean AF\n",
    "  - Checked mirrors?\n",
    "  - Pace difference\n",
    "  - Not even close\n",
    "  - Built different\n",
]

new_close = [
    "  - Paint trade accepted\n",
    "  - Millimeter perfect\n",
    "  - Mirror check next time\n",
    "  - Sent it\n",
    "  - Ballsy\n",
    "  - 1cm gap\n",
    "  - Risky business\n",
    "  - Heart rate: 180\n",
    "  - Lucky AF\n",
    "  - Almost binned it\n",
    "  - Insurance claim avoided\n",
    "  - Pucker factor: 12\n",
]

output = []
state = None

for i, line in enumerate(lines):
    if 'CollisionMessages:' in line:
        output.append(line)
        output.extend(new_collision)
        state = 'collision'
    elif 'OvertakeMessages:' in line and state != 'overtake_done':
        output.append(line)
        output.extend(new_overtake)
        state = 'overtake_done'
    elif 'CloseOvertakeMessages:' in line:
        output.append(line)
        output.extend(new_close)
        state = 'close_done'
    elif state and line.strip().startswith('-'):
        # Skip old messages
        continue
    elif state and line.strip() and not line.startswith(' '):
        # Hit next section
        state = None
        output.append(line)
    elif not state:
        output.append(line)

with open('cfg/extra_cfg.yml', 'w') as f:
    f.writelines(output)

print("✓ Updated messages")
