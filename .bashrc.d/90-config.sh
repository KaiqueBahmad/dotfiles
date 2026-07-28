#. <(asdf completion bash)
# Iniciar agente SSH se não estiver rodando
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
	eval "$(ssh-agent -s)"
fi


short_pwd() {
  local path="${PWD/#$HOME/\~}"
  local IFS='/'
  read -ra parts <<< "$path"
  local len=${#parts[@]}
  if [ $len -le 4 ]; then
    echo "$path"
  else
    echo "${parts[0]}/${parts[1]}/${parts[2]}/.../${parts[$((len-1))]}"
  fi
}

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]$(short_pwd)\[\033[00m\]\$ '

#export JAVA_HOME=$(asdf where java)

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
#export SDKMAN_DIR="$HOME/.sdkman"
#[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

git config --global alias.root 'rev-parse --show-toplevel'

git config --global core.editor "vim"
