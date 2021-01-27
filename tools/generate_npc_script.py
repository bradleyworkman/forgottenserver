import mwparserfromhell
import sys, re, os, string, argparse, textwrap, logging, json

from json import JSONEncoder
from pprint import pformat
from collections import defaultdict

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

        local {__npc__} = NPC({__player_greetings__}, {__npc_greetings__}, {__farewell__})

        function onCreatureAppear(...)      {__npc__}:onCreatureAppear(...)      end
        function onCreatureDisappear(...)   {__npc__}:onCreatureDisappear(...)   end
        function onCreatureSay(...)         {__npc__}:onCreatureSay(...)         end
        function onThink(...)               {__npc__}:onThink(...)               end
        function onCreatureMove(...)        {__npc__}:onCreatureMove(...)        end
        function onPlayerCloseChannel(...)  {__npc__}:onPlayerCloseChannel(...)  end
        function onPlayerEndTrade(...)      {__npc__}:onPlayerEndTrade(...)      end

        local engine = {__npc__}.dialogEngine
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

    CLOSING_TAGS =  ['A', 'ABBR', 'ACRONYM', 'ADDRESS', 'APPLET',
                'B', 'BDO', 'BIG', 'BLOCKQUOTE', 'BUTTON',
                'CAPTION', 'CENTER', 'CITE', 'CODE',
                'DEL', 'DFN', 'DIR', 'DIV', 'DL',
                'EM', 'FIELDSET', 'FONT', 'FORM', 'FRAMESET',
                'H1', 'H2', 'H3', 'H4', 'H5', 'H6',
                'I', 'IFRAME', 'INS', 'KBD', 'LABEL', 'LEGEND',
                'MAP', 'MENU', 'NOFRAMES', 'NOSCRIPT', 'OBJECT',
                'OL', 'OPTGROUP', 'PRE', 'Q', 'S', 'SAMP',
                'SCRIPT', 'SELECT', 'SMALL', 'SPAN', 'STRIKE',
                'STRONG', 'STYLE', 'SUB', 'SUP', 'TABLE',
                'TEXTAREA', 'TITLE', 'TT', 'U', 'UL',
                'VAR', 'BODY', 'COLGROUP', 'DD', 'DT', 'HEAD',
                'HTML', 'LI', 'P', 'TBODY','OPTION', 
                'TD', 'TFOOT', 'TH', 'THEAD', 'TR']

    NON_CLOSING_TAGS = ['AREA', 'BASE', 'BASEFONT', 'BR', 'COL', 'FRAME',
                'HR', 'IMG', 'INPUT', 'ISINDEX', 'LINK',
                'META', 'PARAM']

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

class State(tuple):
    """ NPC dialog state (ie a response) """
    def __repr__(self):
        return "{%s}"%",".join([luaify(x) for x in self])

def highlight(phrases, state):
    """ get a new state where key substrings have been braced
    Arguments:
    phrases -- a list of keywords to highlight
    state   -- a dialog state representing the NPC response to highlight

    Return:
    a new State that is a copy of the old state, but with keywords highlighted (braced ex {foo} for foo in phrases)
    """
    return State(map(lambda x: add_braces(phrases, x), state))

class PythonObjectEncoder(JSONEncoder):
    """ Helper to properly serialize sets as json (by turning them into a list) """
    def default(self, obj):
        if isinstance(obj, (list, dict, str, int, float, bool, type(None))):
            return JSONEncoder.default(self, obj)
        elif type(obj) is set:
            return list(obj)

        return '__python_object__'

def luaify(a):
    """ serialize a python value to lua
    Arguments:
    a -- any python value to turn into a valid lua string

    Return:
    valid lua string representing the value
    """
    if type(a) in [set, list]:
        return "{%s}"%",".join([luaify(x) for x in a])
    elif type(a) in [dict, defaultdict]:
        buf = ""
        for k,v in a.items():
            buf += "%s=%s,"%(k,luaify(v))
        return "{%s}"%buf[:-1]
    elif a is None:
        return "nil"
    elif type(a) is str:
        return "'%s'"%a.replace("'", "\\'")
    else: # bool, int, everything else
        return str(a)

def flatten(a):
    """ convert a list, set, or state into an unnested structure (ex if the state had exactly one response in it, return a string instead)

    Arguments:
    a -- a python value

    Return:
    a new value if the value could be flattened or is empty, else the original value
    """
    if type(a) in [set, list, State]:
        if len(a) == 1:
            return flatten(list(a)[0])

        if len(a) == 0:
            return None

    return a

def is_word_end(message, i):
    """ predicate for determining if position i in message is the last character of a "word"

    Arguments:
    message -- a string to check
    i       -- index into message

    Return:
    True if the character at position i in message represents the last character in a "word", else False

    Note:
    The last position in a string is always considered the end of a word

    A "word" is considered at the end before an "s" or "'s" 

    Words ending in an s will be considered to have two ends, one before the final s and one at the s, either index will return True
    """

    # last character is word end
    if i >= len(message) - 1:
        return True

    tail = message[i+1:]

    return None is not re.match(r'[\W]', tail)\
        or None is not re.match(r'[sS][\W]', tail)\
        or None is not re.match(r'\'[sS][\W]', tail)

def is_word_beg(message, i):
    """ predicate for determining if position i in message is the first character in a "word"

    Arguments:
    message -- a string to check
    i       -- index into message

    Return:
    True if the character at position i in message represents the first character of a "word", else False

    Note:
    The first position in a string is always considered the beginning of a word
    """
    return i == 0 or re.match(r'[\s][\w]', message[i-1:]) is not None

def next_word_beg(message, i):
    """ find the position of the next word in message from offset i

    Arguments:
    message -- a string to search for the next word
    i       -- an index in message to start the search from

    Return:
    An index into message where the next word can be found after position i, or len(message) if no such word is found

    Note:
    Returns i if i is already the beginning of a word, callers should be sure to advance beyond the previous word beginning before calling
    
    """
    while i < len(message) and not is_word_beg(message, i): i += 1

    return i

def add_braces(phrases, message):
    """ brace substrings in message

    Arguments:
    phrases -- list of substrings to search message for
    message -- string to search and brace substrings in

    Return:
    New string that is a copy of message, except where substrings found in phrases have been braced (ex {foo} for foo in phrases)

    Note:
    This function does not brace substrings that occur inside of other substrings; it always considers the longest substring match at the earliest position to be the one to brace
    """
    start = 0
    haystack = message.lower()

    while start < len(message):
        match = None

        # find the longest match in phrases starting at start
        for phrase in [x.lower() for x in phrases]:
            end = start + len(phrase)

            if is_word_end(message, end - 1) and phrase == haystack[start:end]:
                if not match or len(phrase) > len(match):
                    match = phrase

        if match:
            end = start + len(match)
            sub = "{" + message[start:end] + "}"
            message = message[:start] + sub + message[end:]
            haystack = message.lower()

            start += len(sub)

        start = next_word_beg(message, start + 1)

    return message

def remove_braces(text):
    """ strip all braces from a text """
    return re.sub(r'{|}',"",text)

def replace_wiki_links(text):
    """ replace wiki link markup in text """
    # match [[foo|bar]] or [[bar]] and return bar
    return re.sub(r'\[\[([^\[|]+[|])?([^\[]+)\]\]',"\\g<2>", text)

def remove_html_markup(s):
    """ strip html markup (but not text content) from a text

    Arguments:
    s -- a string to strip all valid HTML tags from

    Return:
    New string that is a copy of s with all valid HTML5 tags stripped from it

    Note:
    This function fails to properly remove tags that exist inside of a comment, therefore it throws an exception if any HTML comment is found inside of s.

    It explicitly allows angle brackets (<>) inside of attribute values while parsing, this prevents it from stopping early while inside of an attribute. However, it does not allow escaped single or double quotes inside of an attribute, it will fail to strip a tag with this combination (ex <foo bar="\">">)

    Deliberately chose not to use python's library HTMLParser because it was difficult to remove only valid HTML tags from the text and leave other sgml tags alone. (ex NPC says '<sigh>')

    TODO:
    replace with an actual html parser that can successfully navigate comments and attributes with html tags/angle brackets in them
    """
    if s.find("<--") != -1:
        logging.error("HTML comment found in text, will not successfully remove html markup")

    def _get_tag_name(t):
        name = t[1:t.find(' ')]
        return name.rstrip('/')
     
    in_tag = False
    in_quote = False
    data = ""
    tag = ""

    for c in s:
        if c == '<' and not in_quote:
            in_tag = True
        elif c == '>' and not in_quote:
            in_tag = False
            tag = tag + c

            name = _get_tag_name(tag).upper()
            if not name in (Configuration.CLOSING_TAGS + Configuration.NON_CLOSING_TAGS):
                data = data + tag
            elif name == "BR":
                data = data + "\n"

            tag = ""
        elif in_tag and (c == '"' or c == "'"):
            in_quote = not in_quote
        elif not in_tag:
            data = data + c
            
        if in_tag:
            tag = tag + c

    return data

def transform(template):
    """ convert text of a tibia wiki transcript into a valid lua script representing the NPC and their dialog tree

    Arguments:
    template -- a string containing dialog from tibia wiki

    Return:
    New string that is a valid lua script representing an NPC with the dialog tree contained within template
    """
    def _group(text):
        """ generate challenge:response pairs from a text of tibia wiki dialog (player challenges, npc responses)

        Arguments:
        text -- a string of text to treat as a dialog

        Return:
        a (challenge, response) pair, where challenge is a string of everything the player said, and response is a list of strings of everything the NPC said in return

        Note:
        assumes exactly 1 NPC is talking in response to a players challenge

        A challenge is expected to be a string beginning with "''Player'': " and followed by one or more keyphrases separated by an "or"

        A response is simple a list of strings beginning with "<npc name>: " followed by text the NPC said
        """
        for exchange in [x.strip() for x in text.split("''Player'':")[1:] if x.strip()]:
            i = exchange.find("\n")

            query = "''Player'': "+exchange[:i].strip()

            result = exchange[i:].strip().replace("\n","")

            npc = result.strip().split(':')[0]

            responses = ["%s: "%npc + r.strip() for r in result.split("%s:"%npc) if r.strip()]

            yield (query, responses)

    def _parse_exchange(exchange):
        """ convert a challenge:response pair returned from _group into a Dialog object

        Arguments:
        exchange -- a challenge,response pair as returned from _group

        Return:
        New Dialog object representing this challenge response

        Note:
        Dialog has only the keyphrases said by the player, the text responses from the NPC and the name of the NPC
        """
        def _parse_challenge(challenge):
            """ get the keyphrases from a challenge returned from _group

            Arguments:
            challenge -- a string representing a player challenge from _group

            Return:
            a list of keyphrases contained inside of the challenge
            """
            def _get_keyphrases(c):
                """ get keyphrases from the text content of a challenge

                Arguments:
                c -- the text content of a challenge (ie everything after "''Player'': ")

                Return:
                a list of keyphrases see _group
                """
                c = re.sub(r'\s+', ' ', re.sub(r'\'{2,}', " ", c))

                lock = 0
                step = 1
                words = [w.strip() for w in re.split(" ",c) if w.strip()]
                for step in range(1, len(words)):
                    if words[step] == "or":
                        yield " ".join(words[lock:step])
                        lock = step + 1

                yield " ".join(words[lock:])

            return list(_get_keyphrases(re.match(r"[^:]+:(.*)", challenge).group(1)))

        def _parse_response(response):
            """ get the text content of a response returned from _group

            Arguments:
            response -- a string representing a single NPC response from the list returend by _group

            Return:
            a response object that includes the npc that said the text as well as the message

            Note:
            Mutates message by replacing ''Player'' with |PLAYERNAME| and removing all occurrences of 2 or more single quotes (a wiki markup) for convenience with the lua scripting
            """
            m = re.match(r"([^:]+): (.*)", response)

            message = m.group(2)
            message = message.replace("''Player''", "|PLAYERNAME|")
            message = re.sub(r'\'{2,}', " ", message)

            return {
                "npc": m.group(1),
                "message": message
            }

        dialog = {"key_phrases": _parse_challenge(exchange[0]), "responses":[_parse_response(r) for r in exchange[1]]}

        logging.debug("Dialog%s"%json.dumps(dialog))

        return dialog

    def _is_greeting(dialog, state):
        """ predicate for determining if a particular dialog object or NPC state represents a greeting (see Configuration.GREETINGS)

        Arguments:
        dialog -- a dialog object as returned by _parse_exchange
        state  -- a state object representing an NPC response

        Return:
        True if the dialog represents a greeting according to Configuration.GREETINGS or if the state represents a greeting response according to previously parsed greetings

        Note:
        We need to look the state up, because tibia wiki transcripts often include the same response multiple times in different locations. This NPC may have a single "greet" state, but it might be triggered by words not in Configuration.GREETINGS
        """
        for phrase in dialog["key_phrases"]:
            if phrase in Configuration.GREETINGS: return True

        for _,states in greetings.items():
            if state in states: return True

        return False

    def _is_farewell(dialog, state):
        """ predicate for determining if a particular dialog object or NPC state represents a farewell (see Configuration.Farewell)

        Arguments:
        dialog -- a dialog object as returned by _parse_exchange
        state  -- a state object representing an NPC response

        Return:
        True if the dialog represents a farewell according to Configuration.FAREWELLS or if the state represents a farewell response according to previously parsed farewells

        Note:
        We need to look the state up, because tibia wiki transcripts often include the same response multiple times in different locations. This NPC may have a single "farewell" state, but it might be triggered by words not in Configuration.FAREWELL
        """        
        for phrase in dialog["key_phrases"]:
            if phrase in Configuration.FAREWELLS: return True

        for _,states in farewells.items():
            if state in states: return True

        return False

    def _get_npc_greetings(greetings):
        """ get a flattened list of all the NPC responses in a dictionary of greetings (ie unique states reached from all of the different greeting keywords)

        Arguments:
        greetings -- a dictionary mapping key phrases that are greetings to lists of NPC states

        Return:
        A set containing the NPC states that are reached from all of the greetings

        Note:
        A single npc state can include multiple things an NPC is to say in succession all at once to a response, but we map a greeting to a list of states to represent responding in different ways to the same greeting
        """
        greet = set()
        for states in greetings.values():
            greet |= states

        return flatten(greet)

    def _get_player_greetings(greetings):
        """ get a flattened list of all the key phrases a player can use to greet an NPC

        Arguments:
        greetings -- a dictionary mapping key phrases that are greetings to lists of NPC states

        Return:
        A flattened set containing all of the greetings this NPC will respond to
        """
        return flatten(Configuration.GREETINGS | set(greetings.keys()))

    def _get_farewell(farewells):
        """ get a flattened random farewell state
        
        Arguments:
        farewells -- a dictionary mapping key phrases that are farewells to lists of NPC states

        Return:
        One of the states in farewells flattened

        Note:
        This function is used to pick a farewell that will be used in the NPC code if the player dialog ends for any reason other than the player themselves saying a fairwell (ex timeout, walkaway, disappear etc.)
        """
        farewells = list(farewells.values())

        if not len(farewells): return None

        return flatten(set(farewells[0]))

    def _get_player_farewells(farewells):
        """ get a flattened list of all the key phrases a player can use to farewell an NPC

        Arguments:
        farewells -- a dictionary mapping key phrases that are farewells to lists of NPC states

        Return:
        A flattened set containing all of the farewells this NPC will respond to
        """
        return flatten(Configuration.FAREWELLS | set(farewells.keys()))

    def _get_npc_farewells(farewells):
        """ get a flattened list of all the NPC responses in a dictionary of farewells (ie unique states reached from all of the different farewell keywords)

        Arguments:
        farewells -- a dictionary mapping key phrases that are farewells to lists of NPC states

        Return:
        A set containing the NPC states that are reached from all of the farewells
        """
        f = set()
        for states in farewells.values():
            f |= states

        return flatten(f)

    def _highlight_all(s):
        """ get a new set that is filled with highlighted copies of the states in s """
        return set(map(lambda x: highlight(graph.keys(), x), s))

    if len(Configuration.GREETINGS) < 1:
        logging.warning("no greetings found, NPC will not respond to anything")

    if len(Configuration.FAREWELLS) < 1:
        logging.warning("no farewells found, NPC will not exit dialog")

    if len(template.params) == 0:
        raise Exception("empty transcript detected")
    elif len(template.params) > 1:
        logging.warning("multiple transcripts detected, only parsing one")

    text = replace_wiki_links(remove_html_markup(template.get(1).value))

    logging.debug(text)

    exchanges = [_parse_exchange(ex) for ex in list(_group(text))]

    if len(exchanges) == 0:
        raise Exception("empty dialog detected")

    # separate all dialog states into one of the three possible graphs
    graph = defaultdict(set)
    farewells = defaultdict(set)
    greetings = defaultdict(set)

    speakers = set()
    for dialog in exchanges:
        for r in dialog["responses"]:
            speakers.add(r["npc"])

        state = State([r["message"] for r in dialog["responses"]])

        for phrase in [p.lower() for p in dialog["key_phrases"]]:
            if _is_greeting(dialog, state):
                greetings[phrase].add(state)
            elif _is_farewell(dialog, state):
                farewells[phrase].add(state)
            else:
                graph[phrase].add(state)

    # can only highlight after mapping and sorting all states, this prevents highlighting greeting/farewell key phrases (TODO should we not highlight 'bye'?) and allows for highlighting the best matches (highlight {minotaur} instead of mi{no}taur if both minotaur and no are key phrases to be highlighted)
    for k in graph:
        graph[k] = _highlight_all(graph[k])

    for k in greetings:
        greetings[k] = _highlight_all(greetings[k])

    for k in farewells:
        farewells[k] = _highlight_all(farewells[k])

    if len(speakers) != 1:
        logging.warning("found responses from more than one NPC! %s"%pformat(speakers))

    npc = speakers.pop()
    logging.debug("npc: %s"%npc)

    # slugify the NPC name into a lua variable name
    npc = re.sub(r'[^a-zA-Z\s]+', ' ', npc.strip())
    npc = re.sub(r'[\s]+', '_', npc)
    npc = npc.lower()

    logging.debug("Greetings%s"%json.dumps(greetings, cls=PythonObjectEncoder))
    logging.debug("Farewells%s"%json.dumps(farewells, cls=PythonObjectEncoder))
    logging.debug("DialogGraph%s"%json.dumps(graph, cls=PythonObjectEncoder))

    player_greetings = _get_player_greetings(greetings)
    npc_greetings = _get_npc_greetings(greetings)

    farewell = _get_farewell(farewells)
    player_farewells = _get_player_farewells(farewells)
    npc_farewells = _get_npc_farewells(farewells)

    # write the prolog to the buffer from configuration, this is what will appear on an NPC without any dialog present in the transcript file
    buf=[Configuration.DEFAULT_SCRIPT.format(
        __npc__=npc,
        __npc_greetings__=luaify(npc_greetings),
        __farewell__=luaify(farewell),
        __player_greetings__=luaify(player_greetings))]

    # write the default "all connected" states to the NPC, all states in graph are considered to be states you can reach by keyphrase from any other state
    for phrase in graph:
        # this only occurs after weve been processing some phrases on graph and removing states from other keyphrases
        if not len(graph[phrase]): continue

        player_says = set()
        player_says.add(phrase)

        npc_says = set()

        # the NPC says everything in this graph[phrase], but we need to also look at other phrases in graph to see if this state was reached from other key phrases
        for state in graph[phrase]:
            npc_says.add(state)

            # look for other key phrases on graph that arent the currently processing one
            for edge in [e for e in graph.keys() if e != phrase]:
                if state in graph[edge]:
                    player_says.add(edge)
                    graph[edge].remove(state)

        npc_says = flatten(npc_says)
        player_says = flatten(player_says)

        # this is definitely not the correct way to add the state to the NPC in all cases, but it works for the general case (this state is reachable from any other state)
        buf.append("""engine.all.connect(%s, engine.State(%s))"""%(luaify(player_says), luaify(npc_says)))

    # finally add the farewells to the NPC script, notice that we use all.to which means this state can be reached from all others, but cannot go to any other state, meaning the NPC dialog will terminate automatically upon reaching this state
    buf.append("")
    buf.append("""engine.all.to(%s, engine.State(%s))"""%(luaify(player_farewells), luaify(npc_farewells)))

    output = "\n".join(buf)

    return output

def from_wiki_log(fstr):
    """ function that opens a text file, gets non empty templates from it, and returns the NPC lua script for the dialog tree

    Arguments:
    fstr -- a string holding a filename

    Return:
    New string containing a valid lua script representing the NPC state machine for the dialog tree found in fstr
    """
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

def main(args):
    """ entry point into the program

    Argument:
    args -- Arguments object from an ArgumentParser

    Return:
    prints an NPC lua script to standard output
    """
    log_level = getattr(logging, args.log_level.upper(), None)

    if not isinstance(log_level, int):
        raise ValueError('Invalid log level: %s'%args.log_level)

    logging.basicConfig(filename=args.log_out, format='%(levelname)s:%(message)s', level=log_level)
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
    parser.add_argument("--log-file", "-o", metavar="<file>", required=False, help="output file for logging", dest="log_out")
    parser.add_argument("file", metavar="<transcript-file>", help="input file to process as transcript")

    args = parser.parse_args()

    main(args)