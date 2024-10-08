#!/usr/bin/env bash

# one liner install:
# env bash -c "$(curl -sL https://github.com/khulnasoft/cyberpotmobile/raw/main/install.sh)"

echo "##########################"
echo "# CyberPot Mobile Installer #"
echo "##########################"
echo

CONFIG_FILE="/boot/config.txt"

######
# Go to home folder, install updates and clone repositories
######

cd $HOME
sudo apt update
sudo apt dist-upgrade -y
sudo apt install git exa mesa-utils micro python3 python3-pygame python3-pip unattended-upgrades -y
#sudo rpi-update
git clone https://github.com/khulnasoft/cyberpotmobile
git clone https://github.com/khulnasoft/cyberpot

######
# Setup configs
######

# Function to set dtoverlay for DSI display
set_dsi_display() {
    sudo sed --follow-symlinks -i 's/^dtoverlay=.*/dtoverlay=vc4-kms-v3d/' $CONFIG_FILE
    sudo raspi-config nonint do_spi 1 # 0 is enable, 1 is disable
}

echo "# Setting up Waveshare 4.3inch capacitive display ..."
set_dsi_display

echo
echo "# Now setting up CyberPot Mobile. Please be patient ..."
sudo raspi-config nonint do_i2c 0 # 0 is enable, 1 is disable - for UPS HAT
python3 -m venv --system-site-packages cyberpotmobile/
cd cyberpotmobile
source bin/activate
pip3 install -r requirements.txt
deactivate
cd $HOME
sudo cp cyberpotmobile/settings/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
sudo bash -c "sed s/'\$LOGNAME'/${LOGNAME}/g cyberpotmobile/settings/cyberpotdisplay.service > /etc/systemd/system/cyberpotdisplay.service"
sudo chmod 644 /etc/systemd/system/cyberpot* /etc/apt/apt.conf.d/20auto-upgrades
sudo chown root /etc/systemd/system/cyberpot* /etc/apt/apt.conf.d/20auto-upgrades
sudo systemctl enable cyberpotdisplay.service
echo
echo "# Now setting up CyberPot. Please be patient ..."
cd cyberpot
bash install.sh

cd $HOME
# We do not want CyberPot to update automatically
sed -i s/CYBERPOT_PULL_POLICY=always/CYBERPOT_PULL_POLICY=missing/g cyberpot/.env
sed -i '/^CYBERPOT_TYPE=/c\CYBERPOT_TYPE=MOBILE' cyberpot/.env
# We need to adjust the CyberPot service
sudo bash -c "sed s/'\$LOGNAME'/${LOGNAME}/g cyberpotmobile/settings/cyberpot.service > /etc/systemd/system/cyberpot.service"
sudo systemctl daemon-reload
sudo systemctl enable cyberpot.service
# We always want CyberPot Mobile
cp cyberpot/compose/mobile.yml cyberpot/docker-compose.yml

echo
echo "# Done. You can reboot now."
