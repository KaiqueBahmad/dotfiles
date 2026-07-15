# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias cpc="xclip -sel c < "
alias tocopy='xclip -selection clipboard'

alias claude20='ASDF_NODEJS_VERSION=20.18.0 claude'

alias docker-stop-all='docker stop $(docker ps -q)'
