#!/usr/bin/env bash

# If not running as root, use sudo
SUDO=""
if [ "$EUID" -ne 0 ]
then
  SUDO=sudo
fi
source make_gpg.sh
source secrets.sh

echo "Updating software packages"
$SUDO ./pacapt -Sy

echo "Installing zsh cURL and git dependencies"
$SUDO ./pacapt --noconfirm -S zsh git curl stow rclone 

echo "Installing utilities I like to have"
$SUDO ./pacapt --noconfirm -S neovim

install_gh() {
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
$SUDO chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
$SUDO apt update
$SUDO apt install gh
}

unstow() {
	mv $HOME/.zshrc $HOME/.zshrc-backup
	(cd $HOME/dotfiles && stow *)
	
	if [ ! -d "$HOME/secrets" ]
	then
	  secrets
	fi
	if [ -d "$HOME/.ssh" ]
	then
		echo "Backing up existing .ssh folder to prevent clash with stow"
		mv $HOME/.ssh $HOME/.ssh-backup
	fi
	(cd $HOME/secrets && stow *)
}

install_plugins() {
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
}

dotfiles() {
  git clone https://github.com/konradish/dotfiles $HOME/dotfiles
}

if [ ! -f "$HOME/.zshrc" ]
then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --skip-chsh
fi
#$SUDO rclone configure
#restore_secrets
dotfiles
unstow
install_plugins
exec zsh
