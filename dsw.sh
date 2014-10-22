#!/bin/sh

# Builds a static site from a "content" directory with text files
# eventually using a light markup processor (like markdown o txt2tags) to
# generate html.  Static site goes in "htdocs" directory which has a premade
# two directories: images/ and css/ with graphics and stylesheets.  In css
# automatically goes a defaults css.  All imagess are to be put manually in
# /images/ directory.

# Defaults -- modified by the config file (dsw.conf)
site_title="My test site"
site_sub="A shell divertissement"
fext=".txt" # extension of source files (.txt, .md, .t2t ecc.)
markhandler="cat" # A light markup processor, I use "pandoc". "cat" is good if you directly write html!
lastgen="lastgen.time" # Last time all or modified pages were generated
css_file="default.css"
favicon="favicon.png"

####################################################
### Don't change below if not absolutely needed! ###
####################################################

# Main dirs
src_dir="content" # NO TRAILING SLASH!
out_dir="htdocs"  # IDEM
header_tpl="header.tpl"
footer_tpl="footer.tpl"
# If a conf file we source it
fileconf="dsw.conf"
[ -r "$fileconf" ] && . ./"$fileconf"

dsw_header() # prints out the header substituting values in $header_tpl file
{
	sed -e 's/{{site-title}}/'"${site_title}"'/g' \
	-e 's/{{site-sub}}/'"${site_sub}"'/g' \
	-e 's/{{favicon-img}}/'"$favicon"'/g' \
	-e 's/{{file-css}}/'"$css_file"'/' $header_tpl
}

dsw_thisdir() # $1 == path of src text file -- prints out where we are: dir path in $out_dir
{
	thisdir="${1%/*}/"
	echo "/${thisdir#*/}" # output is like "/Dir/Subdir/etcdir/"; root dir is "/".
}

dsw_menu() # $1 == path of src text file; $2 == $dsex (see dsw_page) -- prints out sections' menu
{
	echo '<div id="menu">'
	echo " <span class=\"thisdir\"><a href=\"./index.html\">$(dsw_thisdir $1)</a></span>" # where we are
	echo " <span class=\"sections\">" # sections of sites (dirs in root dir)
	if [ ${1%/*} = $src_dir ]; then
		for name in $2
		do
			echo "<a href=\"/${name}index.html\">${name}</a>" # no -> normal
		done
		echo '<a class=\"menunow\" href="/index.html">home</a>' # we are in root dir
	else
		for name in $2
		do
			echo $1 | grep "$name" > /dev/null # check if file is under this subdir
			if [ $? -eq 0 ]; then # yes -> strong emphasis
				echo "<a class=\"menunow\" href=\"/${name}index.html\">${name}</a>"
			else
				echo "<a href=\"/${name}index.html\">${name}</a>" # no -> normal
			fi
		done
		echo '&nbsp;&nbsp;&nbsp;<a href="/index.html"><strong><em>home</em></strong></a>' # always in em
	fi
	echo " </span>"
	echo "</div>"
}

dsw_navbar() # $1 == path of txt src file -- prints out a navbar for directory of current processed file
{
cat << _htlines_
<div id="main">
 <div id="navbar">
<ul>
_htlines_

	afile=${1##*/} 	# name of actual processed file without pathname
	tfile=${afile%.*} # and without extension -- we need it below...

	# first a link to current subdir (index file) -- no more needed, it's in menubar!
	#echo "<li class=\"sidefile\"><a href=\"./index.html\">./</a></li>"

	# second if file is not in site root dir we put a link to parent dir
	[ ${1%/*} != "$src_dir" ] && echo "<li class=\"sidefile\"><a href=\"../index.html\">../</a></li>"

	# third we list the files in the subdir excluding index file (previously listed)
	# and actually processed file
	subfiles=$(ls ${1%/*}/*${fext}) # we obtain complete path of files in src_dir

	for f in $subfiles
	do
		of=${f##*/} # file name with no path
		rf=${of%.*} # and with no extentions
		[ "$rf" = "index" ] && continue # index no in sidebar (already "./")
		if [ "$rf" != "$tfile" ]; then
			echo "<li class=\"sidefile\"><a href=\"${rf}.html\">${rf}</a></li>"
		else
			echo "<li class=\"thispage\"><a href=\"${rf}.html\">${rf}</a></li>"
		fi
	done

	# fourth we list eventual directories in dir of processed file	
	subdirs=$(ls -d ${1%/*}/*/ 2>/dev/null) #
	[ -n "$subdirs" ] && \
	for d in $subdirs
	do
		pred=${d%/*}
		odir=${pred##*/}
		echo "<li class=\"sidedir\"><a href=\"${odir}/index.html\">${odir}/</a></li>"
	done

cat << _htlines_
</ul>
 </div>
_htlines_
}

dsw_mark()
{
	echo ' <div id="content">'
	$markhandler $1
	echo ' </div>'
	echo '</div>' # close "main div"
}

dsw_footer()
{
	cat $footer_tpl
}

dsw_makedir() # create directories in $out_dir if necessary
{
	if [ "${1%/*}" != "$src_dir" ]; then # we are not in main dir
		predir=${1#*/}
		adir=${out_dir}/${predir%/*}
		[ -d "$adir" ] || mkdir -p "$adir"
	fi
}

dsw_page()
{
	# Sections of site (directories in root dir of src_dir) -- we need it for dsw_menu

#	ifsex=$(ls -d ${src_dir}/*/ 2>/dev/null)
#	( [ -n "$ifsex" ]] && dsex=$(for dir in "$ifsex"; do echo ${dir#*/}; done) ) || dsex=""
#	echo $dsex

	# 2>/dev/null if there are no dirs in $src_dir.
	dsex=$(for dir in `ls -d ${src_dir}/*/ 2>/dev/null`; do echo ${dir#*/}; done)
	
	dsw_header
	dsw_menu $1 "$dsex"
	dsw_navbar $1
	dsw_mark $1
	dsw_footer
}

dsw_build()
{
	if [ -z "$1" ]; then # no $1, rebuilds all site
		sfiles=$(find $src_dir -name \*${fext}) # builds all files
	else
        # if has an argument builds only files changed from last build (`dsw news`).
        #
        # WARNING! Use only if EXISTING files has been modified and don't use if
        # directory structure has changed or new files has been created after last
        # build!  Menu and navbar of non regenerated html files cannot mirror these
        # changes!  If so build all site with `dsw build`
		sfiles=$(find $src_dir -name \*${fext} -newer "$lastgen") # only newer files
		[ -z "$sfiles" ] && echo "No news" && exit 0 # no changes
	fi
	
	for F in ${sfiles}
	do
		dsw_makedir "$F" # make dirs if necessary
		preht="${F#*/}" # file path without $src_dir
		htfile="${out_dir}/${preht%.*}.html" # output file
		dsw_page $F > $htfile
		echo "* $F -> $htfile"
	done
	cp $css_file "${out_dir}/css"
	date >> $lastgen
}

dsw_reset() # delete content of $lastgen and resets it to an old value (2000-01-01) 
{
	echo > $lastgen
	touch -t 200001010001 $lastgen
}

dsw_init()
{
	dsw_reset
	mkdir $src_dir
	mkdir -p "${out_dir}/css"
	mkdir -p "${out_dir}/images"

cat > $fileconf << _fconf_
# Defaults
site_title="My test site"
site_sub="A shell divertissement"
fext=".txt" # src file extension -- with dot, if any!
css_file="default.css"
markhandler="cat" # markdown, pandoc, tx2tags ecc. Must read stdin and outputs to stdout
lastgen="lastgen.time"
_fconf_

dsw_tpl
cp skel.css $css_file
}

dsw_tpl() # generates a skeleton css file, header and footer templates
{

cat > skel.css << _fcss_
body {}
h1 {}
h2 {}
h3 {}
h4 {}
h5 {}
a {}
a:hover {}
#header {}
#header a {}
#headerTitle {}
#headerSubtitle {}
#menu {}
#menu a {}
#menu a:hover {}
.thisdir {}
.sections {}
#menu .menunow {}
#main {}
#navbar {}
#navbar ul {}
#navbar li {}
#navbar li a {}
#navbar .sidefile a {}
#navbar .thispage a {}
#navbar .sidedir a {}
#content {}
#footer {}
.left {}
.right {}
#google_translate_element {}
@media print {}
  body {}
  a {}
  hr.light {}
  #header {}
  #header a {}
  #headerTitle {}
  #headerSubtitle {}
  #main {}
  #content {}
  #menu {display: none;}
  #navbar {display: none;}
  .thisdir {display: none;}
  #footer img {display: none;}
  .right {display: none;}
  .left {display: none;}
}
_fcss_

cat > $header_tpl << _htpl_
<!DOCTYPE html>
<html>
 <head>
 <meta name="viewport" content="width-device-width">
 <meta charset="UTF-8">
 <title>{{site-title}}</title>
 <link rel="icon" href="/images/{{favicon-img}}" type="image/png">
 <link rel="stylesheet" type="text/css" href="/css/{{file-css}}">
 </head>
 <body>
 <div id="header">
  <h1 id="headerTitle">
  <a href="/index.html">{{site-title}}</a> <span id="headerSubtitle">{{site-sub}}</span>
  </h1>
 </div>
_htpl_

cat > $footer_tpl << _ftpl_
<div id="footer">
 <div class="left">
Copyright notice
 </div>
 <div class="right">
Email and acknowledgements
 </div>
</div>
 </body>
</html>
_ftpl_

}

dsw_help()
{
	echo "USAGE"
	echo "-----"
	echo "${0##*/} build          -- builds the static site in ${out_dir}/"
	echo "${0##*/} news           -- builds only files changed from last build"
	echo "${0##*/} page filename  -- builds a single page from a file in ${src_dir}/ to stdout"
	echo "${0##*/} init           -- initialize a new project directory here in $PWD"
	echo "${0##*/} reset          -- resets time of generated site to an old value"
	echo "${0##*/} tpl            -- generates a skel.css file, header and footer templates"
	echo "------"
	echo "Call the script always from base root of project directory!"
}

# Starting the loop...
case $1 in
	build)
		dsw_build
		;;
	news)
		dsw_build news
		;;
	page)
		( [ "$2" ] && dsw_page "$2" ) || ( dsw_help && exit 7 )
		;;
	init)
		dsw_init
		;;
	reset)
		dsw_reset
		;;
	tpl)
		dsw_tpl
		;;
	*)
		dsw_help
		;;
esac
