#!/usr/bin/env python3
import re
import enum
import argparse
import os

class Mode(enum.Enum):
    ''' (self) -> ([ResultDict], summary: bool)
    * Analzyes uri and returns one of the following:

    ** '@'                            -> (multiple dirs                 ,PENDANTS)
    ** 'abstract-algebra<@'           -> (multiple dirs                ,(SELECTION))
    ** ''                             -> (multiple dirs                 ,ARCHIVE)
    ** 'abstract-algebra<'            -> (multiple dirs                ,(OVERVIEW))
    ** 'group-theory'                 -> (single dir+multiple files     ,TOPIC)

    ** 'group-theory:@'               -> (single dir+multiple files     ,LEAFS)
    ** 'group-theory:group-like-@'    -> (single dir+multiple files     ,SERIES)
    ** 'group-theory:group-like-2'    -> (single dir,file               ,INDIVIDUAL)

    ** 'group-theory:group-like-2#@'  -> (single dir,file+multiple lines,QUEST_M)
    ** 'group-theory:group-like-2#5'  -> (single dir,file,lines         ,QUEST)
    '''

    ARCHIVE    = enum.auto()
    PENDANTS   = enum.auto()
    TOPIC      = enum.auto()
    LEAFS      = enum.auto()
    SERIES     = enum.auto()
    INDIVIDUAL = enum.auto()
    QUEST_M    = enum.auto()
    QUEST      = enum.auto()

class ArkUri:

    def __init__(self, uri):

        matches = re.search(
            r'^(?:([^#/:]*)//)?([^#/:]*)(?::?:([^#/:]*))?(?:#(@|\d*))?$', uri)

        if matches is not None:
            self.ancestor_component = matches.group(1) or ''
            self.pendant_component  = matches.group(2) or ''
            self.leaf_component     = matches.group(3) or ''
            self.quest_component    = matches.group(4) or ''
        else:
            theparser.error('invalid archive uri')

    def __analyze(self):

        ''' (self) -> ([ResultDict], mode: Mode, summaryName: String)
        * Analzyes uri and returns one of the following:

        ** '@'                            -> (multiple dirs                 ,PENDANTS)
        ** 'abstract-algebra<@'           -> (multiple dirs                ,~PENDANTS)
        ** ''                             -> (multiple dirs                 ,SELECTION)
        ** 'abstract-algebra<'            -> (multiple dirs                ,~SELECTION)
        ** 'group-theory'                 -> (single dir+multiple files     ,TOPIC)

        ** 'group-theory:@'               -> (single dir+multiple files     ,LEAFS)
        ** 'group-theory:group-like-@'    -> (single dir+multiple files     ,SERIES)
        ** 'group-theory:group-like-2'    -> (single dir,file               ,INDIVIDUAL)

        ** 'group-theory:group-like-2#@'  -> (single dir,file+multiple lines,QUEST_M)
        ** 'group-theory:group-like-2#5'  -> (single dir,file,lines         ,QUEST)
        '''

        mode        = Mode.ARCHIVE
        summaryName = os.environ['ARCHIVE_ROOT']
        topics      = []

        '''
        processing of ancestor topic
        '''
        if self.ancestor_component:
            matched_ancestors = []
            ancestor_regex = re.compile('/(' + self.ancestor_component.replace('-','[^./]*-') + '[^./]*)/')

        readme_regex = re.compile('^README\..*')
        for root, dirs, files in os.walk(summaryName):
            dirs[:] = [d for d in dirs if not d.startswith('.')]

            if self.ancestor_component:
                match = ancestor_regex.search(root)
                if match and any([readme_regex.search(file) for file in files]):
                    topics.append({
                        'dir':   root,
                        'files': [file for file in files if not readme_regex.search(file)],
                        'lines': []})
                    matched_ancestors.append(match.group(1))

            else:
                if any([readme_regex.search(file) for file in files]):
                    topics.append({
                        'dir':   root,
                        'files': [file for file in files if not readme_regex.search(file)],
                        'lines': []})


        if self.ancestor_component:
            unique_ancestors = set(matched_ancestors)

            if len(unique_ancestors) < 1:
                theparser.error('no such ancestor topic exists')

            if len(unique_ancestors) > 1:
                theparser.error('ancestor topic is ambiguous: ' + ' '.join(unique_ancestors))

            summaryName = unique_ancestors.pop()


        '''
        processing of pendant topic
        '''

        if self.pendant_component == '@':
            mode = Mode.PENDANTS

        elif self.pendant_component:
            mode = Mode.TOPIC
            pendant_regex = '/' + self.pendant_component.replace('-','[^./]*-') + '[^./]*$'
            topics = list(filter(lambda t: re.search(pendant_regex, t['dir']), topics))

            if len(topics) < 1:
                theparser.error('no such pendant topic exists')

            if mode == Mode.TOPIC and len(topics) > 1:
                theparser.error('pendant topic is ambiguous: '
                    + ' '.join(list(map(lambda t: os.path.basename(t['dir']), topics))))

        '''
        processing of leaf topic
        '''

        if self.leaf_component and mode != Mode.TOPIC:
            theparser.error('cannot use leaf topics without definite pendant topic')

        elif self.leaf_component:

            if self.leaf_component == '@':
                mode = Mode.LEAFS

            elif self.leaf_component.endswith('-@'):
                mode = Mode.SERIES
                leaf_regex = '^' + self.leaf_component[:-2].replace('-', '[^./]*-') + '[^./]*\..*$'
                topics[0]['files'] = list(filter(
                    lambda f: re.search(leaf_regex, f), topics[0]['files']))

            else:
                mode = Mode.INDIVIDUAL
                leaf_regex = '^' + self.leaf_component.replace('-', r'[^./]*-') + r'[^./]*\..*$'
                topics[0]['files'] = list(filter(
                    lambda f: re.search(leaf_regex, f), topics[0]['files']))


            if len(topics[0]['files']) < 1:
                theparser.error('no such leaf topic exists')

            # e.g. `gr-@` would hit `graphs-theory-1` and `groups-1`
            if mode == Mode.SERIES and len(topics[0]['files']) > 1:
                leaf_series = set(map(lambda v: re.search('(.*)-.*',v).group(1),topics[0]['files']))
                if len(leaf_series) > 1:
                    theparser.error('leaf topic series is ambiguous: '
                        + ' '.join(list(map(lambda s: os.path.basename(s), leaf_series))))

            if mode == Mode.INDIVIDUAL and len(topics[0]['files']) > 1:

                theparser.error('leaf topic is ambiguous: '
                    + ' '.join(list(map(lambda f: os.path.basename(f), topics[0]['files']))))

        '''
        processing of quest identifier
        '''

        if self.quest_component and mode != Mode.INDIVIDUAL:
            theparser.error('cannot use leaf topics without definite pendant topic')

        elif self.quest_component:

            with open(topics[0]['dir']+'/'+topics[0]['files'][0], "r") as f:
                searchlines = f.readlines()
                for idx, line in enumerate(searchlines):
                    quest_identifier = re.search(r'^:(\d+)\a*:$', line)
                    if quest_identifier:
                        topics[0]['lines'].append({
                            'quest': quest_identifier.group(1),
                            'lineno': idx})

            if self.quest_component == '@':
                mode = Mode.QUEST_M

            else:
                mode = Mode.QUEST
                quest_regex = re.search(r'^:(%s)\a*:$', line)
                topics[0]['lines'] = list(filter(
                    lambda l: l['quest'] == self.quest_component, topics[0]['lines']))

            if len(topics[0]['lines']) < 1:
                theparser.error('no such quest identifier exists in file')

            if mode == Mode.QUEST and len(topics[0]['lines']) > 1:
                theparser.error('quest is ambiguous: '
                    + ' '.join(list(map(lambda f: os.path.basename(f), topics[0]['files']))))
                # should actually never happen

        '''
        constructing the result
        '''

        if ARGV.debug:
            print('### mode:\t' + mode.name)
        return (topics, mode, summaryName)

    def paths(self):
        '''
        returns list of dirs, files, or files with linenos
        '''
        topics, mode, summaryName = self.__analyze()
        result = []

        if mode in [Mode.QUEST, Mode.QUEST_M]:
            for l in topics[0]['lines']:
                result.append(topics[0]['dir']+'/'+topics[0]['files'][0]+':'+str(l['lineno'])+':')

        elif mode in [Mode.INDIVIDUAL, Mode.SERIES, Mode.LEAFS]:
            for f in topics[0]['files']:
                result.append(topics[0]['dir']+'/'+f)

        elif mode in [Mode.TOPIC, Mode.PENDANTS]:
            for d in topics:
                result.append(d['dir'])

        elif mode in [Mode.ARCHIVE]:
            result.append(summaryName)

        else:
            theparser.error('should-never-happen error')

        return result

    def stats(self, preanalyzed=None):
        '''
        returns list of (identifer, count of content lines, count of qtags)
        '''
        topics, mode, summaryName = preanalyzed if preanalyzed is not None else self.__analyze()
        result = []

        # no special stats for quest tags atm
        # if len(topics[0]['lines']) > 0:
        #     for l in topics[0]['lines']:

        if mode in [Mode.QUEST, Mode.QUEST_M, Mode.INDIVIDUAL, Mode.SERIES, Mode.LEAFS]:
            for f in topics[0]['files']:

                with open(topics[0]['dir']+'/'+f, "r") as fx:
                    searchlines = fx.readlines()
                    for _, line in enumerate(searchlines):
                        stats_identifier = re.search('(?<=:stats: )(\d*),(\d*)', line)
                        if stats_identifier:
                            result.append((os.path.splitext(f)[0],
                                int(stats_identifier.group(1)),
                                int(stats_identifier.group(2))))
                            break

        elif mode in [Mode.TOPIC, Mode.PENDANTS]:
            for d in topics:

                all_stats = self.stats( ([d],Mode.LEAFS,'') )
                result.append((os.path.basename(d['dir']),
                               sum(map(lambda l: l[1], all_stats)),
                               sum(map(lambda l: l[2], all_stats))))

        elif mode in [Mode.ARCHIVE]:
            all_stats = self.stats( (topics,Mode.PENDANTS,'') )
            result.append((os.path.basename(summaryName),
                           sum(map(lambda l: l[1], all_stats)),
                           sum(map(lambda l: l[2], all_stats))))

        else:
            theparser.error('should-never-happen error')

        return result

    @staticmethod
    def ark():
        '''
        returns nothing
        '''
        print(r'''
ark() {
  local entry
  arr="$(quiet=errors arkutil paths "$1")"
  exitstatus=$?
  [[ ! $exitstatus == '0' ]] && return $exitstatus
  read -a entry <<< "${arr[@]}"

  if [[ -d ${entry} ]]; then
    cd "$entry"

  elif [[ -f ${entry} ]]; then
    $EDITOR "${entry}"

  elif [[ ${entry} =~ ^(.*):(.*): ]]; then
    $EDITOR "${BASH_REMATCH[1]}" +${BASH_REMATCH[2]} -c 'normal! zz'
  fi
}

alias hasq="awk '{ if(\$3 != 0) { print \$0 } }'"

''')

    @staticmethod
    def print(vals):
        for val in vals:

            if isinstance(val, tuple):
                print('\t'.join(map(lambda i: str(i), list(val))))

            else:
                print(val)

if __name__ == "__main__":
    arkParser = argparse.ArgumentParser(description='Manage and query your notes!', prog='arkutil')
    arkParser.add_argument('-q', '--quiet', action='store_true', help='do not echo result or error')
    arkParser.add_argument('-d', '--debug', action='store_true', help='do not echo result or error')

    subparsers = arkParser.add_subparsers(dest='cmd', help='command to be used with the archive uri')
    subparsers_dict = {}

    subparsers_dict['paths'] = subparsers.add_parser('paths')
    subparsers_dict['paths'].add_argument('uri', nargs='?', default='', help='archive uri you want to query')

    subparsers_dict['stats'] = subparsers.add_parser('stats')
    subparsers_dict['stats'].add_argument('uri', nargs='?', default='', help='archive uri you want to query')

    subparsers_dict['ark'] = subparsers.add_parser('ark')

    ARGV = arkParser.parse_args()

    if ARGV.cmd is not None:
        theparser = subparsers_dict[ARGV.cmd]

        if ARGV.cmd in ['paths', 'stats']:
            result = getattr(ArkUri(ARGV.uri), ARGV.cmd)()

            if not ARGV.quiet or not result:
                ArkUri.print(result)
        else:
            getattr(ArkUri, ARGV.cmd)()

