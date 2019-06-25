#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import argparse
import os
import sys

py3 = sys.version_info.major == 3


def warn(msg):
    print('[powerline-bash] ', msg)


if py3:
    def unicode(x):
        return x


class Powerline: #{{{
    color_templates = {
        'bash': '\\[\\e%s\\]',
        'zsh': '%%{%s%%}',
        'bare': '%s',
    }

    def __init__(self, args):
        self.args = args
        self.cwd_max_dir_size = 12
        self.cwd_max_depth = 3
        self.cwd_mode = 'fancy'   #{fancy,plain,dironly}
        self.mode = 'compatible'
        self.shell = 'bash'
        self.color_template = self.color_templates[self.shell]
        self.reset = self.color_template % '[0m'
        self.lock = 'RO'
        self.network = 'SSH'
        self.separator = ''
        self.separator_thin = '/'
        self.segments = []

    def color(self, prefix, code):
        if code is None:
            return ''
        else:
            return self.color_template % ('[%s;5;%sm' % (prefix, code))

    def fgcolor(self, code):
        return self.color('38', code)

    def bgcolor(self, code):
        return self.color('48', code)

    def append(self, content, fg, bg, separator=None, separator_fg=None):
        self.segments.append((content, fg, bg,
            separator if separator is not None else self.separator,
            separator_fg if separator_fg is not None else Color.SEPARATOR_FG))

    def draw(self):
        text = (''.join(self.draw_segment(i) for i in range(len(self.segments)))
                + self.reset) + ' '
        if py3:
            return text
        else:
            return text.encode('utf-8')

    def draw_segment(self, idx):
        segment = self.segments[idx]
        next_segment = self.segments[idx + 1] if idx < len(self.segments)-1 else None

        return ''.join((
            self.fgcolor(segment[1]),
            self.bgcolor(segment[2]),
            segment[0],
            self.bgcolor(next_segment[2]) if next_segment else self.reset,
            self.fgcolor(segment[4]),
            segment[3]))
#}}}

class RepoStats: #{{{
    symbols = {
        # 'detached': '⚓',
        'detached': 'detached',
        'ahead': '↑',
        'behind': '↓',
        # 'staged': '✔',
        'staged': 'staged',
        'not_staged': '+',
        # 'not_staged': '✎',
        'untracked': '?',
        'conflicted': '*'
    }

    def __init__(self):
        self.ahead = 0
        self.behind = 0
        self.untracked = 0
        self.not_staged = 0
        self.staged = 0
        self.conflicted = 0

    @property
    def dirty(self):
        qualifiers = [
            self.untracked,
            self.not_staged,
            self.staged,
            self.conflicted,
        ]
        return sum(qualifiers) > 0

    def __getitem__(self, _key):
        return getattr(self, _key)

    def n_or_empty(self, _key):
        return unicode(self[_key]) if int(self[_key]) > 1 else u''

    def add_to_powerline(self, powerline, color):
        def add(_key, fg, bg):
            if self[_key]:
                s = u" {}{}".format(self.n_or_empty(_key), self.symbols[_key])
                powerline.append(s, fg, bg,'')

        add('ahead', color.GIT_AHEAD_FG, color.GIT_AHEAD_BG)
        add('behind', color.GIT_BEHIND_FG, color.GIT_BEHIND_BG)
        add('staged', color.GIT_STAGED_FG, color.GIT_STAGED_BG)
        add('not_staged', color.GIT_NOTSTAGED_FG, color.GIT_NOTSTAGED_BG)
        add('untracked', color.GIT_UNTRACKED_FG, color.GIT_UNTRACKED_BG)
        add('conflicted', color.GIT_CONFLICTED_FG, color.GIT_CONFLICTED_BG)
#}}}

def get_valid_cwd(): #{{{
    """ We check if the current working directory is valid or not. Typically
        happens when you checkout a different branch on git that doesn't have
        this directory.
        We return the original cwd because the shell still considers that to be
        the working directory, so returning our guess will confuse people
    """
    # Prefer the PWD environment variable. Python's os.getcwd function follows
    # symbolic links, which is undesirable. But if PWD is not set then fall
    # back to this func
    try:
        cwd = os.getenv('PWD') or os.getcwd()
    except:
        warn("Your current directory is invalid. If you open a ticket at " +
            "https://github.com/milkbikis/powerline-shell/issues/new " +
            "we would love to help fix the issue.")
        sys.stdout.write("> ")
        sys.exit(1)

    parts = cwd.split(os.sep)
    up = cwd
    while parts and not os.path.exists(up):
        parts.pop()
        up = os.sep.join(parts)
    if cwd != up:
        warn("Your current directory is invalid. Lowest valid directory: "
            + up)
    return cwd
#}}}

if __name__ == "__main__": #{{{
    arg_parser = argparse.ArgumentParser()
    
    arg_parser.add_argument('prev_error', nargs='?', type=int, default=0,
            help='Error code returned by the last command')
    
    args = arg_parser.parse_args()

    powerline = Powerline(args)
#}}}

class Color:#{{{
    USERNAME_FG = 15
    USERNAME_BG = 0
    USERNAME_ROOT_BG = 1

    HOSTNAME_FG = 15
    HOSTNAME_BG = 0

    HOME_FG = 15 
    HOME_BG = 0  
    PATH_FG = 3
    PATH_BG = 0
    CWD_FG = 3
    SEPARATOR_FG = 2
    SEPARATOR_THIN_FG = 14

    READONLY_BG = 0
    READONLY_FG = 1

    SSH_BG = 0 
    SSH_FG = 1

    REPO_CLEAN_FG = 14
    REPO_CLEAN_BG = 0
    REPO_DIRTY_FG = 9
    REPO_DIRTY_BG = 0

    JOBS_FG = 4
    JOBS_BG = 8

    CMD_PASSED_FG = 13
    CMD_PASSED_BG = 0
    CMD_FAILED_FG = 0
    CMD_FAILED_BG = 1

    SVN_CHANGES_FG = REPO_DIRTY_FG
    SVN_CHANGES_BG = REPO_DIRTY_BG

    VIRTUAL_ENV_BG = 0
    VIRTUAL_ENV_FG = 2
    
    GIT_AHEAD_BG = 0
    GIT_AHEAD_FG = 250
    GIT_BEHIND_BG = 0
    GIT_BEHIND_FG = 250
    GIT_STAGED_BG = 0
    GIT_STAGED_FG = 15
    GIT_NOTSTAGED_BG = 0
    GIT_NOTSTAGED_FG = 15
    GIT_UNTRACKED_BG = 0
    GIT_UNTRACKED_FG = 15
    GIT_CONFLICTED_BG = 9
    GIT_CONFLICTED_FG = 15
#}}}

# add_begin_wrap(powerline){{{
def add_begin_wrap(powerline):
    bg = Color.CMD_PASSED_BG
    fg = Color.CMD_PASSED_FG
    powerline.append('[', fg, bg,'')
# }}}
# add_virtual_env_segment(powerline){{{
import os

def add_virtual_env_segment(powerline):
    env = os.getenv('VIRTUAL_ENV') or os.getenv('CONDA_ENV_PATH')
    if env is None:
        return

    env_name = os.path.basename(env)
    bg = Color.VIRTUAL_ENV_BG
    fg = Color.VIRTUAL_ENV_FG
    powerline.append(' %s ' % env_name, fg, bg)
# }}}
# add_ssh_segment(powerline){{{
import os

def add_ssh_segment(powerline):

    if os.getenv('SSH_CLIENT'):
        powerline.append('%s' % powerline.network, Color.SSH_FG, Color.SSH_BG, '>')
# }}}
# add_read_only_segment(powerline){{{
import os

def add_read_only_segment(powerline):
    cwd = get_valid_cwd() or os.getenv('PWD')

    if not os.access(cwd, os.W_OK):
        powerline.append('%s' % powerline.lock, Color.READONLY_FG, Color.READONLY_BG, '>')
# }}}
# add_username_segment(powerline){{{
def add_username_segment(powerline):
    import os
    if os.getenv('SSH_CLIENT'):
        if powerline.shell == 'bash':
            user_prompt = '\\u'
        elif powerline.shell == 'zsh':
            user_prompt = '%n'
        else:
            user_prompt = '%s' % os.getenv('USER')

        if os.getenv('USER') == 'root':
            bgcolor = Color.USERNAME_ROOT_BG
        else:
            bgcolor = Color.USERNAME_BG

        powerline.append(user_prompt, Color.USERNAME_FG, bgcolor, '')
# }}}
# add_hostname_segment(powerline){{{
def add_hostname_segment(powerline):
    import os
    if os.getenv('SSH_CLIENT'):
        if powerline.shell == 'bash':
            host_prompt = '\\h '
        elif powerline.shell == 'zsh':
            host_prompt = '%m '
        else:
            import socket
            host_prompt = '%s ' % socket.gethostname().split('.')[0]

        powerline.append('@', Color.HOSTNAME_FG, Color.HOSTNAME_BG, '')
        powerline.append(host_prompt, Color.HOSTNAME_FG, Color.HOSTNAME_BG, '')
# }}}
# add_cwd_segment(powerline) {{{
import os

ELLIPSIS = '..'


def replace_home_dir(cwd):
    home = os.getenv('HOME')
    if cwd.startswith(home):
        return '~' + cwd[len(home):]
    return cwd


def split_path_into_names(cwd):
    names = cwd.split(os.sep)

    if names[0] == '':
        names = names[1:]
        # names[0] = '/' + names[0]
            
    if not names[0]:
        return ['/']

    return names


def maybe_shorten_name(powerline, name):
    """If the user has asked for each directory name to be shortened, will
    return the name up to their specified length. Otherwise returns the full
    name."""
    if powerline.cwd_max_dir_size:
        return name[:powerline.cwd_max_dir_size]
    return name


def add_cwd_segment(powerline):
    cwd = get_valid_cwd() or os.getenv('PWD')
    if not py3:
        cwd = cwd.decode("utf-8")
    cwd = replace_home_dir(cwd)

    if powerline.cwd_mode == 'plain':
        powerline.append('%s' % (cwd,), Color.CWD_FG, Color.PATH_BG)
        return

    names = split_path_into_names(cwd)

    max_depth = powerline.cwd_max_depth
    if max_depth <= 0:
        warn("Ignoring --cwd-max-depth argument since it's not greater than 0")
    elif len(names)-1 > max_depth:
        # n_before = 2 if max_depth > 2 else max_depth - 1
        # names = names[:n_before] + [ELLIPSIS] + names[n_before - max_depth:]

        names = [ELLIPSIS] + names[-max_depth:]

    if (powerline.cwd_mode == 'dironly'):
        # The user has indicated they only want the current directory to be
        # displayed, so chop everything else off
        names = names[-1:]

    for i, name in enumerate(names):
        fg = Color.PATH_FG
        bg = Color.PATH_BG

        separator = powerline.separator_thin
        separator_fg = Color.SEPARATOR_THIN_FG

        if ( i == 0 and name != '~' and name != '/' and name != ELLIPSIS):
            powerline.append('', fg, bg, separator, separator_fg)

        is_last_dir = (i == len(names) - 1)
        if is_last_dir:
            separator = None
            separator_fg = None

        powerline.append('%s' % maybe_shorten_name(powerline, name), fg, bg,
                         separator, separator_fg)
# }}}
# add_git_segment(powerline){{{
import re
import subprocess
import os

def git_subprocess_env():
    return {
        # LANG is specified to ensure git always uses a language we are expecting.
        # Otherwise we may be unable to parse the output.
        "LANG": "C",
        "HOME": os.getenv("HOME"),
        "PATH": os.getenv("PATH"),
    }


def parse_git_branch_info(status):
    info = re.search('^## (?P<local>\S+?)''(\.{3}(?P<remote>\S+?)( \[(ahead (?P<ahead>\d+)(, )?)?(behind (?P<behind>\d+))?\])?)?$', status[0])
    return info.groupdict() if info else None


def _get_git_detached_branch():
    try:
        p = subprocess.Popen(['git', 'describe', '--tags', '--always'],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             env=git_subprocess_env())
    except OSError:
        # Popen will throw an OSError if git is not found
        return

    pdata = p.communicate()
    if p.returncode == 0:
        # detached_ref = pdata[0].decode("utf-8").rstrip('\n')
        # branch = u'{} {}'.format(RepoStats.symbols['detached'], detached_ref)
        branch = 'HEAD detached'
    else:
        branch = 'Big Bang'
    return branch


def parse_git_stats(status):
    stats = RepoStats()
    for statusline in status[1:]:
        code = statusline[:2]
        if code == '??':
            stats.untracked += 1
        elif code in ('DD', 'AU', 'UD', 'UA', 'DU', 'AA', 'UU'):
            stats.conflicted += 1
        else:
            if code[1] != ' ':
                stats.not_staged += 1
            if code[0] != ' ':
                stats.staged += 1

    return stats


def add_git_segment(powerline):
    try:
        p = subprocess.Popen(['git', 'status', '--porcelain', '-b'],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             env=git_subprocess_env())
    except OSError:
        # Popen will throw an OSError if git is not found
        return

    pdata = p.communicate()
    if p.returncode != 0:
        return

    status = pdata[0].decode("utf-8").splitlines()
    stats = parse_git_stats(status)
    branch_info = parse_git_branch_info(status)

    if branch_info:
        stats.ahead = branch_info["ahead"]
        stats.behind = branch_info["behind"]
        branch = branch_info['local']
    else:
        branch = _get_git_detached_branch()

    bg = Color.REPO_CLEAN_BG
    fg = Color.REPO_CLEAN_FG
    if stats.dirty:
        bg = Color.REPO_DIRTY_BG
        fg = Color.REPO_DIRTY_FG

    powerline.append('(%s' % branch, fg, bg,'')
    stats.add_to_powerline(powerline, Color)
    powerline.append(')', fg, bg)
# }}}
# add_hg_segment(powerline){{{
import os
import subprocess

def get_hg_status():
    has_modified_files = False
    has_untracked_files = False
    has_missing_files = False

    p = subprocess.Popen(['hg', 'status'], stdout=subprocess.PIPE)
    output = p.communicate()[0].decode("utf-8")

    for line in output.split('\n'):
        if line == '':
            continue
        elif line[0] == '?':
            has_untracked_files = True
        elif line[0] == '!':
            has_missing_files = True
        else:
            has_modified_files = True
    return has_modified_files, has_untracked_files, has_missing_files

def add_hg_segment(powerline):
    branch = os.popen('hg branch 2> /dev/null').read().rstrip()
    if len(branch) == 0:
        return False
    bg = Color.REPO_CLEAN_BG
    fg = Color.REPO_CLEAN_FG
    has_modified_files, has_untracked_files, has_missing_files = get_hg_status()
    if has_modified_files or has_untracked_files or has_missing_files:
        bg = Color.REPO_DIRTY_BG
        fg = Color.REPO_DIRTY_FG
        extra = ''
        if has_untracked_files:
            extra += '+'
        if has_missing_files:
            extra += '!'
        branch += (' ' + extra if extra != '' else '')
    return powerline.append(' %s ' % branch, fg, bg)
# }}}
# add_svn_segment(powerline){{{
import subprocess


def _add_svn_segment(powerline):
    is_svn = subprocess.Popen(['svn', 'status'],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    is_svn_output = is_svn.communicate()[1].decode("utf-8").strip()
    if len(is_svn_output) != 0:
        return

    #"svn status | grep -c "^[ACDIMRX\\!\\~]"
    p1 = subprocess.Popen(['svn', 'status'], stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
    p2 = subprocess.Popen(['grep', '-c', '^[ACDIMR\\!\\~]'],
            stdin=p1.stdout, stdout=subprocess.PIPE)
    output = p2.communicate()[0].decode("utf-8").strip()
    if len(output) > 0 and int(output) > 0:
        changes = output.strip()
        powerline.append(' %s ' % changes, Color.SVN_CHANGES_FG, Color.SVN_CHANGES_BG)


def add_svn_segment(powerline):
    """Wraps _add_svn_segment in exception handling."""

    # FIXME This function was added when introducing a testing framework,
    # during which the 'powerline' object was passed into the
    # `add_[segment]_segment` functions instead of being a global variable. At
    # that time it was unclear whether the below exceptions could actually be
    # thrown. It would be preferable to find out whether they ever will. If so,
    # write a comment explaining when. Otherwise remove.

    try:
        _add_svn_segment(powerline)
    except OSError:
        pass
    except subprocess.CalledProcessError:
        pass
# }}}
# add_fossil_segment(powerline){{{
import os
import subprocess

def get_fossil_status():
    has_modified_files = False
    has_untracked_files = False
    has_missing_files = False
    output = os.popen('fossil changes 2>/dev/null').read().strip()
    has_untracked_files = True if os.popen("fossil extras 2>/dev/null").read().strip() else False
    has_missing_files = 'MISSING' in output
    has_modified_files = 'EDITED' in output

    return has_modified_files, has_untracked_files, has_missing_files

def _add_fossil_segment(powerline):
    subprocess.Popen(['fossil'], stdout=subprocess.PIPE).communicate()[0]
    branch = ''.join([i.replace('*','').strip() for i in os.popen("fossil branch 2> /dev/null").read().strip().split("\n") if i.startswith('*')])
    if len(branch) == 0:
        return

    bg = Color.REPO_CLEAN_BG
    fg = Color.REPO_CLEAN_FG
    has_modified_files, has_untracked_files, has_missing_files = get_fossil_status()
    if has_modified_files or has_untracked_files or has_missing_files:
        bg = Color.REPO_DIRTY_BG
        fg = Color.REPO_DIRTY_FG
        extra = ''
        if has_untracked_files:
            extra += '+'
        if has_missing_files:
            extra += '!'
        branch += (' ' + extra if extra != '' else '')
    powerline.append(' %s ' % branch, fg, bg)

def add_fossil_segment(powerline):
    """Wraps _add_fossil_segment in exception handling."""

    # FIXME This function was added when introducing a testing framework,
    # during which the 'powerline' object was passed into the
    # `add_[segment]_segment` functions instead of being a global variable. At
    # that time it was unclear whether the below exceptions could actually be
    # thrown. It would be preferable to find out whether they ever will. If so,
    # write a comment explaining when. Otherwise remove.

    try:
        _add_fossil_segment(powerline)
    except OSError:
        pass
    except subprocess.CalledProcessError:
        pass
# }}}
# add_exit_code_segment(powerline) {{{
def add_exit_code_segment(powerline):
    if powerline.args.prev_error == 0:
        return
    fg = Color.CMD_FAILED_FG
    bg = Color.CMD_FAILED_BG
    powerline.append(' %s ' % str(powerline.args.prev_error), fg, bg)
# }}}
# add_root_segment(powerline){{{
def add_root_segment(powerline):
    root_indicators = {
        'bash': ' \\$ ',
        'zsh': '%#',
        'bare': ' $ ',
    }
    bg = Color.CMD_PASSED_BG
    fg = Color.CMD_PASSED_FG
    if powerline.args.prev_error != 0:
        fg = Color.CMD_FAILED_FG
        bg = Color.CMD_FAILED_BG
    powerline.append(root_indicators[powerline.shell], fg, bg,'')
# }}}
# add_end_wrap(powerline){{{
def add_end_wrap(powerline):
    bg = Color.CMD_PASSED_BG
    fg = Color.CMD_PASSED_FG
    powerline.append(']', fg, bg,'')
# }}}

# Enable the features you want {{{
add_begin_wrap(powerline)
# add_virtual_env_segment(powerline)
# add_ssh_segment(powerline)
# add_read_only_segment(powerline)
# add_username_segment(powerline)
# add_hostname_segment(powerline)
add_cwd_segment(powerline)
add_git_segment(powerline)
# add_hg_segment(powerline)
# add_svn_segment(powerline)
# add_fossil_segment(powerline)
# add_exit_code_segment(powerline)
# add_root_segment(powerline)
add_end_wrap(powerline)
#}}}

sys.stdout.write(powerline.draw())

# vim: foldmethod=marker  foldlevelstart=0
