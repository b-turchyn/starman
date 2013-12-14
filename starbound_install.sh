#!/bin/bash

# Var Defaults

SESS_NAME=starbound
WINDOW_NAME=0
PANE_NAME=0
USER=starbound
SV_PASSWORD=''
RCON_PASSWORD='PaSsWoRd!'
MAX_PLAYERS=12


# Grab vars from command line
while getopts ":M:S:u:s:r:m:o:hg:" opt; do
  case $opt in
    S)
      SESS_NAME="$OPTARG"
      ;;
    u)
      USER="$OPTARG"
      ;;
    o)
      EXTRA_OPTIONS="$OPTARG"
      ;;
    h)
      cat <<DELIM

    Usage: ./gmod_install.sh

    Option    Description                               Default
    --------------------------------------------------------------------
        -u    User to install the server under          starbound
        -S    Session name for tmux                     starbound
        -o    Set extra options

DELIM
      exit -1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      exit 1
      ;;
  esac
done

HOMEDIR="/home/$USER"
ARCH=`uname -p`

clear

# Opening Banner
cat <<DELIM
     _____ _
    / ____| |
   | (___ | |_ __ _ _ __ _ __ ___   __ _ _ __
    \___ \| __/ _\` | '__| '_ \` _ \ / _\` | '_ \\
    ____) | || (_| | |  | | | | | | (_| | | | |
   |_____/ \__\__,_|_|  |_| |_| |_|\__,_|_| |_|

     Starbound Dedicated Server Auto-Installer


================================================================================
  Options
================================================================================

   System Architecture: $ARCH
   Username: $USER
   Tmux Session Name: $SESS_NAME
   Extra Options: $EXTRA_OPTIONS
================================================================================

  NOTE: Starbound requires Steam credentials to install the server; you will
  have to input them shortly!

  You have 5 seconds to hit Ctrl-C if the above options don't look right!
DELIM

sleep 5

read -p "Steam Username: " STEAM_USER
read -s -p "Steam Password: " STEAM_PASS

apt-get update

# Check that we have 32-bit lib support
if [ "$ARCH" = "x86_64" ];
then
  dpkg --add-architecture i386
  apt-get update
  apt-get -y install ia32-libs
fi

# Required (and useful) stuffs
apt-get -y install vim libevent-dev libncurses5-dev build-essential

# Check tmux version >= 1.8
TMUX_VERSION=`tmux -V | cut -d " " -f 2`

if [ -n "$TMUX_VERSION" ] && [ "1.8" -gt "$TMUX_VERSION" ];
then
  apt-get uninstall -y tmux
fi

wget http://downloads.sourceforge.net/tmux/tmux-1.8.tar.gz
tar xfz tmux-1.8.tar.gz
cd tmux-1.8
./configure
make install clean

# Get srcds and install Starbound
mkdir -p "$HOMEDIR"
useradd $USER
wget http://media.steampowered.com/client/steamcmd_linux.tar.gz -O "$HOMEDIR/steamcmd_linux.tar.gz"
tar xfz "$HOMEDIR/steamcmd_linux.tar.gz" -C "$HOMEDIR"
chmod +x "$HOMEDIR/steamcmd.sh"
chown -R $USER:$USER $HOMEDIR
chmod 700 $HOMEDIR
su - -c "$HOMEDIR/steamcmd.sh +login $STEAM_USER $STEAM_PASS +force_install_dir $HOMEDIR/starbound +app_update 211820 validate +quit" $USER

# Spin up the tmux session
tmux new-session -A -d -s $SESS_NAME

tmux send-keys -t "$SESS_NAME:$WINDOW_NAME.$PANE_NAME" C-z \
  "su - -c '$HOMEDIR/starbound/starbound_launch_server.sh' $USER" Enter
