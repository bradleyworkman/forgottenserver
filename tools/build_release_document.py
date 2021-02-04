from bs4 import BeautifulSoup
import requests
import dateparser, dateparser.search

import re, sys, textwrap, argparse, logging

from pathlib import Path
from pprint import pformat

sys.stdin.reconfigure(encoding='utf-8')
sys.stdout.reconfigure(encoding='utf-8')

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

    PROGRAM="Tibia update documentation builder"
    VERSION="0.0.1-alpha"
    DESCRIPTION=textwrap.dedent('''\
        This program is designed to parse a wikimedia tibia NPC transcript source and output an NPC lua script that matches -- quests must be done by hand!
        ''');
    EPILOG=textwrap.dedent('''\
        %s

        MIT License (use --license to print in full)
        '''%Copyright.SHORT)

    UPDATE_DIRECTORY=Path.cwd().joinpath("tibia.fandom.com","wiki","Updates").resolve()

    DATES={
        "8_31": dateparser.parse("October 01, 2008"),
        "pre_6_0": dateparser.parse("January 01, 2000"),
        "10_92": dateparser.parse("April 12, 2016")
    }

    @const
    class Template:
        CSS=textwrap.dedent("""\
            /*
            The Neutral Colors Color Scheme palette has 6 colors which are Khaki (HTML/CSS) (#BFAB8E), Pale Taupe (#B79785), Dark Vanilla (#CDB9A5), Tuscany (#B99C98), Philippine Gray (#8C8E8D) and Quick Silver (#A3A893).
            */

            * {
                box-sizing:border-box;
            }

            body {
                max-width: 1024px;
            }

            h2[data-source="name"] {
                font-size:48px;
                margin: 5px 0px
            }

            div[data-source="date"] {
                font-size:18px;
            }

            div[data-source="implemented"] > h3.pi-data-label,
            div[data-source="primarytype"] > h3.pi-data-label {
                display:inline;
            }

            div[data-source="implemented"] > div.pi-data-value,
            div[data-source="primarytype"] > div.pi-data-value {
                display:inline;
            }

            ul.update_teasers {
                list-style-type: none;
                margin: 0;
                padding: 0;
            }

            ul.update_teasers li {
                padding-bottom:3em;
            }

            table {
              font-family: Arial, Helvetica, sans-serif;
              border-collapse: collapse;
              width: 100%;
            }

            table td, table th {
              border: 1px solid black;
              padding: 8px;
            }

            table td {
                vertical-align:top;
            }

            table th {
              padding-top: 12px;
              padding-bottom: 12px;
              text-align: left;
              background-color: #8C8E8D;
              color: white;
              text-align:center;
            }""")

        HTML=textwrap.dedent("""\
            <!doctype html>
            <html lang="en">
            <head>
                <meta charset="utf-8">

                <title>Updates</title>
                <meta name="description" content="{description}">
                <meta name="generator" content="{generator}">

                <style type="text/css">
                    {css}
                </style>
            </head>
            <body>
                {body}
            </body>
            </html>""")

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

def one_line(text):
    """ get the text with newlines replaced with a space """
    return re.sub(r'\r?\n', " ", text)

def get_date_tag(soup):
    """ get the beautiful soup tag containing the date of the update if it exists

    Arguments:
    soup -- a BeautifulSoup object to find the date tag in

    Return:
    anchor tag that contains the update date if it exists, else None
    """
    anchors = soup.find_all("a", limit=5)
    for anchor in anchors:
        try:
            d = dateparser.parse(anchor.text)
            if d: return anchor
        except ValueError as ex: pass

    return None

def get_date(soup):
    """ get the date of the update

    Arguments:
    soup -- a BeautifulSoup object to search for an update date

    Return:
    datetime containing the date of the update if it was found, else None

    Notes:
    performs a fuzzy match on date strings, assumes any anchor in the first 5 on the page containing a parseable date contains the date of the update
    """
    date = soup.find('div', attrs={'data-source':'date'})

    if date:
        text = re.sub(r'\s+', " ", one_line(date.text))
        r = dateparser.search.search_dates(text)

        return r[0][1] if len(r) else None

    anchors = soup.find_all("a", limit=5)
    for anchor in anchors:
        try:
            d = dateparser.parse(anchor.text)
            if d: return d
        except ValueError as ex: pass

    return None

def read_soup(fstr):
    """ get a BeautifulSoup object representing the html stored in a file at fstr

    Arguments:
    fstr -- a path to a UTF-8 encoded file to read the html from

    Return:
    BeautifulSoup object containing the parsed HTML from the file
    """
    with Path(fstr).open('r', encoding="utf-8") as file:
        logging.debug("reading...'%s'"%fstr)
        return BeautifulSoup(file.read(), "html.parser")

def stat(root):
    """ get a mapping of file pathes to update dates

    Arguments:
    root -- a path containing all of the update files to map

    Return:
    dictionary containing a mapping from filepath -> update release time
    """
    paths = {}

    for path in Path(root).glob("*.html"):

        # check the configured hardcoded dates first
        for name,date in Configuration.DATES.items():
            pattern = r'Updates[\\/]%s'%name
            if re.search(pattern, str(path)):
                logging.debug("configured date found...'%s'"%path)
                paths[str(path)] = date
                break

        # if no hardcoded date existed for this update, then parse the date out of the contents
        if str(path) not in paths:
            with path.open('r', encoding="utf-8") as file:
                logging.debug("reading...'%s'"%path)
                soup = BeautifulSoup(file.read(), "html.parser")

            date = get_date(soup)

            if date:
                paths[str(path)] = date

    return paths

def find_unique(updates, pattern, flag):
    """ get the datetime of the unique update matched by pattern or exit

    Arguments:
    updates -- a mapping of file pathes to update datetimes as returned by stat
    pattern -- a pattern to match the file path against
    flag -- a command line option (--from or --to) describing where pattern came from

    Return:
    a datetime corresponding to the unique update matched by pattern

    Side Effects:
    exits with a critical message if no update is matched by pattern or if multiple updates are matched by pattern
    """
    matches = list(filter(lambda t: None != re.search(pattern, t[0]), updates.items()))

    if len(matches) < 1:
        logging.critical("no matches for %s %s"%(flag, pattern))
        sys.exit()

    if len(matches) > 1:
        logging.critical("found multiple matches for %s %s; please be more specific"%(flag, pattern))
        logging.critical(pformat(matches))
        sys.exit()

    return matches[0][1]

def _strain_newsarchive(soup):
    """ get the BeautifulSoup tag which corresponds to the news archive content stored in soup

    Arguments:
    soup -- BeautifulSoup object containing the parsed html from a newsarchive link

    Return:
    BeautifulSoup tag containing the news content we care about if it is found else None

    Side Effects:
    modifies news content on soup, removes anchors, removes "comment on this news" text

    Note:
    returned tag is still connected to the soup passed in
    """
    if soup.body:
        table = soup.body.find("table")
        if table:
            for anchor in table.find_all("a"):
                anchor.unwrap()

            ns = table.find(string=re.compile("Comment on this news"))
            if ns: ns.parent.extract()

            return table
        else:
            logging.warning("no news section found")
    else:
        logging.warning("no body found")

    return None

def _strain(soup, path):
    """ process a BeautifulSoup object containing parsed html from a tibia wiki update page and return the string representing the new content

    Arguments:
    soup -- BeautifulSoup object containing parsed html from an updates file created by fetch_updates.py
    path -- the Path object to the html file parsed to create soup

    Return:
    string containing prettified html from the soup object

    Side Effects:
    modifies content of soup before marshalling it
    """
    def fill_summary():
        """ modify soup to contain the loaded contents of the official updates release from tibia.com for the Summary section

        Arguments:
        None

        Return:
        None

        Side Effects:
        modifes soup, removes contents for summary and artwork if they exist and strained official tibia.com documentation has been successfully loaded
        """
        logging.info("filling summary section")

        anchor = get_date_tag(root)
        if not anchor:
            logging.warning("no official document found for summary")
            return

        summary_href = anchor["href"]

        if summary_href.find("newsarchive") == -1:
            logging.warning("official document was not a news archive link")
            return

        h2 = soup.body.find("h2", string=re.compile(r'Summary', flags=re.IGNORECASE))
        if summary_href and h2:
            section = h2.find_parent("section")
            if section:
                child_path = path.parent.joinpath(summary_href)

                logging.info("loading summary...'%s'"%child_path)
                table = _strain_newsarchive(read_soup(child_path))

                if table:
                    for td in table.find_all("td"):
                        section.extend(list(td.contents))

                    summary = soup.body.find("div",attrs={"data-source":"summary"})
                    if summary: summary.extract()
                    
                    artwork = soup.body.find("div",attrs={"data-source":"artwork"})
                    if artwork: artwork.extract()

            else:
                logging.warning("no summary section found")
        else:
            logging.warning("no summary heading found")

    def fill_teasers():
        """ modify soup to contain the loaded contents of the official update teasers from tibia.com for the Update Teasers section

        Arguments:
        None

        Return:
        None

        Side Effects:
        modifes soup, changes the updates teaser list to an unordered one, adds a class attribute to the list, and replaces update teaser links with their strained content
        """
        logging.info("filling update teasers")

        el = soup.body.find(id="Update_Teasers")
        if not el:
            logging.warning("no update teasers heading found")
            return

        h = el.parent
        l = h.find_next_sibling()

        if l.name not in ["ol","ul"]:
            logging.warning("expected 'ol' or 'ul' found '%s'"%l.name)
            return

        l.name = "ul"
        l["class"] = "update_teasers"

        for anchor in l.find_all("a"):
            if "href" in anchor.attrs and anchor["href"]:

                if anchor["href"].find("newsarchive") == -1:
                    logging.warning("update teaser was not a news archive link")
                    continue

                child_path = path.parent.joinpath(anchor["href"])

                logging.info("loading teaser...'%s'"%child_path)
                table = _strain_newsarchive(read_soup(child_path))

                if table:
                    for td in table.find_all("td"):
                        anchor.parent.extend(list(td.contents))

                    anchor.extract()
            else:
                logging.warning("found anchor in update teasers without href")
                logging.debug(anchor)

    root = soup.body

    fill_summary()
    fill_teasers()

    # remove all anchors on the wiki page (note summary and update linked content was added to soup already)
    for anchor in root.find_all("a"):
        anchor.unwrap()

    # remove nav pointing to other updates
    ns = soup.find(string=re.compile("See also:"))
    if ns:
        nav = ns.find_parent("nav")
        if nav:
            nav.extract()

    # remove nav links at top of wiki page
    div = root.find("div", attrs={"class":"update-header"})
    if div: div.extract()

    # remove the previous update section and link
    div = root.find("div", attrs={"data-source":"previous"})
    if div: div.extract()

    # remove the next update section and link
    div = root.find("div", attrs={"data-source":"next"})
    if div: div.extract()

    # remove all the substitute images used if a lazyloaded image isnt found
    for div in root.find_all("div", attrs={"class":"no-exist"}): div.extract()

    # remove the gallery images for the update
    gallery = root.find("div", id="effect-galleries")
    if gallery: gallery.extract()

    # update lazyload images to use data-src attribute as primary src
    for img in root.find_all("img", attrs={'class':'lazyload'}):
        if 'data-src' in img.attrs:
            img['src'] = img['data-src']

    # strip the <body></body> tags from the output
    return "\n".join(root.prettify(formatter="html5").splitlines(False)[1:-1])

def main(args):
    """ entry point into the program

    Argument:
    args -- Arguments object from an ArgumentParser

    Side Effects:
    crawls the update url for links pointing to wiki updates pages or tibia.com pages, downloads them if not in cache or --clear-cache is specified, and modifies them to be easier to read without styles etc.
    """
    log_level = getattr(logging, args.log_level.upper(), None)

    if not isinstance(log_level, int):
        raise ValueError('Invalid log level: %s'%args.log_level)

    logging.basicConfig(filename=args.log_out, format='%(levelname)s: %(message)s', level=log_level)
    logging.debug(args)

    logging.info("loading update files; this may take a while")
    updates = stat(args.updates_dir)

    start = find_unique(updates, args.min_update, "--from") if args.min_update else min(updates.values())
    end = find_unique(updates, args.max_update, "--to") if args.max_update else max(updates.values())

    logging.info("from: %s"%start)
    logging.info("to: %s"%end)
    logging.info("filtering updates from %s to %s"%(start, end))

    updates = filter(lambda t: start <= t[1] <= end, updates.items())

    logging.info("sorting updates")

    updates = sorted(updates, key=lambda x: x[1])

    logging.info("found: %d"%len(updates))

    buf = []
    for fstr,_ in updates:
        logging.info("_straining...'%s'"%fstr)
        buf.append(_strain(read_soup(fstr), Path(fstr)))

    output = Configuration.Template.HTML.format(
        description=" ".join(sys.argv),
        generator=" ".join([Configuration.PROGRAM, Configuration.VERSION]),
        css=Configuration.Template.CSS,
        body="\n".join(buf))

    if args.out_file:
        with open(args.out_file, 'w') as file:
            file.write(output)
    else:
        print(output)

if (__name__ == '__main__'):
    parser = argparse.ArgumentParser(
        prog=Configuration.PROGRAM,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=wrap(Configuration.DESCRIPTION),
        epilog=Configuration.EPILOG)

    parser.add_argument("--version","-v", action="version", version="%%(prog)s %s"%Configuration.VERSION)
    parser.add_argument("--license", "-l", action=LicenseAction, help="show program's license and exit")
    parser.add_argument("--log-level", required=False, metavar="<level>", help= "set the logging level to one of [DEBUG,INFO,WARNING,ERROR,CRITICAL]", default="INFO", dest="log_level")
    parser.add_argument("--log-file", metavar="<file>", required=False, help="output file for logging", dest="log_out")

    parser.add_argument("--from", metavar="<update name>", help="minimum update to include in compilation", dest="min_update")
    parser.add_argument("--to", metavar="<update name>", help="maximum update to include in compilation", dest="max_update")

    parser.add_argument("--updates-dir", metavar="<folder>", help="location to find wiki update pages to compile", required=False, default=Configuration.UPDATE_DIRECTORY)

    parser.add_argument("-o", metavar="<file>", help="file name to write output to", required=False, dest="out_file")

    args = parser.parse_args()

    main(args)