#!/bin/bash
logfile=/var/log/n8n-smash-install.sh

# Deals with errors
error_exit()
{
	echo "${1:-"Unknown Error"}" 1>&2
    echo "Last 10 entried by this script:"
    tail $logfile
    echo "Full log details are recorded in $logfile"
	exit 1
}

# Create log headings
log_heading()
{
    length=${#1}
    length=`expr $length + 8`
    printf '%*s' $length | tr ' ' '*'>>$logfile
    echo>>$logfile
    echo "*** $1 ***">>$logfile
    printf '%*s' $length | tr ' ' '*'>>$logfile
    echo>>$logfile
    echo -n $1...

}

# Runs commands with "sudo" if the user running the script is not root
SUDO=''
if [[ $EUID -ne 0 ]]; then
    SUDO='sudo'
fi

clear

message='This script is designed to install a pre-configured version of Smashing for use by n8n.\n\nIt will perform the following actions:\n    1. Update all software\n    2. Install Smashing dependencies\n    3. Install NodeJS\n    4. Install Smashing\n    5. Install n8n Dashboards\n    6. Reboot'
whiptail --backtitle "n8n-smashing Installer" --title "n8n-smashing Installer" --msgbox "$message"  18 78

if (whiptail --backtitle "n8n-smashing Installer" --title "Continue with install?" --yesno "Do you wish to continue with the installation?" 8 78); then

    # Updates list of packages
    log_heading "Updating package list"
    $SUDO apt update &>>$logfile || error_exit "$LINENO: Unable to update apt sources"
    echo "done!"

    # Upgrades packages
    log_heading "Upgrading packages (Please be patient, this may take a while)"
    $SUDO apt upgrade -y &>>$logfile || error_exit "$LINENO: Unable to upgrade packages"
    echo "done!"

    # Prepare for NodeJS Installation
    log_heading "Preparing for NodeJS installation"
    cd ~ || error_exit "$LINENO: Unable to change working directory to home directory"
    curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh || error_exit "$LINENO: Unable to download NodeJS setup script"
    $SUDO bash nodesource_setup.sh || error_exit "$LINENO: Unable to run NodeJS setup script"
    rm -rf nodesource_setup.sh || error_exit "$LINENO: Unable to delete NodeJS setup script"
    echo "done!"
   
    # Installs dependencies
    log_heading "Installing dependencies"
    $SUDO apt install build-essential nodejs ruby rubygems ruby-dev ruby-bundler -y &>>$logfile || error_exit "$LINENO: Unable to install dependencies"
    echo "done!"

    # Installs Smashing
    log_heading "Installing Smashing (Please be patient, this may take a while)"
    cd ~
    $SUDO gem install smashing &>>$logfile || error_exit "$LINENO: Unable to install Smashing"
    smashing new n8n_dashboard &>>$logfile || error_exit "$LINENO: Unable to create base n8n_dashboard"
    cd n8n_dashboard || error_exit "$LINENO: Unable to change working directory to n8n_dashboard"
    bundle install &>>$logfile || error_exit "$LINENO: Unable to bundle project"

    # Configuring n8n Dashboards
    log_heading "Install n8n Dashboards"
    rm -rf assets/images/logo.png &>>$logfile || error_exit "$LINENO: Unable to delete default logo"
    wget --no-cache -O assets/images/logo.png https://raw.githubusercontent.com/n8n-io/n8n/master/assets/n8n-logo.png &>>$logfile || error_exit "$LINENO: Unable to copy n8n logo"



else 
    error_exit "$LINENO: Installation cancelled"
fi
