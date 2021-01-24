import generate_npc_script

from pathlib import Path
import os
import logging

logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.DEBUG)


for path in Path('~/Desktop/8.6 Chat Logs').expanduser().glob('**/*.log'):
    dest = os.path.join(path.parent, path.name[:-len(path.suffix)] + ".lua")

    with open(dest, 'w') as file:
        file.write("\n".join(generate_npc_script.from_wiki_log(str(path))))