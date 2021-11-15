convert_bash_hist() {
  curl -Lo ~/bash-to-zsh-hist.py https://gist.github.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py
  chmod +x ~/bash-to-zsh-hist.py
  echo "Converting bash history"
  cat ~/.bash_history | bash-to-zsh-hist.py >> ~/.zsh_history
}
