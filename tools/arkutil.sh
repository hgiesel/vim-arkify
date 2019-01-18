#!/usr/bin/env bash

arkutil_analyze_path() {
  ######################### PROCESSING OF $ARG: SETTING TOPIC_*
  declare ARG=$1

  declare TOPIC_DEF=t
  declare TOPIC_ARG=${ARG%%::*}

  if [[ $ARG =~ .+::?.* ]]; then
    declare SUBTOPIC_DEF=t

    declare tmp1=${ARG##*::}
    declare SUBTOPIC_ARG=${tmp1%%:*}
  fi

  if [[ $ARG =~ .+::?.+:.+ ]]; then
    declare QUEST_DEF=t

    declare tmp2=${ARG%%:}
    declare QUEST_ARG=${tmp2##*:}
  fi

  ######################### PROCESSING OF $ARG: SETTING TOPIC_EXPANDED
  if [[ $TOPIC_ARG == '@' ]]; then
    declare MULTIPLE=t

  elif [[ $TOPIC_ARG ]]; then
    declare tmp3="$(echo $TOPICS | tr ' ' '\n' | cut -d, -f1 | tr '\n' '|')"
    declare NEWTOPICS="(${tmp3%|})"
    declare TOPIC_SELECTED=$(echo $TOPICS | tr ' ' '\n' | cut -d, -f1\
      | command grep "^$TOPIC_ARG")
    declare TOPIC_EXP="$(find ${ARCHIVE_PATH} -type d -iname "$TOPIC_SELECTED")"
  fi

  ######################### PROCESSING OF $ARG: SETTING SUBTOPIC_EXPANDED
  if [[ $SUBTOPIC_DEF && $MULTIPLE ]]; then
    echo "Can't use Subtopic without definite Topic!"
    exit 14
  fi

  if [[ $SUBTOPIC_ARG == '@' ]]; then
    declare MULTIPLE=t

  elif [[ "$SUBTOPIC_ARG" =~ ^.+-@$ ]]; then
    declare MULTIPLE=t
    declare SUBTOPIC_STEM="${SUBTOPIC_ARG%-@}"
    declare SUBTOPIC_EXP="$(find "$ARCHIVE_PATH" -type f -regex\
      "$TOPIC_EXP/$SUBTOPIC_STEM[^/.]*-1\.[^/.]*")"

  elif [[ $SUBTOPIC_ARG =~ ^.+-[[:digit:]]$ ]]; then
    declare SUBTOPIC_STEM="${SUBTOPIC_ARG%-*}"
    declare SUBTOPIC_INDEX="${SUBTOPIC_ARG##*-}"
    declare SUBTOPIC_EXP="$(find "$ARCHIVE_PATH" -type f -regex\
      "$TOPIC_EXP/$SUBTOPIC_STEM[^/.]*-$SUBTOPIC_INDEX\.[^/.]*")"

  elif [[ $SUBTOPIC_ARG ]]; then
    declare SUBTOPIC_EXP="$(find "$ARCHIVE_PATH" -type f -regex\
      "$TOPIC_EXP/$SUBTOPIC_ARG[^/.]*\(-1\|[a-z]\)\.[^/.]*")"
  fi

  ######################### PROCESSING OF $ARG: PROCESSING OF QUEST_ARG
  if [[ $QUEST_DEF && $MULTIPLE ]]; then
    echo "Can't use multiple MULTIPLE signifiers!"
    exit 15
  fi

  if [[ $QUEST_ARG == '@' ]]; then
    declare MULTIPLE=t

  elif [[ $QUEST_ARG ]]; then
    declare QUEST_EXP=$QUEST_ARG
  fi

  ######################### PROCESSING OF $ARG: DETECTING LOGIC ERRORS
  if [[ $VERBOSE ]]; then
    echo "arg:            $ARG"
    echo "topics:         $TOPICS"
    echo "topic def:      $TOPIC_DEF"
    echo "topic arg:      $TOPIC_ARG"
    echo "topic exp:      $TOPIC_EXP"
    echo "topic selected  $TOPIC_SELECTED"
    echo "subtopic def:   $SUBTOPIC_DEF"
    echo "subtopic arg:   $SUBTOPIC_ARG"
    echo "subtopic exp:   $SUBTOPIC_EXP"
    echo "subtopic stem:  $SUBTOPIC_STEM"
    echo "subtopic index: $SUBTOPIC_INDEX"
    echo "quest def:      $QUEST_DEF"
    echo "quest arg:      $QUEST_ARG"
    echo "quest exp:      $QUEST_EXP"
    echo "multiple:       $MULTIPLE"
  fi

  set -- $TOPIC_SELECTED
  [[ $# -gt 1 ]]\
    && { echo "Topic ambiguous:" $TOPIC_SELECTED ; exit 10; }
  [[ "$TOPIC_EXP" =~ (${NEWTOPICS%|}) ]]\
    || { echo "Topic not found!"; exit 11; }

  set -- $SUBTOPIC_EXP
  [[ $# -gt 1 ]] &&\
    {
      echo "Subtopic ambiguous:" $(sed -e 's|.*/||' -e 's|\..*||' <<< $SUBTOPIC_EXP) ;
      exit 20;
    }
  [[ $SUBTOPIC_ARG && ! $MULTIPLE && -z "$SUBTOPIC_EXP" ]]\
    && { echo "Subtopic does not exist!"; exit 21; }

  [[ $QUEST_DEF && ! $MULTIPLE && ! $QUEST_EXP =~ [[:digit:]][[:digit:]]* ]]\
    && { echo "Quest tag must be an integer greater zero: $QUEST_ARG"; exit 30; }
  [[ $QUEST_DEF ]] && ! grep -q "^:${QUEST_EXP:-[0-9]\+}[a-z]*:$" $SUBTOPIC_EXP\
    && { echo "Quest tag(s) doesn't exist in file"; exit 31; }

  [[ $VERBOSE ]] && echo "--------- Survived scrutinization! ---------"
  [[ $DRYRUN ]] && exit 0
}

execute_command() {
  ######################### COMMANDS WITH TOPIC ARGUMENT
  if [[ ! $TOPIC_EXP && ! $MULTIPLE ]]; then
    case $MODE in
      go) cd "$ARCHIVE_PATH" ;;
      update)
        for file in $(find "$ARCHIVE_PATH" -mindepth 2 -iname 'README*'\
          | perl -e 'print sort { length($b) <=> length($a) } <>'); do
          cd $(dirname "$file");
          mkdir -p 'assets'

          for file in $(ls -1 | command grep -vE '(README.*|assets.*)'); do
            if test $file -nt README.*; then
              vim README.* -c 'quit'
              break
            fi
          done
        done

        cd "$ARCHIVE_PATH"
        vim README.* -c 'quit'
        ;;
      stats)
        command grep -rPh -B1 '(?=:stats: ).*' "$ARCHIVE_PATH/README".*\
          | command grep -v -- --\
          | sed -e 'N;s/\n/ /g' -re  's|:tag: (.*) :stats: (.*)|\1,\2|g' ;;
      *) echo "\"$MODE\" mode doesn't work with topic overviews!"; exit 50 ;;
    esac

  elif [[ ! $TOPIC_EXP ]]; then
    case $MODE in
      go) cd "$ARCHIVE_PATH" ;;
      stats) echo $TOPICS | tr ' ' '\n' | command grep -v "^$(dirname $ARCHIVE_PATH)" ;;
      *) echo "\"$MODE\" mode doesn't work with multiple topics!"; exit 51 ;;
    esac

  elif [[ ! $SUBTOPIC_DEF ]]; then
    case $MODE in
      go) cd "$TOPIC_EXP" ;;
      stats) command grep -rPh -B1 '(?=:stats: ).*' "$TOPIC_EXP/README".*\
        | sed -e 'N;s/\n/ /g' -re  's|:tag: (.*) :stats: (.*)|\1,\2|g' ;;
      assets) mkdir -p "$TOPIC_EXP/assets"; open -a 'Finder' "$TOPIC_EXP/assets" ;;
      *) echo "\"$MODE\" mode doesn't work with individual topics!"; exit 52 ;;
    esac

  ######################### COMMANDS WITH SUBTOPIC ARGUMENT
  elif [[ ! $SUBTOPIC_EXP && ! $MULTIPLE ]]; then
    case $MODE in
      go) $EDITOR ${SUBTOPIC_EXP:-$TOPIC_EXP/README.*} ;;
      stats) command grep -rPh -B1 '(?=:stats: ).*' "$TOPIC_EXP/README".*\
        | sed -e 'N;s/\n/ /g' -re  's|:tag: (.*) :stats: (.*)|\1,\2|g' ;;
      *) echo "\"$MODE\" mode doesn't work with subtopic overviews!"; exit 53 ;;
    esac

  elif [[ ! $SUBTOPIC_EXP || (! $QUEST_DEF && $MULTIPLE ) ]]; then
    case $MODE in
      go) $EDITOR ${SUBTOPIC_EXP:-"$TOPIC_EXP/README".*} ;;
      stats) command grep -rPh -B1 '(?=:stats: ).*' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
        | command grep -v -- --\
        | sed -e 'N;s/\n/ /g' -re  's|:tag: .*::(.*) :stats: (.*)|\1,\2|g'\
        | command grep "$SUBTOPIC_STEM" ;;
      keywords) command grep -oH '[^a-zA-Z]\*[^*`!@#$% ][^*]*[^*`!@#$% ]+\*[^a-zA-Z]' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
        | command grep -v 'assets' | sed -r -ne '{s|^.*\*([^`*]*)\*|\1|;p}' ;;
      notation) command grep -oH '^.\+`[^`*]\+`' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
        | command grep -v 'assets' | sed -r -ne '{s|^.*`([^`*]*)`|\1|;p}' ;;
      headers) command grep -noH '^=\+ .*' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
        | command grep -v 'assets'\
        | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
      comments) command grep -noH '^//\+ .*' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
        | command grep -v 'assets'\
        | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
      quests) command grep -noH '^:.*:$' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
        | command grep -v 'assets'\
        | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
      assets) command grep -noHRE '^(image|include|video)::.*' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
        | command grep -v 'assets'\
        | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
      *) echo "\"$MODE\" mode doesn't work with multiple subtopics"; exit 54 ;;
    esac

  elif [[ ! $QUEST_DEF ]]; then
    case $MODE in
      go) $EDITOR ${SUBTOPIC_EXP:-"$TOPIC_EXP/README".*} ;;
      assets) command grep -noHRE '^(image|include|video)::.*' "$SUBTOPIC_EXP"\
        | command grep -v 'assets'\
        | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
      stats) command grep -EPh -B1 '(?=:stats: ).*' "$SUBTOPIC_EXP"\
        | sed -e 'N;s/\n/ /g' -re 's|:tag: .*::(.*) :stats: (.*)|\1,\2|g' ;;
      keywords) command grep -oR '[^a-zA-Z]\*[^*`!@#$% ][^*]*[^*`!@#$% ]+\*[^a-zA-Z]' "$SUBTOPIC_EXP"\
        | command grep -v 'assets' | sed -r -ne '{s|^.*\*([^`*]*)\*|\1|;p}' ;;
      notation) command grep -oR '^.\+`[^`*]\+`' "$SUBTOPIC_EXP"\
        | command grep -v 'assets' | sed -r -ne '{s|^.*`([^`*]*)`|\1|;p}' ;;
      headers) command grep -noH '^=\+ .*' "$SUBTOPIC_EXP"\
        | command grep -v 'assets'\
        | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
      comments) command grep -noH '^//\+ .*' "$SUBTOPIC_EXP"\
        | command grep -v 'assets'\
        | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
      quests) command grep -noH '^:.*:$' "$SUBTOPIC_EXP"\
        | command grep -v 'assets'\
        | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
      *) echo "\"$MODE\" mode doesn't work with individual subtopics!"; exit 55 ;;
    esac

  ######################### COMMANDS WITH QUEST ARGUMENT
  elif [[ $MULTIPLE ]]; then
    case $MODE in
      go) $EDITOR "$SUBTOPIC_EXP" -c "/^:${QUEST_EXP:-\d\+}\a*:$/" -c 'normal! zz' ;;
      *) echo "\"$MODE\" mode doesn't work with multiple quest tags"; exit 56 ;;
    esac

  else
    case $MODE in
      go) $EDITOR "$SUBTOPIC_EXP" -c "/^:${QUEST_EXP:-\d\+}\a*:$/" -c 'normal! zz' ;;
      *) echo "\"$MODE\" mode doesn't work with individual question tags"; exit 57 ;;
    esac
  fi
}

# declare TOPICS=$(command grep -rPh -B1 '(?=:stats: ).*' $(find $ARCHIVE_PATH -type f -name 'README.*')\
#   | command grep -v -- --\
#   | sed -e 'N;s/\n/ /g' -r -e  's|:tag: ([^ ]*) :stats: (.*)|\1,\2|g')


### HANDLING OF OPTIONS
[[ ! $ARCHIVE_ROOT ]] && { echo '$ARCHIVE_ROOT is not set!';  exit 1; }

[[ $# -lt 1 || $# -gt 2 ]] && { echo 'arkutil needs 1 to 2 arguments!';  exit 2; } 

declare MODE=
case "$1" in
  ark)      MODE="$1" ;;
  paths)    MODE="$1" ;;

  stats)    MODE="$1" ;;
  headers)  MODE="$1" ;;
  keywords) MODE="$1" ;;
  notation) MODE="$1" ;;
  quests)   MODE="$1" ;;
  comments) MODE="$1" ;;
  *) echo 'Illegal command!';  exit 3 ;;
esac

[[ $2 ]] && declare ARG=${2:-''}

if [[ $MODE == 'ark' ]]; then
  cat <<-'EOF'
ark() {
  cd $ARCHIVE_ROOT
}
EOF
else
  declare TOPIC_EXP=
  declare SUBTOPIC_EXP=
  declare QUEST_EXP=
  declare MULTIPLE=
  arkutil_analyze_path $ARG
fi
