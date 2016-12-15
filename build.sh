#!/bin/bash
#
# Script for building LaTeX papers.

# the usage of this script
function usage()
{
   echo
   echo "${0##*/} [-r <name>] [-h]"
   echo
   echo "Builds papers as defined in $LIST."
   echo
   echo " -h   this help"
   echo " -r   <name>"
   echo "      resume update with this project name"
   echo
}

# function for building a paper
function build()
{
  OLDDIR="`pwd`"
  cd "$DIR"

  rm -f $NAME.pdf
  rm -f $NAME.bbl

  # 1st build
  $COMPILER -halt-on-error $NAME.tex

  # bibtex?
  COUNT=`ls *.bib | wc -l`
  if [ $COUNT -gt 0 ]
  then
    bibtex $NAME.aux
  fi

  # compile til all references sorted
  RERUN=1
  while [ $RERUN -gt 0 ]
  do
    $COMPILER $NAME.tex
    RC=0
    RERUN=`cat $NAME.log | grep "Rerun to get citations correct\|Rerun to get cross-references right" | wc -l`
    ERROR=`cat $NAME.log | grep "Emergency stop" | wc -l`
    if [ $ERROR -gt 0 ]
    then
      RC=1
    fi
  done

  # supplementary?
  SUPPCOUNT=`ls *.tex | grep "\-supp.tex" | wc -l`

  cd "$OLDDIR"

  if [ "$CHECKSUPP" = "yes" ] && [ $SUPPCOUNT -gt 0 ]
  then
    echo "Building supplementary - $NAME"
    NAME="$NAME-supp"
    CHECKSUPP="no"
    build
  fi
}

ROOT=`expr "$0" : '\(.*\)/'`
LIST=$ROOT/build.list
COMMENT="#"
RESUME=""

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
  COMPILER="${PARTS[2]}"
  
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

  echo "$NAME - $DIR"
  CHECKSUPP="yes"

  build

  # failed?
  if [[ $RC != 0 ]] && [ "$RC" != "" ]
  then 
    echo
    echo "Build of '$NAME' failed with exit code: $RC"
    echo "You can resume builds with: ${0##*/} -r $NAME"
    echo
    exit $RC
  fi
done < "$LIST"

