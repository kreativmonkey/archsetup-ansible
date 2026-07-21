import os

path = '/etc/systemd/system/ollama.service.d/override.conf'
with open(path, 'r') as f:
    lines = f.readlines()

new_line = 'Environment="OLLAMA_JINJA=1"\n'
if new_line not in lines:
    lines.append(new_line)

with open(path, 'w') as f:
    f.writelines(lines)
