from xml.dom import minidom
from pprint import pprint
from pathlib import Path

def get_spawned_monsters(fstr):
    with open(fstr,'r') as Test_file:
        xmldoc = minidom.parse(Test_file)

    names = set()
    monsters = xmldoc.getElementsByTagName("monster")
    for monster in monsters:
        names.add(monster.getAttribute("name"))

    return names

def get_monster_name(fstr):
    with open(fstr,'r') as Test_file:
        xmldoc = minidom.parse(Test_file)

    return xmldoc.documentElement.getAttribute("name")

monsters = get_spawned_monsters('data/world/map-spawn.xml')

for path in Path('data/monster').glob('**/*.xml'):
    monster = get_monster_name(str(path))

    if monster not in monsters:
        print("monster not found in spawns:",str(path))

