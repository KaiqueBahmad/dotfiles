td() {
        cat ~/.todo | expand -t4
}

vtd() {
        vim ~/.todo
}

ntd() {
        echo "[ ] $*" >> ~/.todo
}

gcc-run() { local name="${1%.c}"; gcc "$1" -o "$name" && echo "--- END OF COMPILATION ---"  && ./"$name"; }



npx() {
  "$(asdf where nodejs)/bin/npx" "$@"
}

kill-all-port() {
    if [ -z "$1" ]; then
        echo "Usage: kill-all-port <port>"
        return 1
    fi
    sudo kill -9 $(sudo lsof -t -i:$1)
}
