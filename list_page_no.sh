#!/bin/bash
#
# Script for listing the page numbers of the already compiled articles.
# Output format:
# name <COMMA> #pages <COMMA> startpage
# If an article is not to be included in the startpage count, "NA" will
# get output instead of the "startpage" value.

# the usage of this script
function usage()
{
   echo
   echo "${0##*/} [-r <name>] [-h]"
   echo
   echo "Lists the page numbers of the compiled articles as defined in $LIST."
   echo "Output format:"
   echo "name <COMMA> #pages <COMMA> startpage"
   echo "If an article is not to be included in the startpage count, \"NA\" will"
   echo "get output instead of the \"startpage\" value."
   echo
   echo " -h   this help"
   echo " -r   <name>"
   echo "      resume update with this article name"
   echo "      NB: the \"start page\" value won't be correct in this case"
   echo
}

# function for listing the page numbers
function list_page_no()
{
  OLDDIR="`pwd`"
  cd "$DIR"

  COUNT=`pdfinfo $NAME.pdf  | grep "Pages:" | sed s/".*:\| *"//g`

  # output article stats
  if [ "$ADD" = "yes" ]
  then
    echo "$NAME,$COUNT,$START_PAGE"
  else
    echo "$NAME,$COUNT,NA"
  fi

  if [ "$ADD" = "yes" ]
  then
    START_PAGE=$(($START_PAGE+$COUNT))
  fi

  cd "$OLDDIR"
}

ROOT=`expr "$0" : '\(.*\)/'`
LIST=$ROOT/articles.list
COMMENT="#"
RESUME=""
START_PAGE=1

# interprete parameters
while getopts ":hr:" flag
do
   case $flag in
      r) RESUME=$OPTARG
         ;;
      h) usage
         exit 0
         ;;
      *) usage
         exit 1
         ;;
   esac
done

if [ "$RESUME" = "" ]
then
  echo "name,pageno,startpage"
fi

while read LINE
do
  # comment or empty line?
  if [[ "$LINE" =~ ^$COMMENT ]] || [ -z "$LINE" ]
  then
    continue
  fi
  
  read -a PARTS <<< "${LINE}"
  
  NAME="${PARTS[0]}"
  DIR="${PARTS[1]}"
  ADD="${PARTS[3]}"
  
  # find project to resume
  if [ ! "$RESUME" = "" ]
  then
    if [ ! "$RESUME" = "$NAME" ]
    then
      continue
    else
      RESUME=""
    fi
  fi

  list_page_no

  # failed?
  if [[ $RC != 0 ]] && [ "$RC" != "" ]
  then 
    echo
    echo "Listing page numbers for '$NAME' failed with exit code: $RC"
    echo "You can resume listing with: ${0##*/} -r $NAME"
    echo
    exit $RC
  fi
done < "$LIST"

