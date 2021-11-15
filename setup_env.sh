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
