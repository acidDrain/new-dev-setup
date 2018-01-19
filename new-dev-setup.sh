#!/usr/bin/env bash
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export VGPORT=8080
export REPOADDR="github.com"
export RT=`date +"%s"`
export COLS=$(stty -a | grep "rows\|col" | awk '{print $6}')
export LINE=`printf -- "-%.0s" {$(seq $COLS)}`
export COLORLINE="[38;5;114m$LINE[0m"

# First, check to see if a .ssh directory even exists in $HOME
# If not, create it and assume there are no ssh keys
if [ -a  $HOME/.ssh ]
  then
  echo $COLORLINE
  echo -e "[38;5;114mFound .ssh folder in $HOME[0m"
else
  echo $COLORLINE
  echo -e "[38;5;114mCreating ~/.ssh directory[0m"
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
fi

# We want to find and add the private key to the ssh config file
# The private key is always greater than 1k, public key is less than 1k.
if grep -q $REPOADDR $HOME/.ssh/config
  then
    github_key=`grep $REPOADDR $HOME/.ssh/config -A1 | tail -n1 | awk '{print $2}'`
    echo -e "[38;5;114mFound github key in $HOME/.ssh/config[0m"
    if !(ssh-add -l | awk '{print $3}' | grep -q -e "[a-z|A-Z]")
      then
      echo -e "[38;5;226m$github_key missing from ssh-agent, adding[0m"
      ssh-add $github_key
      echo $COLORLINE
    fi
  else
    echo -e "[38;5;226mNo github keys found in $HOME/.ssh, would you like to specify a key or have this script generate one for you to use? [y/N][0m\n1 - Specify key
    \n2 - Generate keys
    \n3 - Exit"
    read -n 1 -s keyopt
    case ${keyopt:0:3} in
        1 )
          echo -e "\n\nFull path to private ssh key - ex: /path/to/mykey"; read customKey
            customKey=`echo $customKey | sed "s;~;$HOME;"`
          if [ -a $customKey ]
            then
          echo "$customKey missing from ssh-agent, adding"
          echo -e "\n# github Identity\nHost 10.100.4.52\nHostName git.github.com\nIdentityFile $customKey" >> $HOME/.ssh/config
          ssh-add $customKey
          echo $COLORLINE
        else
          echo "Could not find the file specified: $customKey"
          exit
        fi
        ;;
        2 )
          github_key=$HOME/.ssh/github_key.$RT
          echo -e "\n\nGenerating ${github_key} and ${github_key}.pub and placing in $HOME/.ssh"
          ssh-keygen -q -t rsa -f $github_key -P ""
          echo "Adding $github_key to ~/.ssh/config for git.github.com"
          echo -e "\n# github Identity\nHost 10.100.4.52\nHostName git.github.com\nIdentityFile $github_key" >> $HOME/.ssh/config
          chmod 644 $HOME/.ssh/config
          ssh-add $github_key
          echo "Please add $github_key.pub to the Access Keys for your user in"
          echo "github https://git.github.com/admin/users/view?name=user.name"
          echo -e "For convenience, printing the contents of $github_key.pub:\n"
          echo $LINE
          echo $(cat $github_key.pub | awk '{print $1 $2}')
          echo $LINE
          echo -e "\n\n"
        ;;
        3 ) echo -e "\n\nAnswer was no, exiting\n\n"
        exit;;
    esac
  fi

if ! $(ssh-add -l | grep -q "$github_key")
  then
  echo $COLORLINE
  echo "$github_key missing from ssh-agent, adding"
  ssh-add $github_key
  echo $COLORLINE
fi

 if  !(which -s virtualbox)
    then
    read -n 1 -p "No virtualbox install found - would you like to install via brew? (May take a while) [y/N]" VBINST
    case ${VBINST:0:1} in
      y|Y )
        echo $COLORLINE
        echo -e "\nInstalling virtualbox"
        brew install Caskroom/cask/virtualbox
        echo $COLORLINE
    ;;
      * ) echo -e "\nExiting"
    exit;;
  esac
  fi

  if  !(which -s vagrant)
    then
    echo -e "[38;5;226mNo vagrant install found - would you like to install via brew? (May take a while) [y/N]0"
    read -n 1 VAGINST
    case ${VAGINST:0:1} in
      y|Y )
        echo $COLORLINE
        echo -e "[38;5;226mInstalling vagrant0"
        brew install Caskroom/cask/vagrant
        echo $COLORLINE
    ;;
      * ) echo -e "\n[35mExiting0"
    exit;;
  esac
  fi

# Check if the vbguest plugin is installed, and install it if it isn't
if !(vagrant plugin list | grep -q "vagrant-vbguest")
  then
  echo $COLORLINE
  echo -e "[38;5;226mInstalling vbguest plugin for vagrant[0m"
  vagrant plugin install vagrant-vbguest
  echo $COLORLINE
fi

# Check if the vagrant puppet install plugin is installed, and install it if it isn't
# Re-evaluating whether the below is necessary, therefore commenting out [JG-2018/01/18]
# if !(vagrant plugin list | grep -q "vagrant-puppet-install")
# then
#   echo $COLORLINE
#   echo -e "[38;5;226mInstalling puppet-install plugin for vagrant[0m"
#   vagrant plugin install vagrant-puppet-install
#   echo $COLORLINE
# fi
#
# Check if the centos/7 vagrant box is installed, if it's not, add it
# if !(vagrant box list | grep -q "centos/7")
#   then
#   echo $COLORLINE
#   echo -e "[38;5;226mInstalling centos/7 box for vagrant[0m"
#   vagrant box add centos/7 --provider=virtualbox
#   echo $COLORLINE
# fi

# Clone the portal repo
if !(which -s git)
  then
  echo -e "[38;5;226mNo git install found - would you like to install it via brew? (May take a while) [y/N][0m"
  read -n 1 GITINST
  case ${GITINST:0:1} in
    y|Y )
      echo $COLORLINE
      echo -e "[38;5;226mInstalling vagrant[0m"
      brew install git
      echo $COLORLINE
    ;;
    * ) echo -e "[38;5;226mExiting[0m"
    exit;;
  esac
fi

if !(which -s npm)
  then
  read -n 1 -p "[38;5;226mNo nodejs/npm executables found - would you like to install it via brew? (May take a while) [y/N][0m" NPMINST
  case ${NPMINST:0:1} in
    y|Y )
      echo $COLORLINE
      echo -e "[38;5;226mInstalling node.js and npm[0m"
      brew install node
      echo $COLORLINE
    ;;
    * ) echo -e "[38;5;226mExiting[0m"
    exit;;
  esac
fi

if !(which -s automake)
    then
    echo $COLORLINE
    read -n 1 -p "[38;5;226mInstall build-tools? [y/N][0m" BUILDTOOLS
    case ${BUILDTOOLS:0:1} in
        y|Y )
            echo $COLORLINE
            echo -e "[38;5;226mInstalling build tools[0m"
            brew install readline redis rlwrap tmux tree rtmpdump wget xz yarn glib emacs jq dos2unix autoconf automake c-ares cairo clasp clingo cmake coreutils cpprestsdk gnupg gnutls go gcc@6 libarchive libass libassuan libbluray libbs2b libcaca libebml libepoxy libev libevent libffi libgcrypt libgpg-error libgsm libidn2 libksba libmagic libmatroska libmodplug libmpc libogg libpng libsamplerate libsndfile libsoxr libssh libtasn1 libtiff libtool libunistring libusb libvidstab libvorbis libvpx libyaml little-cms little-cms2 lua
        ;;
        * ) echo -e "[38;5;226mNot installing build tools[0m"
    exit;;
    esac
fi

if !(which -s ffmpeg)
    then
    echo $COLORLINE
    read -n 1 -p "[38;5;226mInstall media tools? [y/N][0m" MEDIATOOLS
    case ${MEDIATOOLS:0:1} in
        y|Y )
            echo $COLORLINE
            echo -e "[38;5;226mInstalling media tools[0m"
            brew install x264 x265 xvid wavpack faac fdk-aac ffmpeg flac lame jpeg openh264 openjpeg mkvtomp4 mkvtoolnix mpfr
        ;;
        * ) echo -e "[38;5;226mNot installing media tools[0m"
    exit;;
    esac
fi

if !(which -s aws)
    then
    echo $COLORLINE
    echo -e "[38;5;226mInstalling aws tools[0m"
    brew install awscli juju juju-wait kompose kops kubernetes-cli kubernetes-helm terraform
fi

echo $COLORLINE
echo -e "[1;49;32mScript complete![0m"
echo $COLORLINE
