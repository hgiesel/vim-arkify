#!/usr/bin/env python3
import re
import enum
import argparse
import os
import sys
import json
import urllib.request

def ark():
    print(
'''
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

alias hasq="awk '{ if(\$2 != 0) { print \$0 } }'"
alias noq="awk '{ if(\$2 == 0) { print \$0 } }'"

alias nomatch="awk '{ if(\$2 != \$3 ) { print \$0 } }'"
''')

class Mode(enum.Enum):
    ''' modes for ArkUri.__analyze '''
    GROUP    = enum.auto() # -> GROUP

    SECTION_I      = enum.auto() # -> SECTION_I
    SECTION_A   = enum.auto() # -> SECTION_A

    PAGE_I = enum.auto() # -> PAGE_I
    PAGE_S     = enum.auto() # -> PAGE_S
    PAGE_A      = enum.auto() # -> PAGE_A
    PAGE_B = enum.auto() # -> PAGE_B

    QUEST_I    = enum.auto() # -> QUEST_I
    QUEST_SA   = enum.auto() # -> QUEST_SA
    QUEST_A    = enum.auto() # -> QUEST_A
    QUEST_B    = enum.auto() # -> QUEST_B
    QUEST_C = enum.auto() # -> QUEST_C

class ArkPrinter():
    @staticmethod
    def print_stats(vals):
        '''pretty print values from ArkUri:stats '''
        for val in vals:
            print('\t'.join([str(v) for v in list(val)]))

    @staticmethod
    def print_paths(vals):
        '''prints values from ArkUri:paths '''
        for val in vals:
            file_name, lineno = val
            if lineno is not None:
                print('{0}:{1}:'.format(file_name, lineno))
            else:
                print(file_name)

class ArkUri:
    def __init__(self, uri='', hypothetical=False):
        ''' (self) -> ([ResultDict], mode: Mode, summary_name: String)
        * Analzyes uri and returns one of the following:

        ** 'abstract-algebra<@'           -> (multiple dirs                ,~doesn't affect mode)
        ** 'abstract-algebra<'            -> (multiple dirs                ,~doesn't affect mode)

        ** ''                             -> (multiple dirs                 ,GROUP)
        ** 'group-theory'                 -> (single dir+multiple files     ,SECTION_I)

        ** 'group-theory:@'               -> (single dir+multiple files     ,PAGE_A)
        ** 'group-theory:group-like-@'    -> (single dir+multiple files     ,PAGE_S)
        ** 'group-theory:group-like-2'    -> (single dir,file               ,PAGE_I)

        ** 'group-theory:group-like-2#@'  -> (single dir,file+multiple lines,QUEST_A)
        ** 'group-theory:group-like-2#5'  -> (single dir,file,lines         ,QUES_IT)

        ** '@:@'               -> (single dir+multiple files ,QUEST_B)
        ** '@'                -> (multiple dirs              ,SECTION_A)
        ** '@:@'    -> (multiple dirs,files,lines  ,PAGE_B)
        ** '@:@#@'  -> (multiple dirs,files,lines  ,QUEST_C)
        '''

        component_regex = (# optional ancestor component
                           r'^(?:([^#/:]+)//)?'
                           # compulsory pendant component (but may be empty!)
                           r'([^#/:]*)'
                           # can't have quest identifier without leaf component!
                           r'(?:'
                           # can be one or two colons
                           r':?:'
                           # leaf component can't be empty
                           r'([^#/:]+)'
                           # quest identifer must be preceded with number sign
                           r'(?:#'
                           # quest identifer is numbers or @
                           r'(@|\d+)'
                           # closes both non capturing groups
                           r')?)?$')

        matches = re.search(component_regex, uri)

        # queries that don't need to check against the archive
        # e.g. for making match tests against Anki
        self.hypthetical = hypothetical

        if matches is not None:
            self.ancestor_component = matches.group(1) or ''
            self.pendant_component  = matches.group(2) or ''
            self.leaf_component     = matches.group(3) or ''
            self.quest_component    = matches.group(4) or ''

            tempMode = Mode.GROUP

            if self.pendant_component == '@':
                tempMode = Mode.SECTION_A

            elif self.pendant_component:
                tempMode = Mode.SECTION_I

            if tempMode == Mode.SECTION_A and self.leaf_component == '@':
                tempMode = Mode.PAGE_B

            elif tempMode == Mode.SECTION_A and self.leaf_component:
                theparser.error('query malformed: cannot use leaf topics without definite pendant topic or @')

            if tempMode == Mode.SECTION_I and self.leaf_component == '@':
                tempMode = Mode.PAGE_A
            elif tempMode == Mode.SECTION_I and self.leaf_component.endswith('-@') and len(self.leaf_component) >= 3:
                tempMode = Mode.PAGE_S
            elif tempMode == Mode.SECTION_I and self.leaf_component:
                tempMode = Mode.PAGE_I

            if self.quest_component == '@':
                if tempMode == Mode.PAGE_B:
                    tempMode = Mode.QUEST_C
                elif tempMode == Mode.PAGE_A:
                    tempMode = Mode.QUEST_B
                elif tempMode == Mode.PAGE_S:
                    tempMode = Mode.QUEST_SA
                elif tempMode == Mode.PAGE_I:
                    tempMode = Mode.QUEST_A

            elif self.quest_component and tempMode == Mode.PAGE_I:
                tempMode = Mode.QUEST_I

            elif self.quest_component:
                theparser.error('query malformed: cannot use quest identifers without definite leaf topic or @')

            self.mode = tempMode

        else:
            theparser.error('query malformed: invalid archive uri')

        if ARGV.debug:
            print('ancestor: {}\npendant: {}\nleaf: {}\nmode: {}'.format(
                   self.ancestor_component,
                   self.pendant_component,
                   self.leaf_component,
                   self.mode))

    def __analyze(self):

        summary_name = os.environ['ARCHIVE_ROOT']
        topics      = []

        '''
        processing of ancestor topic
        '''
        if self.ancestor_component:
            matched_ancestors = []
            ancestor_regex = re.compile('(.*/' + self.ancestor_component.replace('-','[^./]*-') + '[^./]*)/')

        readme_regex = re.compile('^README\..*')
        for root, dirs, files in os.walk(summary_name):
            dirs[:] = [d for d in dirs if not d.startswith('.')]
            files[:] = [f for f in files if not f.startswith('.')]

            if self.ancestor_component:
                match = ancestor_regex.search(root)
                if any([readme_regex.search(file) for file in files]) and root is not summary_name and match:
                    topics.append({
                        'dirName':   root,
                        'files': [{'fileName': file, 'lines': []} for file in files if not readme_regex.search(file)]})
                    matched_ancestors.append(match.group(1))
            else:
                if any([readme_regex.search(file) for file in files]) and root is not summary_name:
                    topics.append({
                        'dirName':   root,
                        'files': [{'fileName': file, 'lines':[]} for file in files if not readme_regex.search(file)]})

        if self.ancestor_component:
            unique_ancestors = set(matched_ancestors)

            if len(unique_ancestors) < 1:
                theparser.error('no such ancestor topic exists')

            if len(unique_ancestors) > 1:
                theparser.error('ancestor topic is ambiguous: ' +
                    ' '.join(map(lambda d: os.path.basename(d), unique_ancestors)))

            summary_name = unique_ancestors.pop()

        '''
        processing of pendant topic
        '''
        if self.pendant_component and not self.pendant_component == '@':
            pendant_regex = '/' + self.pendant_component.replace('-','[^./]*-') + '[^./]*$'
            topics = list(filter(lambda t: re.search(pendant_regex, t['dirName']), topics))

            if len(topics) < 1:
                theparser.error('no such pendant topic exists')

            if len(topics) > 1:
                theparser.error('pendant topic is ambiguous: '
                    + ' '.join(list(map(lambda t: os.path.basename(t['dirName']), topics))))

        '''
        processing of leaf topic
        '''

        first_dir = topics[0]


        if self.mode == Mode.PAGE_S or self.mode == Mode.QUEST_SA:
            leaf_regex = '^' + self.leaf_component[:-2].replace('-', '[^./]*-') + '[^./]*\..*$'
            first_dir['files'] = list(filter(
                lambda f: re.search(leaf_regex, f['fileName']), first_dir['files']))

        elif self.leaf_component and not self.leaf_component.endswith('@'):
            leaf_regex = '^' + self.leaf_component.replace('-', r'[^./]*-') + r'[^./]*\..*$'
            first_dir['files'] = list(filter(
                lambda f: re.search(leaf_regex, f['fileName']), first_dir['files']))

        if len(first_dir['files']) < 1:
            theparser.error('no such leaf topic exists')

        # e.g. `gr-@` would hit `graphs-theory-1` and `groups-1`
        if self.leaf_component.endswith('-@') and len(first_dir['files']) > 1:
            leaf_series = set(map(lambda f: re.search('(.*)-.*', f['fileName']).group(1), first_dir['files']))
            if len(leaf_series) > 1:
                theparser.error('leaf topic series is ambiguous: '
                    + ' '.join(list(map(lambda s: os.path.basename(s), leaf_series))))

        elif self.pendant_component and not self.pendant_component == '@' and len(first_dir['files']) > 1:
            theparser.error('leaf topic is ambiguous: '
                + ' '.join(list(map(lambda f:
                    os.path.splitext(os.path.basename(f['fileName']))[0], first_dir['files']) )))

        '''
        processing of quest identifier
        '''

        if self.quest_component:
            for d in topics:
                for f in d['files']:
                    with open(d['dirName']+'/'+f['fileName'], 'r') as stream:
                        searchlines = stream.readlines()
                        for idx, line in enumerate(searchlines):
                            quest_identifier = re.search(r'^:(\d+)\a*:$', line)
                            if quest_identifier:
                                f['lines'].append({
                                    'lineno': idx,
                                    'quest': quest_identifier.group(1)})


        if self.mode == Mode.QUEST_I:
            first_dir  = topics[0]
            first_file = topics[0]['files'][0]

            # quest_regex = re.search(r'^:(%s)\a*:$', line)

            first_file['lines'] = list(filter(
                lambda l: l['quest'] == self.quest_component, first_file['lines']))

            if len(first_file['lines']) < 1:
                theparser.error('no such quest identifier exists in file')

            elif len(first_file['lines']) > 1:
                theparser.error('quest is ambiguous: '
                    + ' '.join(list(map(lambda f: os.path.basename(f['fileName']), first_file))))
                # should actually never happen

        '''
        constructing the result
        '''

        return (topics, summary_name)

    def paths(self):
        '''
        returns list of dirs, files, or files with linenos
        '''
        topics, summary_name = self.__analyze()
        result = []

        if self.mode in [Mode.QUEST_C, Mode.QUEST_B, Mode.QUEST_SA, Mode.QUEST_A, Mode.QUEST_I]:
            for d in topics:
                for f in d['files']:
                    for l in f['lines']:
                        result.append( (d['dirName'] + '/' + f['fileName'], l['lineno']) )

        elif self.mode in [Mode.PAGE_B, Mode.PAGE_A, Mode.PAGE_S, Mode.PAGE_I]:
            for d in topics:
                for f in d['files']:
                    result.append( (topics[0]['dirName']+'/'+f['fileName'], None) )

        elif self.mode in [Mode.SECTION_A, Mode.SECTION_I]:
            for d in topics:
                result.append( (d['dirName'],None) )

        elif self.mode in [Mode.GROUP]:
            result.append( (summary_name,None) )

        else:
            theparser.error('should-never-happen error')

        return result

    def stats(self, preanalyzed=None, fakeMode=None):
        '''
        returns list of (identifer, count of content lines, count of qtags)
        '''
        topics, summary_name = preanalyzed if preanalyzed is not None else self.__analyze()
        mode = fakeMode if fakeMode is not None else self.mode

        result = []

        if mode in [Mode.QUEST_I, Mode.QUEST_A, Mode.QUEST_SA, Mode.QUEST_B, Mode.QUEST_C]:
            for d in topics:
                for f in d['files']:
                    for l in f['lines']:

                        display_name = ''
                        if len(topics) == 1:
                            display_name = os.path.splitext(f['fileName'])[0]
                        else:
                            display_name = os.path.basename(d['dirName']) + ':' + os.path.splitext(f['fileName'])[0]

                        result.append( (display_name,
                            l['quest'],
                            l['lineno']) )

        elif mode in [Mode.PAGE_I, Mode.PAGE_S, Mode.PAGE_A, Mode.PAGE_B]:

            for d in topics:
                for f in d['files']:
                    with open(d['dirName']+'/'+f['fileName'], "r") as fx:
                        searchlines = fx.readlines()
                        for _, line in enumerate(searchlines):
                            stats_identifier = re.search('(?<=:stats: )(\d*),(\d*)', line)
                            if stats_identifier:

                                display_name = ''
                                if len(topics) == 1:
                                    display_name = os.path.splitext(f['fileName'])[0]
                                else:
                                    display_name = os.path.basename(d['dirName']) + ':' + os.path.splitext(f['fileName'])[0]

                                result.append((display_name,
                                    stats_identifier.group(1),  # questions
                                    stats_identifier.group(2))) # content lines

        elif mode in [Mode.SECTION_I, Mode.SECTION_A]:

            for d in topics:
                all_stats = self.stats( ([d],''), Mode.PAGE_A )
                result.append((os.path.basename(d['dirName']),
                    str(sum(map(lambda l: int(l[1]), all_stats))),
                    str(sum(map(lambda l: int(l[2]), all_stats)))))

        elif mode in [Mode.GROUP]:

            all_stats = self.stats( (topics,''), Mode.PAGE_A )
            result.append((os.path.basename(summary_name),
                str(sum(map(lambda l: int(l[1]), all_stats))),
                str(sum(map(lambda l: int(l[2]), all_stats)))))

        else:
            theparser.error('should-never-happen error')

        return result

    def query(self, validate=False, type='anki'):
        if validate:
            analyzee = self.__analyze()
        else:
            analyzee = None

        result = []
        result.append('card:1')


        pc = self.pendant_component.replace('@', '').replace('-', '*-') + '*' if self.pendant_component else '*'
        lc = self.leaf_component.replace('@', '').replace('-', '*-') + '*' if self.pendant_component else '*'
        qc = self.quest_component.replace('@', '*') if self.pendant_component else '*'

        result.append('tag:' + pc + '::' + lc)
        result.append('Quest:'+ '"*' + ':' + qc +':' +'*"')

        return result

    def match(self, db, type='anki'):

        stats = self.stats()
        result = []

        if self.mode in [Mode.QUEST_I, Mode.QUEST_SA, Mode.QUEST_A, Mode.QUEST_B, Mode.QUEST_C]:

            queries = []
            for entry in stats:
                if self.mode == Mode.QUEST_C:
                    constructed_quest = entry[1]
                    constructed_pendant, constructed_leaf = entry[0].split(':')
                else:
                    constructed_quest = entry[1]
                    constructed_pendant, constructed_leaf = self.pendant_component, entry[0]

                constructed_uri = constructed_pendant + ':' + constructed_leaf + '#' + constructed_quest
                queries.append(' '.join(ArkUri(constructed_uri).query()))

            remote_qcounts = db.anki_query_count(queries)

            # print(str(queries) + ' ### ' + str(remote_qcounts))
            for t in tuple(zip(stats, remote_qcounts)):
                result.append( (t[0][0], t[0][1], t[1]) )
            pass

        elif self.mode in [Mode.PAGE_I, Mode.PAGE_S, Mode.PAGE_A, Mode.PAGE_B]:

            queries = []
            for entry in stats:
                if self.mode == Mode.PAGE_B:
                    constructed_pendant, constructed_leaf = entry[0].split(':')
                else:
                    constructed_pendant, constructed_leaf = self.pendant_component, entry[0]

                constructed_uri = constructed_pendant + ':' + constructed_leaf
                queries.append(' '.join(ArkUri(constructed_uri).query()))

            remote_qcounts = db.anki_query_count(queries)

            for t in tuple(zip(stats, remote_qcounts)):
                result.append( (t[0][0], t[0][1], t[1]) )

        elif self.mode in [Mode.SECTION_I, Mode.SECTION_A]:

            queries = []
            for entry in stats:
                queries.append(' '.join(ArkUri(entry[0]).query()))

            remote_qcounts = db.anki_query_count(queries)

            for t in tuple(zip(stats, remote_qcounts)):
                result.append( (t[0][0], t[0][1], t[1]) )

        elif self.mode in [Mode.GROUP]:
            remote_qcount = db.anki_query_count([' '.join(self.query())])
            result.append( (stats[0][0], stats[0][1], remote_qcount[0]) )

        return result

class AnkiConnection:
    def __init__(self, port=8765, deck_name=''):
        '''setup connection to anki'''
        self.req = urllib.request.Request('http://localhost:' + str(port))
        self.req.add_header('Content-Type', 'application/json; charset=utf-8')
        self.deck_name = deck_name

    def anki_add(self, json):
        pass

    def anki_query_count(self, query_list, back_check=False):

        json_query = json.dumps({
            'action': 'multi',
            'version': 6,
            'params': {
                'actions': [{
                    'action': 'findNotes',
                    'params': { 'query': q + ' deck:{}*'.format(self.deck_name) }
                    } for q in query_list]
                }
            }).encode('utf-8')

        response = urllib.request.urlopen(self.req, json_query)
        res_string = (response.read().decode('utf-8'))
        res_json = json.loads(res_string)

        return [len(r) for r in res_json['result']]

    def anki_delete(self):
        pass

    def anki_match(self):
        pass

if __name__ == '__main__':
    arkParser = argparse.ArgumentParser(description='Manage and query your notes!',
        prog='arkutil')

    arkParser.add_argument('-q', '--quiet', action='store_true',
        help='do not echo result or error')
    arkParser.add_argument('-d', '--debug', action='store_true',
        help='do not echo result or error')

    subparsers = arkParser.add_subparsers(dest='cmd',
        help='command to be used with the archive uri')
    subparsers_dict = {}

    subparsers_dict['paths'] = subparsers.add_parser('paths')
    subparsers_dict['paths'].add_argument('uri', nargs='?', default='',
        help='archive uri you want to query')

    subparsers_dict['stats'] = subparsers.add_parser('stats')
    subparsers_dict['stats'].add_argument('uri', nargs='?', default='',
        help='archive uri you want to query')

    subparsers_dict['query'] = subparsers.add_parser('query')
    subparsers_dict['query'].add_argument('-v', '--validate', action='store_true',
            default=False, help='get a query you can use in Anki')
    subparsers_dict['query'].add_argument('uri', nargs='?', default='',
        help='additionally verify uri against archive')

    subparsers_dict['match'] = subparsers.add_parser('match')
    subparsers_dict['match'].add_argument('uri', nargs='?', default='',
        help='match cards and see if any are missing or extra')

    subparsers_dict['ark'] = subparsers.add_parser('ark')

    ARGV = arkParser.parse_args()

    # if getattr(ARGV, 'infile', None):
    #     data = ARGV.infile.read().replace('\n', '<br />')
    #     print(data)

    if ARGV.cmd is not None:
        theparser = subparsers_dict[ARGV.cmd]

        result = None

        if ARGV.cmd == 'paths':
            result = getattr(ArkUri(ARGV.uri), ARGV.cmd)()
            ArkPrinter.print_paths(result)

        elif ARGV.cmd == 'stats':
            result = getattr(ArkUri(ARGV.uri), ARGV.cmd)()
            ArkPrinter.print_stats(result)

        elif ARGV.cmd == 'query':
            result = getattr(ArkUri(ARGV.uri), ARGV.cmd)(ARGV.validate)
            print(' '.join(result))

        elif ARGV.cmd == 'match':
            result = getattr(ArkUri(ARGV.uri), ARGV.cmd)(AnkiConnection(deck_name='misc::head'))
            ArkPrinter.print_stats(result)

        elif ARGV.cmd == 'ark':
            ark()

        else:
            getattr(ArkUri(ARGV.uri), ARGV.cmd)()
