[[ -t 1 ]] || return

set -o notify
shopt -s cdspell extglob nocaseglob nocasematch histappend

HISTFILESIZE=11000
HISTSIZE=11000 # size allowed in memory
HISTCONTROL=ignorespace:ignoredups:erasedups
HISTIGNORE="@(?|??|???)*( |$'\t'):*( |$'\t')"
# HISTIGNORE='@(?|??|???)*([[:space:]]):*([[:space:]])'
HISTTIMEFORMAT='<%d %b %H:%M>  '

FIGNORE='~:.swp:.o' # <tab> completion
# Equivalents:
#    * ls -B to ignore backup files (~) in listings
#    * :set wildignore+=*~,*.swp in Vim

HOSTFILE="$HOME"/.hosts # hostnames completion (same format as /etc/hosts)

## Colors
# These can't reside in .profile since there is no terminal for tput
     Bold="$(tput bold)"
Underline="$(tput smul)"
   Purple="$(tput setaf 140)"
   Yellow="$(tput setaf 221)"
    Green="$(tput setaf 2)"
     Blue="$(tput setaf 4)"
      Red="$(tput setaf 1)"
     RRed="$(tput setaf 9)"
   LGreen="$(printf %s "$Bold"; tput setaf 2)"
    LBlue="$(printf %s "$Bold"; tput setaf 4)"
     LRed="$(printf %s "$Bold"; tput setaf 1)"
    LCyan="$(printf %s "$Bold"; tput setaf 6)"
    Reset="$(tput sgr0)"

# Colored man pages
export LESS_TERMCAP_mb="$LGreen" # begin blinking
export LESS_TERMCAP_md="$LBlue"  # begin bold
export LESS_TERMCAP_me="$Reset"  # end mode

# so -> stand out - info box
export LESS_TERMCAP_so="$(printf %s "$Bold"; tput setaf 3; tput setab 4)"
# se -> stand out end
export LESS_TERMCAP_se="$(tput rmso; printf %s "$Reset")"

# us -> underline start
export LESS_TERMCAP_us="$(printf %s%s "$Bold$Underline"; tput setaf 5)"
# ue -> underline end
export LESS_TERMCAP_ue="$(tput rmul; printf %s "$Reset")"

[[ -r $HOME/.dir_colors ]] && eval "$(dircolors "$HOME"/.dir_colors)"

## Vim
if command -v nvim
then
   alias v=nvim
else
   alias v='vim -u ~/.vimrc'
fi >/dev/null 2>&1

alias ed='ed -v -p:'

## sudo
alias  sd=sudo
alias sde=sudoedit

## PS1 + title (\e]2; ---- \a)
_gbr() {
   local gb="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
   if [[ $gb ]]
   then echo " λ-$gb"
   else echo ''
   fi
}

# Helper for c (fuzzy bookmarked cd)

# mkdir -p $XDG_DATA_HOME/bmarks
#
# sqlite3 $XDG_DATA_HOME/bmarks/marks.sqlite << 'INIT'
# CREATE TABLE marks (
#   dir VARCHAR(200) UNIQUE,
#   weight INTEGER
# );
#
# CREATE INDEX _dir ON marks (dir);
# INIT
update_marks() {
   local db="$XDG_DATA_HOME"/bmarks/marks.sqlite

   # Get weight for the current directory
   local weight="$(sqlite3 "$db" "SELECT weight FROM marks WHERE dir = '$(pwd -P)';")"

   if [[ $weight ]]
   then
      ((weight++))
   else
      weight=1
   fi

   sqlite3 "$db" "INSERT or REPLACE into marks (dir, weight) values ('$(pwd -P)', '$weight');"
}

# Fuzzy cd based on visited locations only (bookmarks)
c() {
   local db="$XDG_DATA_HOME"/bmarks/marks.sqlite

   # Statistics
   if [[ $1 == -s ]]
   then
      sqlite3 "$db" 'SELECT * FROM marks ORDER BY weight DESC;' | column -t -s'|' | less
      return 0
   fi

   if (($# > 0))
   then
      # Note: for more than 2 arguments, not all permutations are tried.
      # So for c 1 2 3, %1%2%3% and %3%2%1% are only tried.
      local _dirs
      printf -v _dirs '%s%%' "$@"
      # dir="$(sqlite3 "$db" "SELECT dir FROM marks WHERE dir LIKE '%${_dirs%\%}%' or dir LIKE '%${(j.%.)${(aO)@}}%' ORDER BY weight DESC;" | fzf +s -0 -1)"
      local dir="$(sqlite3 "$db" "SELECT dir FROM marks WHERE dir LIKE '%${_dirs%\%}%' ORDER BY weight DESC;" | fzf +s -0 -1)"
   else
      local dir="$(sqlite3 "$db" "SELECT dir FROM marks ORDER BY weight DESC;" | fzf +s -0 -1)"
   fi

   if [[ $dir ]]
   then
      cd -- "$dir"
   fi
}

PS1() {
   if ((EUID == 0)); then
      # Add root's PATH because I am simply running a root bash, so haven't
      # sourced any of root's files (as it happens with su - root)
      PATH=/sbin:/usr/sbin:/usr/local/sbin:/root/bin:"$PATH"
      # Use PROMPT_COMMAND to aggregate users' history into a single file
      # /var/log/user-history.log                                    whoami | bash PID |         history 1        |  $?
      #                                                              oge    | [21118]: | 2013-09-09_10:46:34 su - | [1]
      # export PROMPT_COMMAND='RETRN_VAL=$?; logger -p local6.debug "$LOGNAME [$$]: $(history 1 | command sed "s/^[ ]*[0-9]\+[ ]*//" ) [$RETRN_VAL]"; ...'
      [[ $TERM != linux ]] && export PROMPT_COMMAND='printf "\e]2;%s @ %s # %s\a" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
      if [[ $SSH_CONNECTION ]]
      then
         PS1="\n[\[$LBlue\]\w\[$Reset\]]\$(_gbr) \[$Purple\]\h\[$Reset\] \A"'$(((\j>0)) && echo \ ❭ \[$RRed\]%\j\[$Reset\])'"\n\[$RRed\]\u\[$Reset\] # "
      else
         PS1="\n[\[$LBlue\]\w\[$Reset\]]\$(_gbr) \[$Yellow\]\h\[$Reset\] \A"'$(((\j>0)) && echo \ ❭ \[$RRed\]%\j\[$Reset\])'"\n\[$RRed\]\u\[$Reset\] # "
      fi
   else
      [[ $TERM != linux ]] && export PROMPT_COMMAND='printf "\e]2;%s @ %s $ %s\a" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
      if [[ $SSH_CONNECTION ]]
      then
         PS1="\n[\[$LBlue\]\w\[$Reset\]]\$(_gbr) \[$Purple\]\h\[$Reset\] \A"'$(((\j>0)) && echo \ ❭ \[$RRed\]%\j\[$Reset\])'"\n\[$Yellow\]\u\[$Reset\] \\$ "
      else
         PS1="\n[\[$LBlue\]\w\[$Reset\]]\$(_gbr) \[$Yellow\]\h\[$Reset\] \A"'$(((\j>0)) && echo \ ❭ \[$RRed\]%\j\[$Reset\])'"\n\[$Yellow\]\u\[$Reset\] \\$ "
      fi
   fi
}

       PS1 # call function above
       PS2='↪ '
export PS3='Choose an entry: '
       PS4='+ '

## Directory functions and aliases: cd, md, rd, pw
if [[ -r $HOME/github/bash/scripts/cd/cd.bash ]]
then
   . "$HOME"/github/bash/scripts/cd/cd.bash
   cd_alias=c
fi

alias  cd-="${cd_alias:-cd} - >/dev/null"
alias -- -="${cd_alias:-cd} - >/dev/null"
alias    1="${cd_alias:-cd} .."
alias    2="${cd_alias:-cd} ../.."
alias    3="${cd_alias:-cd} ../../.."
alias    4="${cd_alias:-cd} ../../../.."
alias cd..="${cd_alias:-cd} .."
alias   ..="${cd_alias:-cd} .."

alias to=touch
alias md='command mkdir -p --'

rd() {
   printf 'rd: remove directory ‘%s’?\n' "$@"
   read -p '(y/n) '
   [[ $REPLY == @(y|yes) ]] && command rm -r -- "$@"
}

complete -A directory mkdir md rmdir rd

pw() {
   if (($#))
   then pws --seconds 25 get "$1"
   else command pwd -P
   fi
}

## Fuzzy
fd() {
   local dir

   if [[ $1 ]]
   then
      # if a path contains /., that's a folder staring with dot
      dir="$(find "${1}" \( -type d -path '*/\.*' -prune \) -o -type d -print | fzf -0 +m)"
   else
      dir="$(find . \( -type d -path '*/\.*' -prune \) -o -type d -printf '%P\n' | tail -n+2 | fzf -0 +m)"
   fi

   [[ -d $dir ]] && cd "$dir"
}

fda() {
   local dir

   if [[ $1 ]]
   then
      # Todo: exclude more directories (.svn, ...)
      dir="$(find "${1}" \( -type d -path '*/\.git*' -prune \) -o -type d -print | fzf -0 +m)"
   else
      dir="$(find . \( -type d -path '*/\.git*' -prune \) -o -type d -printf '%P\n' | tail -n+2 | fzf -0 +m)"
   fi

   [[ -d $dir ]] && cd "$dir"
}

## Networking: myip, dig, tunnel
alias myip='curl icanhazip.com'

dig() { command dig +noall +answer "${@#*//}"; }
dg() { dig -x $(dig +noall +answer +short "${@#*//}"); }

# Tunnel host's port to the local port
tunnel() {
   # Help
   if [[ $1 == -@(h|-h)* ]] || (($# == 0))
   then
      local info='Usage: tunnel {host} [{remote port: 80} {local port: 8080}]'
      if (($#))
      then echo "$info"    ; return 0
      else echo "$info" >&2; return 1
      fi
   fi

   if (($# == 1))
   then
      ssh -fNL "${3:-8080}":localhost:"${2:-80}" "$1" &&
      xdg-open http://localhost:"${3:-8080}" 2>/dev/null
   else
      ssh -fNL "${3:-$2}":localhost:"$2" "$1" &&
      xdg-open http://localhost:"${3:-$2}" 2>/dev/null
   fi
}

# Security
alias il='iptables -nvL --line-numbers'
alias nn=netstat

## Processes and jobs
# memory map
pm() {
   for i in "$@"; do
      printf '%s: ' "$i"; pmap -d "$(command pgrep "$i")" | tail -n1
   done | column -t | sort -k4
}

pg() {
   (($# == 0)) || [[ $1 == -h || $1 == --help ]] && {
      cat <<- HELP
		Usage:
		  pg [-lz] pattern
		    -l: PID PPID PGID SID TTY TPGID STAT EUSER EGROUP START CMD
		    -z: squeeze! no context lines.
		HELP
      return 0
   }

   [[ $1 == -* ]] && { [[ $1 == @(-l|-z|-lz|-zl) ]] || return 1; }

   # fields
   if [[ $1 != -*l* ]]
   then
      # PID STAT EUSER EGROUP START CMD
      local fields=pid,stat,euser,egroup,start_time,cmd
   else
      local fields=pid,ppid,pgid,sid,tname,tpgid,stat,euser,egroup,start_time,cmd
   fi

   # Display headers:
   ps o "$fields" | head -n1

   # Squeeze! No context lines
   if [[ $1 == -*z* ]]
   then
      ps  axww o "$fields" | grep -v grep | grep -iE   --color=auto "${@:2}"
   elif [[ $1 == -* ]]; then
      ps faxww o "$fields" | grep -v grep | grep -iEB1 --color=auto "${@:2}"
   else
      ps faxww o "$fields" | grep -v grep | grep -iEB1 --color=auto "$@"
   fi
}

alias  k=kill
alias kl='kill -l'
alias ka=killall
alias kg='kill -- -'
alias pk=pkill
complete -A signal kill k

# jobs
alias     j='jobs -l'
alias     z=fg
alias -- --='fg %-'
complete -A job     -P '%' fg z jobs j disown
complete -A stopped -P '%' bg

## rsync with git excludes
rs() {
rsync -f".- $HOME/.gitignore" \
      -f':- .gitignore'       \
      -f'- .git'              \
      "$@"
}

## Permissions + debug
x() {
   (($#)) && { chmod u+x -- "$@"; return; }

   if [[ $- == *x* ]]
   then echo 'debug OFF'; set +o xtrace
   else echo 'debug ON' ; set -o xtrace
   fi
} 2>/dev/null

alias bx='bash -x'

alias    setuid='chmod u+s'
alias    setgid='chmod g+s'
alias setsticky='chmod  +t'

alias cg=chgrp
alias co=chown
alias cm=chmod

## ls
ldot() {
   local ls
   if [[ ${FUNCNAME[1]} == 'l.' ]]
   then ls=(ls -FB   --color=auto)
   else ls=(ls -FBhl --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M")
   fi
   (($# == 0)) && {             "${ls[@]}" -d .[^.]* ; return; }
   (($# == 1)) && { (cd "$1" && "${ls[@]}" -d .[^.]*); return; }
   local i arg
   for arg in "$@"; do
      printf '%s:\n' "$arg"
      (cd -- "$arg" && "${ls[@]}" -d .[^.]*)
      (($# != ++i)) && echo
   done
}

.() {
   if (($#))
   then source "$@"
   else command ls -FB --color=auto -d .[^.]*
   fi
}

unalias l. ll. l ld la lr lk lx ll lld lla llr llk llx lm lc lu llm llc llu ln \
   2>/dev/null

 l.() { ldot "$@"; }
ll.() { ldot "$@"; }

alias   l='command ls -FB    --color=auto'
alias  ll='command ls -FBhl  --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M"'
alias  l1='command ls -FB1   --color=auto'

alias  la='command ls -FBA   --color=auto'
alias lla='command ls -FBAhl --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M"'

alias  ld='command ls -FBd   --color=auto'
alias lld='command ls -FBdhl --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M"'

alias  lk='command ls -FBS   --color=auto'
alias llk='command ls -FBShl --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M"'

alias  lr="tree -FAC -I '*~|*.swp' --noreport"
alias llr='command ls -FBRhl --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M"'

lm() {
   [[ -t 1 ]] && echo "$Purple${Underline}Sorted by modification date:$Reset"
   command ls -FBtr --color=auto "$@"
}

llm() {
   [[ -t 1 ]] && echo "$Purple${Underline}Sorted by modification date:$Reset"
   command ls -FBhltr --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M" "$@"
}

_lx() {
   local exes=()
   for x in *; do [[ -x $x ]] && exes+=("$x"); done
   if [[ ${FUNCNAME[1]} == 'lx' ]]; then
      command ls -FB   --color=auto                                    "${exes[@]}"
   else
      command ls -FBhl --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M" "${exes[@]}"
   fi
}

 lx() { _lx "$@"; }
llx() { _lx "$@"; }

ln() {
   if (($#)); then
      command ln "$@"
   else
      if (( $(find . -maxdepth 1 -type l -print -quit | wc -l) == 1 )); then
         find . -maxdepth 1 -type l -printf '%P\0' |
         xargs -0 'ls' -FBAhl --color=auto --time-style="+${Blue}@$Reset %d-%b-%y %H:%M" --
      fi
   fi
}

sl() {
   printf '%-8s %-17s %-3s %-4s %-4s %-10s %-12s %-s\n'\
          'Inode' 'Permissions' 'ln' 'UID' 'GID' 'Size' 'Time' 'Name'
   local args=(); (($#)) && args=("$@") || args=(*)
   stat -c "%8i %A (%4a) %3h %4u %4g %10s (%10Y) %n" -- "${args[@]}"
}

## Help
m() {
   local choice
   (($#)) || {
      select choice in help man; do
         case "$choice" in
            help) help help; return;;
             man) man  man ; return;;
               *) echo '*** Wrong choice ***' >&2
         esac
      done
   }
   (($# >= 2)) && [[ -f $1 ]] && { command mv -i -- "$@"; return; }
   local topic arg
   for topic in "$@"; do
      ((arg++))
      [[ $topic == [1-8]* ]] && { man "$topic" -- "${@:$((arg+1))}"; return; }
      if [[ $(type -at -- $topic 2>/dev/null) == builtin*file ]]; then
         select choice in "help $topic" "man $topic"; do
            case "$choice" in
               help*) help -- "$topic"; break;;
                man*) man  -- "$topic"; break;;
                   *) echo '*** Wrong choice ***' >&2
            esac
         done
      else
         { help -- "$topic" || man -- "$topic" || type -a -- "$topic"; } 2>/dev/null
      fi
   done
}

alias mm='man -k'

mg() { man git-"${1:-help}"; }

# Search for help topics in my personal documentation
doc() {

   case "$1" in
      rg|regex)
         cat /home/mitko/github/help/regex.txt
         return ;;

      pf|printf)
         /home/mitko/github/help/printf.sh
         return ;;

      sort)
         cat /home/mitko/github/help/sort.txt
         return ;;
   esac

   local matches=()
   while read -r
   do
      matches+=("$REPLY")
   done < <(ag -lS --ignore '*install*' --ignore '*readme*' --ignore '*license*' "$1" "$HOME"/help/it)

   # For a single match, open the help file
   if (( ${#matches[@]} == 1 ))
   then
      command nvim -u "$HOME"/.vimrc "${matches[@]}" -c"0/$1" -c'noh|norm zv<cr>'
   elif (( ${#matches[@]} > 1 ))
   then
      ag -S --color-line-number="00;32" --color-path="00;35" --color-match="01;31" \
         "$1" "${matches[@]}"
   fi
}

alias rg="cat $HOME/github/help/regex.txt" # Regex  help
alias pf="$HOME/github/help/printf.sh"     # printf help

complete -A helptopic help m # Currently, same as builtin
complete -A command   man m which whereis type ? tpye sudo

# which-like function
_type() {
   (($#)) || { type -a -- "$FUNCNAME"; return; }

   echo "${Bold}type -a (exe, alias, builtin, func):$Reset"
   type -a -- "$@" 2>/dev/null
   echo

   echo "${Bold}whereis -b (bin):$Reset"
   whereis -b "$@"
   echo

   echo "${Bold}file -L (deref):$Reset"
   local f
   for f in "$@"
   do
      file -L "$(type -P -- "$f")"
   done
}

alias ?=_type

## Display /etc/passwd, ..group and ..shadow with some formatting
db() {
   local options[0]='/etc/passwd'
         options[1]='/etc/group'
         options[2]='/etc/shadow'

   select choice in "${options[@]}"; do

      case "$choice" in

         "${options[0]}")
            header=LOGIN:PASSWORD:UID:GID:GECOS:HOME:SHELL
            sort -k7 -t: /etc/passwd | command sed -e "1i$header" -e 's/::/:-:/g' |\
               column -ts:
            break;;

         "${options[1]}")
            header=GROUP:PASSWORD:GID:USERS
            sort -k4 -t: /etc/group | command sed "1i$header" | column -ts:
            break;;

         "${options[2]}")
            header=LOGIN:PASSWORD:LAST:MIN:MAX:WARN:INACTIVITY:EXPIRATION:RESERVED
            sudo sort -k2 -t: /etc/shadow |\
               awk -F: '{print $1":"substr($2,1,3)":"$3":"$4":"$5":"$6":"$7":"$8":"$9}' |\
               command sed -e "1i$header" -e 's/::/:-:/g' | column -ts:
            break;;
      esac
      echo '*** Wrong choice ***'
   done
}

## rm and cp like functions and aliases
# Delete based on inodes (use ls -li first)
di() {
   (($#)) || return 1
   local inode inodes=()
   # skip the last inode
   for inode in "${@:1:$#-1}"; do
      inodes+=(-inum "$inode" -o)
   done
   # last inode
   inodes+=(-inum "${@:$#}")
   # -inum 38 -o -inum 73
   find . \( "${inodes[@]}" \) -exec rm -i -- {} +
}

alias y='cp -i --'
alias d='rm -i --preserve-root --'

## Find stuff and diffs
f() {
   if (($# == 1))
   then
      find . -name .git -prune -o -iname "*$2*" -printf '%M %u %g %P\n' | grep -vE '~$'
   else
      find "$@"
   fi
}

alias lo='command locate -i'
alias ldapsearch='ldapsearch -x -LLL'

# Grep or silver searcher aliases
if command -v ag >/dev/null 2>&1; then
   alias g='ag -S --color-line-number="00;32" --color-path="00;35" --color-match="01;31"'
   alias gr='ag -S --color-line-number="00;32" --color-path="00;35" --color-match="01;31"'
   alias ag='ag -S --color-line-number="00;32" --color-path="00;35" --color-match="01;31"'
else
   alias g='command grep -iE --color=auto --exclude="*~" --exclude tags'
   alias gr='command grep -IriE --color=auto --exclude="*~" --exclude tags'
fi

diff() {
   if [[ -t 1 ]] && command -v colordiff >/dev/null 2>&1
   then         colordiff "$@"
   else command      diff "$@"
   fi
}

alias _=combine

## Convert to dec, bin, oct, hex
cv() {
   (($#)) || { echo 'Usage: cv digit ...' >&2; return 1; }
   cvs[0]='Decimal to binary'
   cvs[1]='Decimal to octal'
   cvs[2]='Decimal to hexadecimal'
   cvs[3]='Binary to decimal'
   cvs[4]='Octal to decimal'
   cvs[5]='Hexadecimal to decimal'
   local cv PS3='.? '
   select cv in "${cvs[@]}"; do
      case "$cv" in
         "${cvs[0]}")
            while read -r; do
               printf '%d -> %d\n' "$1" "$REPLY"; shift
            done < <(IFS=';'; command bc -q <<< "obase=2; $*") |\
            command sed '1iDec -> Bin' | column -t
            break;;
         "${cvs[1]}")
            while (($#)); do printf '%d -> %o\n' "$1" "$1"; shift; done |\
            command sed '1iDec -> Oct' | column -t
            break;;
         "${cvs[2]}")
            while (($#)); do printf '%d -> %x\n' "$1" "$1"; shift; done |\
            command sed '1iDec -> Hex' | column -t
            break;;
         "${cvs[3]}")
            while (($#)); do printf '%d -> %d\n' "$1" "$((2#$1))"; shift; done |\
            command sed '1iBin -> Dec' | column -t
            break;;
         "${cvs[4]}")
            while (($#)); do printf '%d -> %d\n' "$1" "$((8#$1))"; shift; done |\
            command sed '1iOct -> Dec' | column -t
            break;;
         "${cvs[5]}")
            while (($#)); do printf '%s -> %d\n' "$1" "$((16#$1))"; shift; done |\
            command sed '1iHex -> Dec' | column -t
            break;;
                   *) printf '\nInvalid choice!\n' >&2
      esac
   done
}

## Date and calendar
date() {
   if (($#))
   then command date "$@"
   else command date '+%A %d %B %Y, %H:%M %Z (%d/%m/%Y)'
   fi
}

if command -v ncal >/dev/null 2>&1; then
   alias  cal='env LC_TIME=bg_BG.utf8 ncal -3 -M -C'
   alias call='env LC_TIME=bg_BG.utf8 ncal -y -M -C'
else
   alias  cal='env LC_TIME=bg_BG.utf8 cal -m3'
   alias call='env LC_TIME=bg_BG.utf8 cal -my'
fi

## uname + os
u() {
   uname -r
   echo "$(uname -mpi) (machine, proc, platform)"
}

alias os='tail -n99 /etc/*{release,version} 2>/dev/null | cat -s'

## Backup functions and aliases
b() {
   (($#)) || { echo 'Usage: bak {file} ...' 1>&2; return 1; }
   local arg
   for arg in "$@"
   do
      command cp -i -- "$arg" "$arg".bak
   done
}

# Usage: sw file [file.bak]. file.bak is assumed by default so it can be omitted
bs() {
   if [[ $1 == -@(h|-h)* ]] || (($# != 1 && $# != 2)); then
      info='Usage: sw file [file.bak]'
      if (($#))
      then echo "$info"    ; return 0
      else echo "$info" >&2; return 1
      fi
   fi
   file1="$1"
   if (($# == 1))
   then file2="$1".bak
   else file2="$2"
   fi
   if [[ -e $file1 && -e $file2 ]]
   then
      local tmpfile=$(mktemp)
      if [[ $tmpfile ]]
      then
         'mv' -- "$file1"   "$tmpfile" &&
         'mv' -- "$file2"   "$file1"   &&
         'mv' -- "$tmpfile" "$file2"
      fi
   else
      head -n2 "$file1" "$file2" # to get an error message
   fi
}

br() {
   if (($#))
   then
      find . \( -name '*~' -o -name '.*~' \) -a ! -name '*.un~' -delete
   else
      find . \( -name '*~' -o -name '.*~' \) -a ! -name '*.un~' -printf '%P\n'
   fi
}

alias dump='dump -u'

## Disk: df, du, hdparm, mount
df() { command df -hT "$@" | sort -k6r; }

# Display largest files/directories
# ds
# ds -[fdt]
ds() {
   [[ $1 == -h || $1 == --help ]] && {
      cat <<- HELP
		Usage:
		ds
		ds -[fdt] (files, directories, total)
		HELP
      return 0
   }

   # Files
   if (($# == 0)) || [[ -d $1 ]] || { [[ $1 == -f ]] && [[ -d $2 || -z $2 ]]; }
   then
      if [[ $1 != -f ]]
      then
         local start="${1:-.}"
      else
         local start="${2:-.}"
      fi

      local file
      local files=()
      while read -r _ file
      do
         files+=("$file")
      done < <(find "$start" -xdev \( -name .git -o -path '*vendor/bundle' -o -path '*shared/bundle' \) -prune -o -type f -printf '%p\0' | xargs -0 du -h | sort -hr | head -n15)

      if [[ -n $files ]]
      then
         ls -FBShl --color --time-style='+%d-%b-%y %H:%M' -- "${files[@]#./}" | tee /tmp/ds_files
      else
         return 1
      fi
   fi

   # Directories
   if (($# == 0)) || [[ -d $1 ]] || { [[ $1 == -d ]] && [[ -d $2 || -z $2 ]]; }
   then
      if [[ $1 != -d ]]
      then
         local start="${1:-.}"
      else
         local start="${2:-.}"
      fi

      { (($# == 0)) || [[ -d $1 ]]; } && echo

      local size folder
      while read -r size folder
      do
         echo -n "$size "
         ls -d --color -- "${folder#./}"
      done < <(du -xh "$start" | sort -hr | head -n15) | tee /tmp/ds_dirs
   fi

   # Folder total
   if [[ $1 == -t ]] && [[ -d $2 || -z $2 ]]
   then
      du -sxh --time --time-style=+'%d-%b-%y %H:%M' "${2:-.}"
   fi
}

hd() { if ((1 == $#)); then hdparm -I -- "$1"; else hdparm "$@"; fi; }

mn() {
   if (($#))
   then command mount "$@"
   else command mount | cut -d" " -f1,3,5,6 | column -t
   fi
}

alias umn=umount
alias fu='sudo fuser -mv'

## Misc: options, app aliases, rc(), b(), e()
# Options
alias  a=alias
alias ua=unalias

complete -A alias alias a unalias ua

alias  o='set -o'
alias oo=shopt

complete -A setopt set   o
complete -A shopt  shopt oo

# Application aliases
alias open=xdg-open
alias weechat='TERM=xterm-256color weechat'
alias wgetpaste='wgetpaste -s dpaste -n kurkale6ka -Ct'
alias parallel='parallel --no-notice'
alias bc='bc -ql'

# More aliases
alias msg=dmesg
alias cmd=command
alias builtins='enable -a | cut -d" " -f2  | column'
alias hg='history | command grep -iE --color=auto'

alias pl=perl
alias py=python
alias rb=irb

complete -f -o default -X '!*.pl' perl   prel pl
complete -f -o default -X '!*.py' python py
complete -f -o default -X '!*.rb' ruby   rb

# rbenv: run multiple versions of ruby side-by-side
command -v rbenv >/dev/null 2>&1 && eval "$(rbenv init -)"

# Helper for creating a minimal .inputrc file
rc() {
   local inputrc="printf '%s\n' "
         inputrc+="'\"\e[A\": history-search-backward' "
         inputrc+="'\"\e[B\": history-search-forward' >> $HOME/.inputrc"
   xclip -f <<< "$inputrc"
}

# Banners using figlet
bn() {
   if   (($# == 1)); then figlet -f smslant -- "$1"
   elif (($# == 2)); then figlet -f "$1"    -- "${@:2}"
   else                   figlist | column -c"$COLUMNS"
   fi
}

# Echo
e() { local status=$?; (($#)) && echo "$@" || echo "$status"; }

## Head/tail + cat-like functions
h() { if (($#)) || [[ ! -t 0 ]]; then head "$@"; else history; fi; }

alias t=tail
alias tf='tail -f -n0'

# Display the first 98 lines of all (or filtered) files in . Ex: catall .ba
catall() {
   (($#)) && local filter=(-iname "$1*")
   find . -maxdepth 1 "${filter[@]}" ! -name '*~' -type f -print0 |
   xargs -0 file | grep text | cut -d: -f1 | cut -c3- | xargs head -n98 |
   command $nvim -u "$HOME"/.vimrc -c "se fdl=0 fdm=expr fde=getline(v\:lnum)=~'==>'?'>1'\:'='" -
}

cn() { if [[ -t 1 ]]; then command cat -n -- "$@"; else command cat "$@"; fi; }

# Print nth line in a file: n 11 /my/file
n() { command sed -n "$1{p;q}" -- "$2"; }

# Display non-empty lines in a file
sq() { command grep -v '^[[:space:]]*#\|^[[:space:]]*$' -- "$@"; }

if [[ $(uname) == Darwin ]]
then
   PATH=/usr/local/bin:"$PATH"
   PATH="$(brew --prefix coreutils)"/libexec/gnubin:"$PATH"

   MANPATH="$(brew --prefix coreutils)"{/libexec/gnuman,/share/man}:"$MANPATH"
   for pkg in ed findutils ag ctags tree gnu-sed homebrew/dupes/grep vim
   do
      MANPATH="$(brew --prefix $pkg)"/share/man:"$MANPATH"
   done
fi

# Cleaner PATH display
pa() { awk '!_[$0]++' <<< "${PATH//:/$'\n'}"; }

## Git
alias gc='git commit -v'
alias gp='git push origin master'
alias gs='git status -sb'
alias go='git checkout'
alias gm='git checkout master'
alias ga='git add'
alias gb='git branch'
alias gd='git diff --word-diff=color'
alias gf='git fetch'
alias gl='git log --oneline --decorate'
alias gll='git log -U1 --word-diff=color' # -U1: 1 line of context (-p implied)

gsa() (
   for repo in bash config help scripts vim
   do
      cd "$HOME"/github/"$repo" && {
         echo "$Bold=== $repo ===$Reset"
         if (($#)) # fetch if branch ahead of remote
         then
            git fetch
         else
            git -c color.ui=false status -sb | head -n1
            git status -s
         fi
         [[ $repo != vim ]] && echo
      }
   done
)

## GitHub: open the repo corresponding to the current pwd in a browser
gh() {
   if [[ $1 == -@(h|-h)* ]]
   then
      echo 'Usage: gh [origin|-b|-i|-p|-c]'; return 0
   fi

   local origin
   [[ $1 != -* ]] && origin="$1"
   local remote=remote."${origin:-origin}".url

   local giturl="$(git config --get "$remote")"
   [[ $giturl ]] || {
      echo "Not a git repository or no $remote set"
      return 1
   }

   local user_tmp="${giturl%/*}"
   local user_tmp="${user_tmp##*/}"
   local user="${user_tmp#*:}"
   local repo="${giturl##*/}"
   giturl=https://github.com/"$user"/"$repo"

   local branch="$(git symbolic-ref HEAD 2>/dev/null)"
   [[ $branch ]] && branch="${branch#refs/heads/}" || branch=master

   local path
   case "$1" in
      -b) path=branches;;
      -i) path=issues;;
      -p) path=pulls;;
      -c) path=commits/"$branch";;
       *) path=tree/"$branch";;
   esac
   giturl="${giturl%.git}"/"$path"

   xdg-open "$giturl" 2>/dev/null
}

## Google search: gg term
urlencode() {
   local char
   local str="$*"
   for ((i = 0; i < ${#str}; i++)); do
      char="${str:i:1}"
      case "$char" in
         [a-zA-Z0-9.~_-]) printf "$char" ;;
                     ' ') printf + ;;
                       *) printf '%%%X' "'$char"
      esac
   done
}

gg() {
   sudo -umitko xdg-open https://www.google.co.uk/search?q="$(urlencode "$@")" >/dev/null 2>&1
}

## Typos
alias cta=cat
alias ecex=exec
alias akw=awk
alias rmp=rpm
alias shh=ssh
alias xlcip=xclip

## Programmable completion
complete -A enabled  builtin
complete -A disabled enable
complete -A export   printenv
complete -A variable export local readonly unset use
complete -A function function
complete -A binding  bind
complete -A user     chage chfn finger groups mail passwd slay su userdel \
                     usermod w write
complete -A hostname dig nslookup snlookup host p ping pnig ssh shh

# Usage: cl arg - computes a completion list for arg
cl() { column <(compgen -A "$1"); }

complete -W 'alias arrayvar binding builtin command directory disabled enabled
export file function group helptopic hostname job keyword running service
setopt shopt signal stopped user variable' cl compgen complete

# enable bash completion in non posix shells
if ! shopt -oq posix; then
   if [[ -f /etc/profile.d/bash-completion.sh ]]; then
      . /etc/profile.d/bash-completion.sh
   elif [[ -f /etc/bash_completion ]]; then
      . /etc/bash_completion
   fi >/dev/null 2>&1
fi

## tmux
alias tmux='tmux -2'
alias tm='tmux -2'
alias tl='tmux ls'
alias ta='tmux attach-session'
alias tn='tmux new -s'

complete -W '$(tmux ls 2>/dev/null | cut -d: -f1)' tmux
complete -W "$(screen -ls 2>/dev/null | grep -E '^\s+[0-9].*\.' | awk {print\ \$1})" screen

## fzf
[[ -f ~/.fzf.bash ]] && . ~/.fzf.bash

## Business specific or system dependant stuff
[[ -r $HOME/.bashrc_after ]] && . "$HOME"/.bashrc_after

# vim: fdm=expr fde=getline(v\:lnum)=~'^##'?'>'.(matchend(getline(v\:lnum),'###*')-1)\:'='
