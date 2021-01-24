import mwparserfromhell
import sys, re, os
import subprocess
import argparse
import textwrap
import logging
import requests
import itertools
from html.parser import HTMLParser
from html.entities import name2codepoint
import re, string

from pprint import pprint, pformat

class FormatDict(dict):
    def __missing__(self, key):
        return "{" + key + "}"

def const(cls):
    # Replace a class's attributes with properties,
    # and itself with an instance of its doppelganger.
    is_special = lambda name: (name.startswith("__") and name.endswith("__"))
    class_contents = {n: getattr(cls, n) for n in vars(cls) if not is_special(n)}
    def unbind(value):  # Get the value out of the lexical closure.
        return lambda self: value
    propertified_contents = {name: property(unbind(value))
                             for (name, value) in class_contents.items()}
    receptor = type(cls.__name__, (object,), propertified_contents)
    return receptor()  # Replace with an instance, so properties work.

@const
class Configuration:
    @const
    class Copyright:
        YEAR=2021
        SHORT='''Copyright %d Bradley Workman'''%YEAR
        LICENSE=textwrap.dedent('''\
            %s

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
            '''%SHORT)

    TERMINAL_WIDTH=80

    DEFAULT_SCRIPT=textwrap.dedent('''\
require 'data/npc/lib/NPC'

local {name} = NPC({greetings}, {greeting}, {farewell})

function onCreatureAppear(...)      {name}:onCreatureAppear(...)      end
function onCreatureDisappear(...)   {name}:onCreatureDisappear(...)   end
function onCreatureSay(...)         {name}:onCreatureSay(...)         end
function onThink(...)               {name}:onThink(...)               end
function onCreatureMove(...)        {name}:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  {name}:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      {name}:onPlayerEndTrade(...)      end

local engine = {name}.dialogEngine
        ''')

    GREETINGS={"hello","hi"}

    FAREWELLS={"bye"}

    PROGRAM="Open Tibia NPC script generator"
    VERSION="0.0.1-alpha"
    DESCRIPTION=textwrap.dedent('''\
        This program is designed to parse a wikimedia tibia NPC transcript source and output an NPC lua script that matches -- quests must be done by hand!
        ''');
    EPILOG=textwrap.dedent('''\
        %s

        MIT License (use --license to print in full)
        '''%Copyright.SHORT)

def wrap(text, width=Configuration.TERMINAL_WIDTH, **kwargs):
    if "replace_whitespace" not in kwargs:
        kwargs["replace_whitespace"]=False

    if "break_on_hyphens" not in kwargs:
        kwargs["break_on_hyphens"]=False

    return "\n".join(textwrap.wrap(text, width, **kwargs))

class LicenseAction(argparse.Action):
    def __init__(self, option_strings, dest, nargs=None, **kwargs):
        kwargs["required"] = False
        kwargs["nargs"] = 0
        super(LicenseAction, self).__init__(option_strings, dest, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        print(wrap(Configuration.Copyright.LICENSE))
        sys.exit()

def transform(template):
    def _group(lines):
        def _chunk(lines):
            lock = 0
            for step in range(1,len(lines)):
                if lines[step].startswith("''Player'':"):

                    if 1 == step - lock:
                        logging.warning("found no NPC response to challenge: %s"%lines[lock])

                    yield (lines[lock], lines[lock+1:step])
                    lock = step

            yield(lines[lock], lines[lock+1:])


        # an exchange is a grouping of 1 player chat (challenge) to a list of NPC responses
        # return a list of exchanges

        # find the first challenge
        i = 0
        while i < len(lines) and not lines[i].startswith("''Player'':"): i+=1

        if i != 0:
            logging.warning("transcript did not start with a player chat. Discarding %d messages"%i)

        lines = lines[i:]

        if len(lines) < 2:
            logging.warning("transcript did not contain any exchanges.")
            return []

        return list(_chunk(lines))

    def _parse_exchange(exchange):
        class TextHTMLParser(HTMLParser):
            # TODO handle the case where we get more than one data; do we need to worry about tags?
            def handle_data(self, data):
                self.data = data

        def _parse_challenge(challenge):
            logging.debug("parse challenge: %s"%challenge)

            m = re.match(r"''(Player)'': (.*)", challenge)
            return {
                "speaker": m.group(1),
                "values": [x.strip("'") for x in m.group(2).split(""" ''or'' """)]
            }

        def _parse_response(response):
            logging.debug("parse response: %s"%response)

            m = re.match(r"(.*): (.*)", response)

            return {
                "speaker": m.group(1).strip("[]"),
                "value": re.sub("\\[\\[[^|]*\\|(.*)\\]\\]", "\\g<1>", m.group(2))
            }

        logging.debug("parsing exchange")

        html_parser = TextHTMLParser()

        html_parser.reset()
        html_parser.feed(exchange[0])
        challenge = _parse_challenge(html_parser.data)

        dialog = {"challenge": challenge, "responses":[]}

        for response in exchange[1]:
            html_parser.reset()
            html_parser.feed(response)
            dialog["responses"].append(_parse_response(html_parser.data))

        speakers = set([x["speaker"] for x in dialog["responses"]])
        if len(speakers) != 1:
            logging.warning("found responses from more than one NPC! %s"%pformat(speakers))

        logging.debug("Dialog%s"%pformat(dialog, indent=4))

        return dialog

    def _to_lua_string(message):

        logging.debug("converting to lua string from: %s"%message)

        message = "'%s'"%message.replace("'", "\\'");

        logging.debug("converted: %s"%message)

        return message

    def _to_lua_string_or_list(messages):
        messages = [_to_lua_string(m) for m in messages]

        if len(messages) > 1:
            return "{%s}"%(",".join(messages))
        elif len(messages) == 1:
            return messages[0]

        return _to_lua_string("")

    def _prepare_response(response):

        logging.debug("preparing response from: %s"%response)

        # TODO dont use a regex to parse this, it doesnt handle beginning or ending on a single quote
        # escape single quotes in string
        message = re.sub("'''(([^']+[']{0,2})+)'''","{\\g<1>}", response["value"])

        logging.debug("after sub: %s"%message)

        message = message.replace("''Player''", "|PLAYERNAME|")

        logging.debug("prepared: %s"%message)

        return message

    def _is_greeting(dialog):
        return len(Configuration.GREETINGS & set([x.lower() for x in dialog["challenge"]["values"]])) > 0

    def _greet(dialog):
        responses = [_prepare_response(r) for r in dialog["responses"]]

        if len(responses) < 1:
            logging.warning("NPC will not respond to player when entering dialog")

        return _to_lua_string_or_list(responses)

    def _is_farewell(dialog):
        return len(Configuration.FAREWELLS & set([x.lower() for x in dialog["challenge"]["values"]])) > 0

    def _farewell(dialog):
        responses = [_prepare_response(r) for r in dialog["responses"]]

        if len(responses) < 1:
            logging.warning("NPC will say nothing when exiting dialog")

        return _to_lua_string_or_list(responses)

    def _general(dialog):
        template = """engine.all.connect(%s,engine.State(%s))"""

        responses = [_prepare_response(r) for r in dialog["responses"]]

        if len(responses) < 1:
            logging.warning("NPC has an empty response")

        challenges = dialog["challenge"]["values"]

        if len(challenges) < 1:
            logging.warning("NPC has an empty query")

        return [template%(_to_lua_string_or_list(challenges), _to_lua_string_or_list(responses))]
        

    if len(template.params) == 0:
        raise Exception("empty transcript detected")
    elif len(template.params) > 1:
        logging.warning("multiple transcripts detected, only parsing one")

    exchanges = _group([x.strip() for x in template.get(1).value.splitlines() if x.strip()])

    logging.debug("found %d exchanges"%len(exchanges))

    if len(exchanges) == 0:
        raise Exception("empty dialog detected")

    greetings = _to_lua_string_or_list(Configuration.GREETINGS)

    if len(Configuration.GREETINGS) < 1:
        logging.warning("no greetings found, NPC will not respond to anything")

    if len(Configuration.FAREWELLS) < 1:
        logging.warning("no farewells found, NPC will not exit dialog")

    buf = [Configuration.DEFAULT_SCRIPT]

    speaker = None
    greeting = None
    farewell = None

    for dialog in [_parse_exchange(ex) for ex in exchanges]:
        if not speaker:
            speaker = dialog["responses"][0]["speaker"]
            speaker = re.sub(r'[^a-zA-Z\s]+', '', speaker.strip())
            speaker = re.sub(r'[\s]+', '_', speaker)

        if _is_greeting(dialog):
            logging.debug("_is_greeting")
            greeting = _greet(dialog)
        elif _is_farewell(dialog):
            logging.debug("_is_farewell")

            farewell = _farewell(dialog)

            buf.append("")
            buf.append("""engine.all.to({farewells}, engine.State(%s))""" % farewell)
            buf.append("")
        else:
            logging.debug("is _general")
            buf.extend(_general(dialog))

    if not greeting:
        logging.warning("NPC had no greeting in transcript")

    if not farewell:
        logging.warning("NPC had no farewell in transcript")

    output = "\n".join(buf)

    return string.Formatter().vformat(output, (), FormatDict({\
        "name":speaker.lower(),
        "greeting":greeting,
        "farewell":farewell,
        "greetings":_to_lua_string_or_list(Configuration.GREETINGS),
        "farewells":_to_lua_string_or_list(Configuration.FAREWELLS)}))

def from_wiki_log(fstr):
    logging.debug("opening transcript file...%s"%fstr)

    with open(fstr, "r") as file:
        wikicode = mwparserfromhell.parse(file.read())
        for template in wikicode.filter_templates():
            if template.name.matches("Infobox Transcript"):
                logging.debug("transforming transcript template")
                try:
                    return transform(template)
                except Exception as ex:
                    logging.exception('',exc_info=ex)

    return ""

def main(args):
    log_level = getattr(logging, args.log_level.upper(), None)

    if not isinstance(log_level, int):
        raise ValueError('Invalid log level: %s'%args.log_level)

    logging.basicConfig(filename=args.out, format='%(levelname)s:%(message)s', level=log_level)
    logging.debug(args)

    print(from_wiki_log(args.file))

if (__name__ == '__main__'):
    parser = argparse.ArgumentParser(
        prog=Configuration.PROGRAM,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=wrap(Configuration.DESCRIPTION),
        epilog=Configuration.EPILOG)

    parser.add_argument("--version","-v", action="version", version="%%(prog)s %s"%Configuration.VERSION)
    parser.add_argument("--license", "-l", action=LicenseAction, help="show program's license and exit")
    parser.add_argument("--log-level", required=False, metavar="<level>", help= "set the logging level to one of [DEBUG,INFO,WARNING,ERROR,CRITICAL]", default="INFO", dest="log_level")
    parser.add_argument("--out-file", "-o", metavar="<file>", required=False, help="output file for logging", dest="out")
    parser.add_argument("file", metavar="<transcript-file>", help="input file to process as transcript")

    args = parser.parse_args()

    main(args)