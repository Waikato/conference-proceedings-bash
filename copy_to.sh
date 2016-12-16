#!/bin/bash
#
# Script for copying compiled documents to a directory
# Supplementary documents must have the format "$NAME-supp.pdf".

# the usage of this script
function usage()
{
   echo
   echo "${0##*/} -o <dir> [-h]"
   echo
   echo "Copies the compiled articles (defined in $LIST) to a directory."
   echo "Supplementary documents must have the format: <NAME>-supp.pdf"
   echo
   echo " -h   this help"
   echo " -o   <dir>"
   echo "      the output directory to copy the PDFs to"
   echo
}

# function for copying the PDFs
function copy_to()
{
  OLDDIR="`pwd`"
  cd "$DIR"

  cp $NAME.pdf $OUTPUT
  if [ -f "$NAME-supp.pdf" ]
  then
    cp $NAME-supp.pdf $OUTPUT
  fi

  cd "$OLDDIR"
}

ROOT=`expr "$0" : '\(.*\)/'`
LIST=$ROOT/articles.list
COMMENT="#"
OUTPUT=""

# interprete parameters
while getopts ":ho:" flag
do
   case $flag in
      o) OUTPUT=$OPTARG
         ;;
      h) usage
         exit 0
         ;;
      *) usage
         exit 1
         ;;
   esac
done

if [ ! -d "$OUTPUT" ]
then
  echo "Output directory does not exist: $OUTPUT"
  exit 2
fi

while read LINE
do
  # comment or empty line?
  if [[ "$LINE" =~ ^$COMMENT ]] || [ -z "$LINE" ]
  then
    continue
  fi
  
  IFS=$'\t' read -r -a PARTS <<< "${LINE}"
  
  NAME="${PARTS[0]}"
  DIR="${PARTS[1]}"
  COMPILER="${PARTS[2]}"

  copy_to

  # failed?
  if [[ $RC != 0 ]] && [ "$RC" != "" ]
  then 
    echo
    echo "Copying of '$NAME' failed with exit code: $RC"
    echo
    exit $RC
  fi
done < "$LIST"

