#!/usr/bin/env bash

# If not running as root, use sudo
SUDO=""
if [ "$EUID" -ne 0 ]
then
  SUDO=sudo
fi
source make_gpg.sh

echo "Updating software packages"
$SUDO ./pacapt -Sy
echo "Installing zsh cURL and git dependencies"
$SUDO ./pacapt --noconfirm -S zsh git curl stow rclone 

unstow() {
	mv ~/.zshrc ~/.zshrc-backup
	(cd ~/dotfiles && stow *)
}

install_plugins() {
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  #echo "source ~/dotfiles/Spaceship10kTheme" >~/.zshrc
}


if [ ! -f "$HOME/.zshrc" ]
then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --skip-chsh
fi
#$SUDO rclone configure
#restore_secrets
unstow
install_plugins
exec zsh
