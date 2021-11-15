# ⚠ Wait
I use this repo to quickly get my shell set up the way I like. You may not like your shell the way I like my shell, so maybe check out what the setup script does before you run it.

# 🛹 Future
Right now this is just a setup script. I want to eventually be able to add my dotfiles from my running system into this repo by typing something on the command line. I know there are projects out there that do this. Need to find time to learn how it works.

# Preconfigure
## Windows Terminal
I like to use CaskaydiaCove [Nerd Font](https://www.nerdfonts.com/) size 15, with the Campbell color scheme

# Test drive
If you have Docker, you can test drive this shell in a container
```shell
./run_test.sh debian
```
Instead of Debian you can supply the name of your favorite distro.

# How to install
1. Clone this project into your home directory. Run these commands from ~/dotfiles
```shell
./setup.sh
```

# Customize
```shell
p10k configure
```
