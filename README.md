# DSW

**DSW** (Dan's Suckless Webframework, or another acronym you like more) is a
static website generator.  From a bunch of files and directories it
generates a static web site that mirrors the source and adds _css/_ and and
_images_/ directories.

 It's not a new idea, I know, but I didn't like similar programs out there
that I tried so I coded this new one.

Very similars scripts from which I have stolen many ideas are _[sw]_ and
_[rawk]_ and an old version of _[sw]_ modified by me but not in the public
domain (too much bloated!).  The appereance is literally grabbed from that
of _[suckless]_ site.

[suckless]: http://suckless.org
[sw]: http://github.com/jroimartin/sw
[rawk]: http://github.com/kisom/rawk

## DSW help

~~~~~~~~~~~~~~~~~~~~~
  USAGE
  -----
  dsw build          -- builds the static site in htdocs/
  dsw page filename  -- builds a single page from a file in content/ to stdout
  dsw init           -- initialize a new project directory here in $PWD
  dsw reset          -- resets time of generated site to an old value
  dsw tpl            -- generates a skel.css file, header and footer templates
  ------
  Call the script always from base root of project directory!
~~~~~~~~~~~~~~~~~~~~~

## Howto

1. Make a dir for a site project and go there. You always have to run `dsw` from there!
2. `dsw init` creates a dir for text files (`content`) and for static site (`htdocs`)
   It creates also an empty css file, an header and footer template, an
   `images` and `css` directory in `htdocs`. Creates a standard `dsw.conf`. 
3. Write some text files and directories in `content` with this advice:
   every directory must have and index file. Main directories in `content`
   are thougth like "sections" of site and appear in a menu in every page of
   the site. Change title and subtitle of your site in `dsw.conf`.
4. The markup of text files is what you like more (markdown,
   txt2tags, html and so on -- or none): you must have the parser to
   generate html snippets from them and configure the appropriate variable
   in `dsw.conf`: `markhandler`.  The parser must read from stdin and write
   to stdout (I personally use _[pandoc]_).  The `fext` variable defines the
   extension of text files: only them will be parse by the script.  It must
   have a dot!  Like name.ext.
5. If you link local images put them by hand in htdocs/images directory and link them
   from the text file.
6. For starting to styling your site you can initially use the standard
   `default.css` file from the distribution.
7. Run `dsw` from the project directory and you'll obtain the site in
   `htdocs`.  The script appends also to the `lastgen.time` file the time of
   generation.  The next time you'll build the site only files that are more
   recent of its modified time will be parsed.  You can reset them to an older
   default value (2000-01-01) with the command `dsw reset` and so rebuild all the
   site with `dsw build`.

8. To test the site go in `htdocs`, start the simple python webserver with the command
   `python -m SimpleHTTPServer` and from the browser visit `localhost:8000`
9. Navigating the site is simple. The name of the files and directories are
   the name of links that link to them: so is better for those names to be
   short and expressive!


[pandoc]: http://johnmacfarlane.net/pandoc
