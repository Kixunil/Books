#!/bin/bash

# Automatic book information retriever
# Authors: Dominik Zajíček and Martin Habovštiak <martin.habovstiak@gmail.com>
# License: MIT

# Standard help function
function usage() {
	echo "Usage: $0 [--sql] BARCODE"
	echo "Retrieves information about given book and shows it."
	echo "If --sql flag is present output is in SQL format."
	echo "Exit value: 0 - success, 1 - book not found, 2 - input error"
}

# Parse options
if [ "$1" = "-h" -o "$1" = "--help" -o "$1" = "-help" -o "$1" = "-?" -o "$1" = "?" ];
then
	usage
	exit 0
fi

# Default
OUTPUT_TYPE=human
if [ "$1" = "--sql" ];
then
	OUTPUT_TYPE=sql
	shift
fi

# Check input
if [ $# -eq 0 ];
then
	echo 'Invalid input!' >&2
	usage >&2
	exit 2
fi

# Human readable output
function output_author_human() {
	echo "Author: $1"
}

function output_translation_human() {
	echo "Translation: $1"
}

# Read comma separated items from given string and process them individualy
# First argument: list
# Second argument: name of output function (without output_ prefix and _type sufix)
function output_list() {
	local TMP
	local CUR
	TMP="$1"
	while [ -n "$TMP" ];
	do
		CUR="`echo $TMP | sed 's/,.*$//g'`"
		TMP="`echo $TMP | sed 's/^[^,]*,\? \?//g'`"
		output_$2_$OUTPUT_TYPE "$CUR"
	done
}

# Print information about book in human readable form
function output_book_human() {
	echo "ISBN-type: `echo -n $ISBN | wc -c`"
	echo "ISBN: $ISBN"
	echo "Title: $TITLE"
	output_list "$AUTHOR" author
	if [ -n "$TRANSLATION" ];
	then
		output_list "$TRANSLATION" translation
	fi
	if [ -n "$AUTHOR_INFO" ];
	then
		echo "Info: $AUTHOR_INFO"
	fi
}

# Escapes apostrophes for SQL
function escape_sql() {
	echo "$1" | sed "s/'/''/g"
}

# SQL output
function output_author_sql() {
	echo "INSERT INTO books_authors VALUES ('`escape_sql "$ISBN"`', '`escape_sql "$1"`');"
}

function output_translation_sql() {
	echo "INSERT INTO books_translations VALUES ('`escape_sql "$ISBN"`', '`escape_sql "$1"`');"
}

function output_book_sql() {
	local INF=NULL
	test -n "$INFO" && INF="'`escape_sql "$INFO"`'"
	echo "INSERT INTO books VALUES ('`escape_sql "$ISBN"`', '`escape_sql "$TITLE"`', $INF);"
	# Database is in 3rd normal form, so we have to insert authors and translators individualy
	output_list "$AUTHOR" author
	output_list "$TRANSLATION" translation
}

# Finds Czech books
function get_aleph_nkp_cz() {
	# Check if token is cached
	if [ -z "$aleph_nkp_cz_TOKEN" ];
	then
		# Get TOKEN
		aleph_nkp_cz_TOKEN=`wget -qO - "http://aleph.nkp.cz/F/?func=file&file_name=find-b&local_base=nkck" | grep Refresh | sed 's/.*\/F\///' | sed ''s/\?.*//`
	fi

	# Get and parse info
	TITLE="`wget -qO - "http://aleph.nkp.cz/F/$token?func=find-b&find_code=ISN&x=19&y=16&request=$1&filter_code_1=WTP&filter_request_1=&filter_code_2=WLN&adjacent=N"  | \
		sed '/nowrap>Název<\/td>/,/<\/A>/!d' | sed 's/<[^<>]*>//g' | \
		sed -n '2 p'`"

	if [ -z "$TITLE" ];
	then
		# Fail
		return 1
	fi

	# Replace some special chars
	TITLE="`echo $TITLE | sed 's/&#38;/\&/g'`"

	# Get author from title
	AUTHOR="`echo $TITLE | sed 's/^.* \/&nbsp;//'`"

	# Get translators, if any
	TRANSLATION="`echo $AUTHOR | grep ' ; \[překlad .*\]' | sed -re 's/^.* ; \[překlad (.*)\]/\1/'`"
	test -z "$TRANSLATION" && TRANSLATION="`echo $AUTHOR | grep -E ' ; pře(ložil|klad) ' | sed -re 's/^.* ; pře(ložil|klad) ([^]]*)(]|$)/\2/'`"
	AUTHOR="`echo $AUTHOR | sed -e 's/ ; \[překlad .*\]//' -e 's/ ; přeložil .*//' -e 's/ ; překlad [^]]*//'`"

	# Get additional info, if any
	AUTHOR_INFO="`echo $AUTHOR | grep -E ' (; )?\[.*\]'| sed -re 's/^.* (; )?\[(.*)\]/\2/'`"

	# Throw away garbage
	AUTHOR="`echo $AUTHOR | sed -re 's/ (; )?\[.*\]//' -e 's/ \.\.\.$//'`"
	TITLE="`echo $TITLE | sed -e 's/ \/&nbsp;.*$//' -e 's/&nbsp;/ /g'`"
}

# Implementation of checksum calculation described at https://en.wikipedia.org/wiki/International_Standard_Book_Number#ISBN-10_check_digit_calculation
function gen_isbn10() {
	# Sed creates string which bc understands
	CHECKSUM="`echo $1 | sed -re 's/978(.)(.)(.)(.)(.)(.)(.)(.)(.).$/(11-(10*\1+9*\2+8*\3+7*\4+6*\5+5*\6+4*\7+3*\8+2*\9)%11)%11/' | bc`"
	# Use 'X' instead of 10
	test $CHECKSUM -eq 10 && CHECKSUM="X"
	# Output generated ISBN
	echo $1 | sed -re 's/^978(.{9}).$/\1'"$CHECKSUM"'/'
}

ISBN=$1
ISBN10="`gen_isbn10 $ISBN`"

# In case we have other web site providing information about books, we can just write function and add it to list
METHODS="aleph_nkp_cz"

# Try each method for both ISBN types until one succeeds (or all fail)
for METHOD in $METHODS;
do
	get_$METHOD $ISBN && break
	get_$METHOD $ISBN10 && break
done

if [ -z "$TITLE" ];
then
	# All methods failed
	echo "Error: book $ISBN not found" >&2
	exit 1
fi

# Output
output_book_$OUTPUT_TYPE
