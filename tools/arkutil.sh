#!/usr/bin/env bash

arkutil_analyze_path() {
  local uri="$1" debug="$2" quiet=errors

  if [[ "$uri" =~ ^([^#:]*):?:?([^#:]*)#?([^#:]*)$ ]]; then
    local uriComponents
    read -a uriComponents <<< "${BASH_REMATCH[@]:1}"
  fi

  [[ $debug ]] && echo \#\#\# 'uriComponents' "${uriComponents[@]}"

  #######################################################}}}
  ##### processing of pendant topic
  #######################################################{{{

  local pendantTopicsAvailable
  read -a pendantTopicsAvailable <<< "$(find $ARCHIVE_ROOT\
    -mindepth 2 -type f -name 'README\.*' -printf '%h ')"

  local pendantTopics
  if [[ "${uriComponents[0]}" == '@' ]]; then
    local multiple=pendants
    read -a pendantTopics <<< "${pendantTopicsAvailable[@]}"

  elif [[ "${uriComponents[0]}" ]]; then
    pendantTopicRegex="/${uriComponents[0]//-/[^./]*-}[^./]*$"
    read -a pendantTopics <<< "$(IFS=$'\n'; echo "${pendantTopicsAvailable[*]}"\
      | grep "$pendantTopicRegex" | xargs)"
  fi

  ##### validity checks and error reporting #####

  [[ $debug ]]\
    && echo \#\#\# 'multiple' "${multiple:-false}" 'pendantRegex' "${pendantTopicRegex}"\
    && echo \#\#\# 'pendantTopics' "${pendantTopics[@]}" && echo \#\#\#

  if [[ "${#pendantTopics[@]}" -lt 1 ]]; then
    [[ ! $quiet ]] && echo "arkutil: no such pendant topic exists"
    exit 12
  fi

  if [[ "${#pendantTopics[@]}" -gt 1 && ! $multiple ]]; then
    [[ ! $quiet ]] && echo "arkutil: pendant topic is ambiguous: $(basename -a "${pendantTopics[@]}" | xargs)"
    exit 13
  fi

  #######################################################}}}
  ##### processing of leaf topic
  #######################################################{{{

  if [[ "${uriComponents[1]}" && "$multiple" ]]; then

    [[ ! $quiet ]] && echo "arkutil: cannot use leaf topics without definite pendant topic"
    exit 14

  elif [[ "${uriComponents[1]}" ]]; then

    local leafTopicsAvailable
    read -a leafTopicsAvailable <<< "$(find "${pendantTopics}"\
      -maxdepth 1 -name 'README\.*' -prune -o -type f -printf '%p ')"

    local leafTopics
    if [[ ${uriComponents[1]} == '@' ]]; then
      local multiple=leafs
      read -a leafTopics <<< "${leafTopicsAvailable[@]}"

    elif [[ ${uriComponents[1]} =~ -@$ ]]; then
      local multiple=series

      local shortenedComponent="${uriComponents[1]%-@}"
      local leafTopicRegex="/${shortenedComponent//-/[^./]*-}[^./]*\..*$"

      read -a leafTopics <<< "$(IFS=$'\n'; echo "${leafTopicsAvailable[*]}"\
        | grep "$leafTopicRegex" | xargs)"

    else
      local leafTopicRegex="/${uriComponents[1]//-/[^./]*-}[^./]*\..*$"
      read -a leafTopics <<< "$(IFS=$'\n'; echo "${leafTopicsAvailable[*]}"\
        | grep "$leafTopicRegex" | tr '\n' ' ')"
    fi

    ##### validity checks and error reporting #####

    [[ "$debug" ]]\
      && echo \#\#\# 'multiple' "${multiple:-false}" 'leafTopicRegex' "${leafTopicRegex}"\
      && echo \#\#\# 'leafTopics' "${leafTopics[@]}" && echo \#\#\#

    if [[ "${#leafTopics[@]}" -lt 1 ]]; then
      [[ ! $quiet ]] && echo "arkutil: no such leaf topic exists"
      exit 15
    fi

    if [[ "${#leafTopics[@]}" -gt 1 && "$multiple" == 'series' ]]; then
      local leafSeries
      read -a leafSeries <<< $(basename -a "${leafTopics[@]%-*}" | sort -u | xargs)

        # e.g. `gr-@` would hit `graphs-theory-1` and `groups-1`
        if [[ "${#leafSeries[@]}" -gt 1 ]]; then
          [[ ! $quiet ]] && echo "arkutil: leaf topic series is ambiguous: ${leafSeries[*]}"
          exit 16
        fi
    fi

    if [[ "${#leafTopics[@]}" -gt 1 && ! "$multiple" ]]; then
      [[ ! $quiet ]] && echo "arkutil: leaf topic is ambiguous: $(basename -a "${leafTopics[@]%.*}" | xargs)"
      exit 17
    fi
  fi

  #######################################################}}}
  ##### processing of quest identifier
  #######################################################{{{

  if [[ ! "${uriComponents[2]}" =~ ^[@0-9]*$ ]]; then
    [[ ! $quiet ]] && echo "arkutil: quest identifers must contain of numbers exclusively"
    exit 18
  fi

  if [[ "${uriComponents[2]}" && "$multiple" ]]; then

    [[ ! $quiet ]] && echo "arkutil: cannot use quest identifiers without definite pendant topic"
    exit 19

  elif [[ "${uriComponents[2]}" ]]; then

    local questIdentifiersAvailable
    read -a questIdentifiersAvailable <<<\
      "$(command grep -n '^:[[:digit:]]\+[[:alpha:]]*:$' "${leafTopics}" | xargs)"

    local questIdentifiers
    if [[ ${uriComponents[2]} == '@' ]]; then
      local multiple=quests
      read -a questIdentifiers <<< "${questIdentifiersAvailable[@]}"

    else
      read -a questIdentifiers <<< "$(IFS=$'\n'; echo "${questIdentifiersAvailable[*]}"\
        | grep "[0-9]\+:[^0-9]*${uriComponents[2]}[^0-9]*" | xargs)"
    fi

    ##### validity checks and error reporting #####

    [[ "$debug" ]]\
      && echo \#\#\# 'multiple' "${multiple:-false}"\
      && echo \#\#\# 'questIdentifierAvailable' "${questIdentifiersAvailable[@]}" && echo \#\#\#\
      && echo \#\#\# 'questIdentifiers' "${questIdentifiers[@]}" && echo \#\#\#

    if [[ "${uriComponents[2]}" && "${#questIdentifiers[@]}" -lt 1 ]]; then
      [[ ! $quiet ]] && echo "arkutil: no such quest identifier exists in file"
      exit 20
    fi

    if [[ "${uriComponents[2]}" && "${#questIdentifiers[@]}" -gt 1 && ! "$multiple" ]]; then
      [[ ! $quiet ]] && echo echo "arkutil: quest is ambiguous: ${questIdentifiers[@]}"
      exit 21
    fi

    local -a quests
    for line in "${questIdentifiers[@]}"; do
      quests+=("${leafTopics}:${line%%:*}:")
    done
  fi

  #######################################################}}}
  ##### constructing result
  #######################################################{{{

  if [[ ! $quiet == 'all' ]]; then
    if [[ ${quests[@]} ]]; then
      echo "${quests[*]}"
    elif [[ "${leafTopics[@]}" ]]; then
      echo "${leafTopics[*]}"
    else
      echo "${pendantTopics[*]}"
    fi
  fi

  exit 0
}

# execute_command() {
#   ######################### COMMANDS WITH TOPIC ARGUMENT
#   if [[ ! $TOPIC_EXP && ! $MULTIPLE ]]; then
#     case $MODE in
#       update)
#         for file in $(find "$ARCHIVE_ROOT" -mindepth 2 -iname 'README*'\
#           | perl -e 'print sort { length($b) <=> length($a) } <>'); do
#           cd $(dirname "$file");
#           mkdir -p 'assets'

#           for file in $(ls -1 | command grep -vE '(README.*|assets.*)'); do
#             if test $file -nt README.*; then
#               vim README.* -c 'quit'
#               break
#             fi
#           done
#         done

#         cd "$ARCHIVE_ROOT"
#         vim README.* -c 'quit'
#         ;;
#       stats)
#         command grep -rPh -B1 '(?=:stats: ).*' "$ARCHIVE_ROOT/README".*\
#           | command grep -v -- --\
#           | sed -e 'N;s/\n/ /g' -re  's|:tag: (.*) :stats: (.*)|\1,\2|g' ;;
#       *) echo "\"$MODE\" mode doesn't work with topic overviews!"; exit 50 ;;
#     esac

#   elif [[ ! $TOPIC_EXP ]]; then
#     case $MODE in
#       stats) echo $TOPICS | tr ' ' '\n' | command grep -v "^$(dirname $ARCHIVE_ROOT)" ;;
#       *) echo "\"$MODE\" mode doesn't work with multiple topics!"; exit 51 ;;
#     esac

#   elif [[ ! $SUBTOPIC_DEF ]]; then
#     case $MODE in
#       stats) command grep -rPh -B1 '(?=:stats: ).*' "$TOPIC_EXP/README".*\
#         | sed -e 'N;s/\n/ /g' -re  's|:tag: (.*) :stats: (.*)|\1,\2|g' ;;
#       assets) mkdir -p "$TOPIC_EXP/assets"; open -a 'Finder' "$TOPIC_EXP/assets" ;;
#       *) echo "\"$MODE\" mode doesn't work with individual topics!"; exit 52 ;;
#     esac

#   ######################### COMMANDS WITH SUBTOPIC ARGUMENT
#   elif [[ ! $SUBTOPIC_EXP && ! $MULTIPLE ]]; then
#     case $MODE in
#       stats) command grep -rPh -B1 '(?=:stats: ).*' "$TOPIC_EXP/README".*\
#         | sed -e 'N;s/\n/ /g' -re  's|:tag: (.*) :stats: (.*)|\1,\2|g' ;;
#       *) echo "\"$MODE\" mode doesn't work with subtopic overviews!"; exit 53 ;;
#     esac

#   elif [[ ! $SUBTOPIC_EXP || (! $QUEST_DEF && $MULTIPLE ) ]]; then
#     case $MODE in
#       stats) command grep -rPh -B1 '(?=:stats: ).*' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
#         | command grep -v -- --\
#         | sed -e 'N;s/\n/ /g' -re  's|:tag: .*::(.*) :stats: (.*)|\1,\2|g'\
#         | command grep "$SUBTOPIC_STEM" ;;
#       keywords) command grep -oH '[^a-zA-Z]\*[^*`!@#$% ][^*]*[^*`!@#$% ]+\*[^a-zA-Z]' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
#         | command grep -v 'assets' | sed -r -ne '{s|^.*\*([^`*]*)\*|\1|;p}' ;;
#       notation) command grep -oH '^.\+`[^`*]\+`' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
#         | command grep -v 'assets' | sed -r -ne '{s|^.*`([^`*]*)`|\1|;p}' ;;
#       headers) command grep -noH '^=\+ .*' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
#         | command grep -v 'assets'\
#         | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
#       comments) command grep -noH '^//\+ .*' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
#         | command grep -v 'assets'\
#         | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
#       quests) command grep -noH '^:.*:$' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
#         | command grep -v 'assets'\
#         | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
#       assets) command grep -noHRE '^(image|include|video)::.*' "$TOPIC_EXP/$SUBTOPIC_STEM"*\
#         | command grep -v 'assets'\
#         | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
#       *) echo "\"$MODE\" mode doesn't work with multiple subtopics"; exit 54 ;;
#     esac

#   elif [[ ! $QUEST_DEF ]]; then
#     case $MODE in
#       assets) command grep -noHRE '^(image|include|video)::.*' "$SUBTOPIC_EXP"\
#         | command grep -v 'assets'\
#         | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
#       stats) command grep -EPh -B1 '(?=:stats: ).*' "$SUBTOPIC_EXP"\
#         | sed -e 'N;s/\n/ /g' -re 's|:tag: .*::(.*) :stats: (.*)|\1,\2|g' ;;
#       keywords) command grep -oR '[^a-zA-Z]\*[^*`!@#$% ][^*]*[^*`!@#$% ]+\*[^a-zA-Z]' "$SUBTOPIC_EXP"\
#         | command grep -v 'assets' | sed -r -ne '{s|^.*\*([^`*]*)\*|\1|;p}' ;;
#       notation) command grep -oR '^.\+`[^`*]\+`' "$SUBTOPIC_EXP"\
#         | command grep -v 'assets' | sed -r -ne '{s|^.*`([^`*]*)`|\1|;p}' ;;
#       headers) command grep -noH '^=\+ .*' "$SUBTOPIC_EXP"\
#         | command grep -v 'assets'\
#         | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
#       comments) command grep -noH '^//\+ .*' "$SUBTOPIC_EXP"\
#         | command grep -v 'assets'\
#         | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
#       quests) command grep -noH '^:.*:$' "$SUBTOPIC_EXP"\
#         | command grep -v 'assets'\
#         | sed -E -e 's|^[^:]*/||' -e 's|\.[^:]*:([[:digit:]]+):|,\1,|' ;;
#       *) echo "\"$MODE\" mode doesn't work with individual subtopics!"; exit 55 ;;
#     esac

#   ######################### COMMANDS WITH QUEST ARGUMENT
#   elif [[ $MULTIPLE ]]; then
#     case $MODE in
#       *) echo "\"$MODE\" mode doesn't work with multiple quest tags"; exit 56 ;;
#     esac

#   else
#     case $MODE in
#       *) echo "\"$MODE\" mode doesn't work with individual question tags"; exit 57 ;;
#     esac
#   fi
# }


### handling of options
[[ ! $ARCHIVE_ROOT ]] && { echo '$ARCHIVE_ROOT is not set!';  exit 1; }

[[ $# -lt 1 || $# -gt 2 ]] && { echo 'arkutil needs 1 to 2 arguments!';  exit 2; } 

case "$1" in
  ark|paths) arkMode="$1" ;;

  stats|refs|backrefs) arkMode="$1" ;;
  headers|headers|keywords) arkMode="$1" ;;
  notation|quests|comments)  MarkMode="$1" ;;
  *) echo 'Illegal command!';  exit 3 ;;
esac

[[ $2 ]] && declare ARG=${2:-''}

if [[ "$arkMode" == 'ark' ]]; then
  cat <<-'EOF'
ark() {
  if [[ -z "$1" ]]; then
    cd $ARCHIVE_ROOT
  else
    local entry
    entry=$(quiet=errors arkutil paths "$1")
    exitstatus=$?
    [[ ! $exitstatus == '0' ]] && return $exitstatus

    if [[ -d "${entry}" ]]; then
      cd "$entry"
    elif [[ -f "${entry}" ]]; then
      $EDITOR "${entry}"
    else
      if [[ "${entry}" =~ ^(.*):(.*):$ ]]; then
        $EDITOR "${BASH_REMATCH[1]}" +${BASH_REMATCH[2]} -c 'normal! zz'
      fi
    fi
  fi
}
EOF
else
  declare TOPIC_EXP=
  declare SUBTOPIC_EXP=
  declare QUEST_EXP=
  declare MULTIPLE=
  arkutil_analyze_path $ARG
  echo $TOPIC_EXP $SUBTOPIC_EXP $QUEST_EXP $MULTIPLE
fi
