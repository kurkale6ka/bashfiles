txt_blk='\e[0;30m' # Black - Regular
txt_blu='\e[0;34m' # Blue
txt_cyn='\e[0;36m' # Cyan
txt_grn='\e[0;32m' # Green
txt_pur='\e[0;35m' # Purple
txt_red='\e[0;31m' # Red
txt_wht='\e[0;37m' # White
txt_ylw='\e[0;33m' # Yellow
#--------------------------------------
bld_blk='\e[1;30m' # Black - Bold
bld_blu='\e[1;34m' # Blue
bld_cyn='\e[1;36m' # Cyan
bld_grn='\e[1;32m' # Green
bld_pur='\e[1;35m' # Purple
bld_red='\e[1;31m' # Red
bld_wht='\e[1;37m' # White
bld_ylw='\e[1;33m' # Yellow
#--------------------------------------
und_blk='\e[4;30m' # Black - Underline
und_blu='\e[4;34m' # Blue
und_cyn='\e[4;36m' # Cyan
und_grn='\e[4;32m' # Green
und_pur='\e[4;35m' # Purple
und_red='\e[4;31m' # Red
und_wht='\e[4;37m' # White
und_ylw='\e[4;33m' # Yellow
#--------------------------------------
bak_blk='\e[40m'   # Black - Background
bak_blu='\e[44m'   # Blue
bak_cyn='\e[46m'   # Cyan
bak_grn='\e[42m'   # Green
bak_pur='\e[45m'   # Purple
bak_red='\e[41m'   # Red
bak_wht='\e[47m'   # White
bak_ylw='\e[43m'   # Yellow
#--------------------------------------
txt_rst='\e[0m'    # Text Reset

title="\e]0;\D{%e %B %Y}, bash $BASH_VERSION on $TERM, [\u@\H]\a"

clear

if [[ 0 == $UID ]]; then

    echo 'Hi root'
    PS1="$title\n$txt_red\D{%a} \A \w [!\! - %\j]\n# $txt_rst"
else
    echo 'Hi kurkale6ka'
    PS1="$title\n$txt_ylw\D{%a} \A $txt_pur\w $txt_red[!\! - %\j]$txt_rst\n\$ "
fi

function _exit()
{
    clear
    echo -e "${txt_red}Hasta la vista, baby${txt_rst}"
}
trap _exit EXIT

function extract()
{
    if [ -f $1 ]
    then
        case $1 in
            *.tar.gz|*.tgz)   tar zxvf   $1 ;;
            *.tar.bz2|*.tbz2) tar jxvf   $1 ;;
            *.tar)            tar xvf    $1 ;;
            *.bz2)            bunzip2    $1 ;;
            *.gz)             gunzip     $1 ;;
            *.zip)            unzip      $1 ;;
            *.rar)            unrar x    $1 ;;
            *.Z)              uncompress $1 ;;
            *.7z)             7z x       $1 ;;
            *)                echo "'$1' cannot be extracted via extract" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

function bak()
{
    mv $1 $1.bak
}

function x()
{
    if [[ $- == *x* ]]; then

        echo 'debug off'
        set +o xtrace
    else
        echo 'debug on'
        set -o xtrace
    fi
}

function swap()
{
    local tmpfile=tmp.$$

    [ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
    [ !  -e $1 ] && echo "swap: $1 does not exist"  && return 1
    [ !  -e $2 ] && echo "swap: $2 does not exist"  && return 1

    mv $1 $tmpfile
    mv $2 $1
    mv $tmpfile $2
}

# Vim
#my_vim=vimx
my_vim='gvim -v'
alias       v="$my_vim"
alias      vi="$my_vim"
alias     vim="$my_vim"
alias    view="$my_vim -R"
alias vimdiff="$my_vim -d"
alias      gv=gvim
alias     gvi=gvim

# Change/print directory
alias    .='pwd'
alias  cd-='cd -'
alias -- -='cd -'
alias    1='cd ..'
alias    2='cd ../..'
alias    3='cd ../../..'
alias    4='cd ../../../..'
alias cd..='cd ..'
alias   ..='cd ..'
alias  ...='cd ../..'

# "-p" lets you create a path structure with one command, ex. mkdir -p /a/b/c
alias md='mkdir -p'
alias rd='rmdir'

# Misc
alias a=awk
alias c=cat
alias e=echo
alias f='find . -name $*'
alias h=history
alias j='jobs -l'
alias k=kill
alias m=man
alias o='set -o'
alias p='ps -aux'
alias t=extract
alias z=fg

alias  more='vi -'
alias set-o='set -o'
alias    so=source

# List directory
options='--color=auto --dereference-command-line-symlink-to-dir'
alias   l="ls -F          $options"
alias  ls="ls -F          $options"
alias  ll="ls -Fl         $options"
alias  l.="ls -Fd  .[^.]* $options"
alias ll.="ls -Fdl .[^.]* $options"
alias  la="ls -FA         $options"
alias lla="ls -FAl        $options"
alias  lr="ls -FR         $options"
alias  lv='ls|vi -'

alias df='df -h'
alias du='du -h'

alias    g='grep --color'
alias grep='grep --color'

alias     ?='type -a'
alias which='type -a'

alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias  alais=alias
alias   bnid=bind
alias    cta=cat
alias   ehco=echo
alias exprot=export
alias   hlep=help
alias    mna=man
alias   mroe=more
alias   gerp=grep
alias   klil=kill
alias  gveiw=gview
alias   gvmi=gvim
alias   veiw=view
alias    vmi=vim
alias    akw=awk
alias    sde=sed
alias   prel=perl
alias pyhton=python
alias   rbuy=ruby
alias    pph=php
alias    bka=bak
alias   sawp=swap

# Vars
export CDPATH='~:..:../..:'
export EDITOR=$my_vim
export GIT_PROXY_COMMAND=~/.ssh/proxy_cmd_for_github
export HISTIGNORE='&:.:..:...:-:[bf]g:c:cd:cd-:cd..:d[fu]:h:j:l:l[.alrsv]:ll[.a]:o:p:pwd:v:vi:vim:vmi:gv:gvi:gvim:gvmi:z:x'

shopt -s cdspell
shopt -s extglob

set -o notify # about terminated jobs

complete -A hostname rsh rcp telnet rlogin r ftp ping disk ssh
complete -A export   printenv
complete -A variable export local readonly unset
complete -A enabled  builtin
complete -A alias    alias unalias
complete -A function function
complete -A user     su mail finger

complete -A helptopic      help # Currently, same as builtins.
complete -A shopt          shopt
complete -A stopped -P '%' bg
complete -A job -P '%'     fg jobs disown

complete -A directory            mkdir rmdir
complete -A directory -o default cd

# Compression
complete -f -o default -X '!*.+(zip|ZIP|z|Z|gz|GZ|bz2|BZ2)' extract t

complete -f -o default -X '!*.pl'  perl
complete -f -o default -X '!*.php' php
complete -f -o default -X '!*.py'  python
complete -f -o default -X '!*.rb'  ruby
