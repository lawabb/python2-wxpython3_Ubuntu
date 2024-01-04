#!/bin/bash

# Install pyenv

install_pyenv_dependencies() {
    sudo apt-get update; sudo apt-get install make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
}

# Download and execute installation script

install_script() {
    curl https://pyenv.run | bash
}

# Add path to ~/.bashrc

add_path() {

    cat <<'EOF'>> ~/.bashrc
    # pyenv
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
EOF
 }

#install_pyenv_dependencies
#install_script
#add_path
#exec $SHELL
#pyenv --version
pyenv install 2.7.18
