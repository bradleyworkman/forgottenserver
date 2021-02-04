from bs4 import BeautifulSoup
import requests

import re, sys, unicodedata, time, errno, textwrap, argparse, logging, os

from time import sleep
from pathlib import Path
from urllib.parse import urlparse, urljoin, urlsplit, urlunsplit

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

    PROGRAM="Tibia update documentation downloader"
    VERSION="0.0.1-alpha"
    DESCRIPTION=textwrap.dedent('''\
        This program is designed to download/update official tibia update documentation from tibia.com and unofficial documentation from tibia.fandom.com.
        ''');
    EPILOG=textwrap.dedent('''\
        %s

        MIT License (use --license to print in full)
        '''%Copyright.SHORT)

    WIKI_UPDATES_URL="https://tibia.fandom.com/wiki/Updates"
    TEMPLATE=textwrap.dedent("""\
        <!doctype html>
        <html lang="en">
            <head>
                <meta charset="utf-8">

                <title>{title}</title>
                <meta name="description" content="{description}">
                <meta name="generator" content="%s %s">

            </head>
            <body>
                {body}
            </body>
        </html>
        """)%(PROGRAM, VERSION)

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

class Cache:
    """ interface for a simple cache """
    def get(self, key): raise NotImplementedError
    def set(self, key, value): raise NotImplementedError
    def exists(self, key): raise NotImplementedError
    def remove(self, key): raise NotImplementedError
    def __contains__(self, key): return self.exists(key)

def slugify(value, allow_unicode=False):
    """
    Taken from https://github.com/django/django/blob/master/django/utils/text.py
    Convert to ASCII if 'allow_unicode' is False. Convert spaces or repeated
    dashes to single dashes. Remove characters that aren't alphanumerics,
    underscores, or hyphens. Convert to lowercase. Also strip leading and
    trailing whitespace, dashes, and underscores.
    """
    value = str(value)
    if allow_unicode:
        value = unicodedata.normalize('NFKC', value)
    else:
        value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode('ascii')
    value = re.sub(r'[^\w\s-]', '_', value.lower())
    return re.sub(r'[-\s_]+', '_', value).strip('-_')

class HTTPFileSystemCache(Cache):
    """ cache for saving html to disk

    Note:
    The cache actually allows the same key to be used multiple times. When setting a new document is created under the key + timestamp, when getting the latest document is returned, when removing all documents with the same base key are unlinked.

    The above is also the reason why this cache implements an "Update" method, which modifies the last created document under the key (keeping the original timestamp!) instead of creating a new document with a different timestamp.
    """
    def _parse(self, href):
        """ get the components of an href as valid file system paths
        Arguments:
        href -- a url to parse

        Return:
        A tuple containing the Path consisting of the net location of the url, a string containing the directory of the url, and a slugified filename for the url
        """
        parts = urlparse(href)
        root = Path(parts.netloc)
        path = Path(parts.path)

        if parts.query:
            directory = str(path)
            filename = slugify(parts.query)
        else:
            directory = str(path.parent)
            filename = slugify(path.name)

        return root, directory, filename

    def _find_all(self, href):
        """ find all paths that match values for the key href in this cache
        Arguments:
        href -- a url to find paths for

        Return:
        a generator that will yield all paths that match values for the key href
        """
        root, directory, filename = self._parse(href)
        p = self.root.joinpath(root, directory.strip("/\\"))
        globstr = "%s.*.html"%filename

        logging.debug("_find_all %s %s"%(p, globstr))

        return p.glob(globstr)

    def _find(self, href):
        """ return the path to the latest cache value for the href

        Arguments:
        href --  a url to find a path for

        Return:
        a path to an existing file that contains the latest value for the key href else None if the key is not in this cache
        """
        paths = self._find_all(href)

        try:
            newest = next(paths)
        except StopIteration as ex: return None
        
        for p in paths:
            if p.stat().st_mtime_ns > newest.stat().st_mtime_ns:
                newest = p

        return newest

    def __init__(self, root=Path.cwd()):
        """ constructor
        Arguments:
        root -- a Path object to the root directory for this cache, default cwd()
        """
        self.root = root

    def get(self, href):
        """ get the latest html stored in this cache for the key href
        Arguments:
        href --  a url to get html for

        Return:
        a UTF-8 encoded string containing the latest HTML stored in this cache for the key href
        """
        path = self._find(href)

        if not path: raise KeyError(href)

        with path.open('r', encoding="utf-8") as file:
            logging.info("reading...'%s'"%path)
            return file.read()

    def set(self, href, html):
        """ add a new entry in this cache
        Arguments:
        href --  a url to store html for
        html -- a unicode string containing HTML data to store

        Return:
        None

        Side Effects:
        creates a new file on disk and writes the html to it

        Note:
        Does not replace/remove previous cached entries, adds a new one
        """
        ext = ".%s.html"%int(time.time())
        root, directory, filename = self._parse(href)

        path = self.root.joinpath(root,directory.strip("/\\"), filename + ext)
        path.parent.mkdir(parents=True,exist_ok=True)

        with path.open('w', encoding="utf-8") as file:
            logging.info("writing...'%s'"%path)
            file.write(html)

    def update(self, href, html):
        """ modifies the html in the latest store for the key href
        Arguments:
        href --  a url to store html for
        html -- a unicode string containing HTML data to store

        Return:
        None

        Side Effects:
        overwrites the content on disk of the latest file containing the html value for key href

        Note:
        This replaces the file contents for the latest stored html, but does not update its timestamp (thus timestamp can be considered creation time, but not modified time)
        """
        path = self._find(href)

        if not path: raise KeyError(href)

        with path.open('w', encoding="utf-8") as file:
            logging.info("writing...'%s'"%path)
            file.write(html)

    def exists(self, href):
        """ check if this cache has a value stored for the key href
        Arguments:
        href --  a url to check if any html is stored for

        Return:
        True if a file exists which contains html for this href, else False
        """
        try:
            next(self._find_all(href))
            return True
        except StopIteration as ex: pass

        return False

    def remove(self, href):
        """ remove the html values for href from this cache
        Arguments:
        href --  a url to get html for

        Return:
        None

        Side Effects:
        unlinks all files on disk that store html values for the key href

        Note:
        removes *all* cache entries for this key href
        """
        for p in self._find_all(href):
            logging.info("deleting...'%s'"%p)
            p.unlink()

    def uri(self, href):
        """ get a file URI to the latest file containing html content for the key href
        Arguments:
        href --  a url to get a file path for

        Return:
        a unicode string containing the path to the file backing the latest content for the key href
        """
        path = self._find(href)

        if not path: raise KeyError(href)

        return urlunsplit(("file","",str(path),"",""))

class Page:
    """class containing a url and the parsed response from the server"""
    url = None
    soup=None

    def __init__(self, url):
        """ constructor
        Arguments:
        url -- string containing the url to load
        """
        self.url = url

    def load(self):
        """ try to load the url and parse the response
        Arguments:
        None

        Return:
        the status code of the http request to this Page's url or -1 if an exception occurs while loading the page (such as page not found)
        """
        try:
            logging.info("downloading...'%s'"%self.url)
            r = requests.get(self.url)

            # timeout to be nice to the server and prevent rate limiting
            sleep(1)

            if r.status_code == 200:
                self.soup = BeautifulSoup(r.text, "html.parser")

            return r.status_code

        except Exception as ex:
            logging.error("", exc_info=ex)
            return -1

    def __str__(self):
        """ convert this Page to a string by returning the prettified html from a successful page load or empty string"""
        return self.soup.prettify(formatter="html5") if self.soup else ""

    def resolve(self, href):
        """ get the 'absolute' path to href as referenced from this page's url

        Arguments:
        href -- a url to resolve

        Return:
        a new string containing the full url to href from this page's url
        """
        parts = urlparse(href)

        if parts.scheme or parts.netloc:
            return href

        return urljoin(self.base().rstrip("/"),href.lstrip("/"))

    def title(self):
        """ get the page title
        
        Arguments:
        None

        Return:
        The title of the page as taken from the parsed contents if it exists, else the url of the page
        """
        if self.soup and self.soup.title :
            return " ".join(self.soup.title.contents)

        return self.url

    def base(self):
        """ get the page base
        
        Arguments:
        None

        Return:
        the base url of the page as taken from the parsed contents if it exists, else the base url as taken from the url of this page
        """
        if self.soup and self.soup.base and "href" in self.soup.base:
            return self.soup.base["href"]

        parts = urlparse(self.url)
        return "%s://%s"%(parts.scheme, parts.netloc)

def is_tibia_url(url):
    """ return True if url is an http url to tibia.com """
    return url.find("tibia.com") >= 0 and url.find("http") >= 0

def is_updates_url(url):
    """ return True if the url contains a path component 'Updates' """
    return None != re.search(r'[\\/]Updates[\\/]',url)

def _strain_wiki(page):
    """ process the tibia wiki contents of page

    Arguments:
    page -- a Page object containing a loaded tibia wiki url

    Return:
    None

    Side Effects:
    modifies page by stripping unnecessary content (ex table of contents), removing links to content outside of tibia.com and tibia wiki updates, and placing the wiki contents into a new document
    """
    root = page.soup.body.find('div', attrs={'class':'mw-parser-output'})

    if root:
        template = BeautifulSoup(Configuration.TEMPLATE.format(
            title=page.title(),
            description="source document: '%s'"%page.url,
            body=""
            ),'html.parser')

        toc = root.find('div', attrs={'class': 'toc'})
        if toc: toc.extract()

        for anchor in root.find_all("a"):
            if "href" not in anchor.attrs or (not is_tibia_url(anchor["href"]) and not is_updates_url(anchor["href"])):
                    anchor.unwrap()

        template.body.append(root)
        page.soup = template
    else:
        logging.warning("missing mw-parser-output")

def _strain_newsarchive(page):
    """ process the tibia.com newsarchive contents of page

    Arguments:
    page -- a Page object containing a loaded tibia.com newsarchive url

    Return:
    None

    Side Effects:
    modifies page by stripping unnecessary content (ex button to comment on the news), removing all links, and placing the news contents into a new document
    """    
    root = page.soup.body.find('div', attrs={'class':'NewsHeadline'})

    if root and root.parent:
        template = BeautifulSoup(Configuration.TEMPLATE.format(
            title=page.title(),
            description="source document: '%s'"%page.url,
            body=""
            ),'html.parser')

        root = root.parent

        for anchor in root.find_all("a"):
            anchor.unwrap()

        ptr = root.find("form")
        while ptr.parent != root:
            ptr = ptr.parent
        ptr.extract()

        template.body.append(root)
        page.soup = template
    else:
        logging.warning("missing NewsHeadline")

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

    logging.basicConfig(filename=args.log_out, format='%(levelname)s:%(message)s', level=log_level)
    logging.debug(args)

    cache = HTTPFileSystemCache()

    def crawl(page):
        """ traverse all anchors in the page, fetch their content and store in cache, crawl the fetched content if its a wiki updates url, process the content for tibia news urls and wiki updates, replace the href on the anchor with the path to the fetched content as stored by cache.

        Arguments:
        page -- a Page object containing a loaded wiki url

        Return:
        None

        Side Effects:
        adds new pages to cache, replaces anchor links in page's parsed html with links to the downloads stored by cache
        """
        def _relative(a,b):
            """ get the relative link to b from a
            Arguments:
            a -- a file URI to calculate the path from
            b -- a file URI to calculate the path to

            Return:
            a string containing the relative path from the file pointed to by a to the file pointed to by b
            """
            logging.debug("_relative %s %s"%(a,b))

            a = Path(urlsplit(a).path)
            b = Path(urlsplit(b).path)
            r = os.path.relpath(str(b),str(a.parent))

            logging.debug("return %s"%r)

            return r

        for anchor in page.soup.body.find_all("a"):
            if "href" in anchor.attrs:
                href = page.resolve(anchor["href"])

                if args.clear_cache:
                    cache.remove(href)

                if href not in cache:
                    child = Page(href)
                    response = child.load()

                    if 200 == response:
                        if is_tibia_url(href):
                            if href.find("newsarchive") >= 0:
                                _strain_newsarchive(child)

                        cache.set(href, str(child))

                        if is_updates_url(href):
                            _strain_wiki(child)

                            try:
                                crawl(child)
                            except Exception as ex:
                                logging.error("", exc_info=ex)

                            cache.update(href, str(child))

                    else: # error fetching child page
                        logging.error("response: %d"%response)

                try:
                    # this will fail if the href wasnt successfully downloaded, in which case we just remove the anchor from the page
                    anchor["href"] = _relative(cache.uri(page.url), cache.uri(href))
                except KeyError as ex:
                    anchor.unwrap()
            else: # remove the anchor tag if it has no href to process
                anchor.unwrap()

    logging.info("replacing root document in cache")

    page = Page(args.update_url)
    response = page.load()
    if 200 != response:
        logging.critical("response: %d"%response)
        sys.exit()

    _strain_wiki(page)

    cache.remove(args.update_url)
    cache.set(args.update_url, str(page))
    try:
        crawl(page)
    except Exception as ex:
        logging.error("", exc_info=ex)

    cache.update(args.update_url, str(page))


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

    parser.add_argument("--updates-url", metavar="<url>", help="root url to begin crawling/downloading", dest="update_url", required=False, default=Configuration.WIKI_UPDATES_URL)

    parser.add_argument("--clear-cache", help="pass this flag if you wish to overwrite previously downloaded update information, not specifying it means the program will skip any previously downloaded file and use the original when converting links", required=False, action='store_true')

    args = parser.parse_args()

    main(args)