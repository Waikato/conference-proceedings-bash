#!/bin/bash
#
# Script for updating the page numbers.
# Uses the list_page_no.sh script to generate the start page numbers.

# the usage of this script
function usage()
{
   echo
   echo "${0##*/} -p <startpages> [-h]"
   echo
   echo "Script for updating the page numbers."
   echo "Uses the output generated from the list_page_no.sh script to obtain "
   echo "the start page numbers (-p option)."
   echo
   echo " -h   this help"
   echo " -p <startpages>"
   echo "      the file with the start pages, as generated by the "
   echo "      list_page_no.sh script"
   echo
}

# function for updating the start page
function update_start_page()
{
  OLDDIR="`pwd`"
  cd "$DIR"
  TMP_OUT=$NAME.tmp

  echo "Updating $NAME -> $START_PAGE"

  cat $NAME.tex | sed s/".newcommand..startpage.*"/"\\\\newcommand{\\\\startpage\}\{$START_PAGE\}"/g > $TMP_OUT
  cp $TMP_OUT $NAME.tex
  rm $TMP_OUT

  cd "$OLDDIR"
}

ROOT=`expr "$0" : '\(.*\)/'`
PAGES=""

# interprete parameters
while getopts ":hp:" flag
do
   case $flag in
      h) usage
         exit 0
         ;;
      p) PAGES=$OPTARG 
         ;;
      *) usage
         exit 1
         ;;
   esac
done

if [ ! -f "$PAGES" ]
then
  echo "File generated from list_page_no.sh output not found: $PAGES"
  exit 2
fi

while read LINE
do
  # skip line?
  if [[ "$LINE" =~ NA$ ]] || [[ "$LINE" =~ startpage$ ]] || [ -z "$LINE" ]
  then
    continue
  fi
  
  IFS=$'\t' read -a PARTS <<< "${LINE}"
  
  NAME="${PARTS[0]}"
  DIR="${PARTS[1]}"
  START_PAGE="${PARTS[3]}"
 
  update_start_page

  # failed?
  if [[ $RC != 0 ]] && [ "$RC" != "" ]
  then 
    echo
    echo "Updating start page number for '$NAME' failed with exit code: $RC"
    echo
    exit $RC
  fi
done < "$PAGES"

