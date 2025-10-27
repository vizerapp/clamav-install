#!/usr/bin/env bash

if ! command -v brew &>/dev/null; then
    echo "brew is required for this script"
    exit 1
fi

if ! command -v curl &>/dev/null; then
    echo "curl is required for this script"
    exit 1
fi

ARCHITECTURE=$(arch)
BASE_PATH=/opt/homebrew/etc
LOG_PATH=/opt/homebrew/var/log

if [[ "$ARCHITECTURE" == "i386" ]]; then
    BASE_PATH=/usr/local/etc
    LOG_PATH=/var/log
fi

echo "Running clamav setup"
echo "🚨 IMPORTANT: you will soon be prompted for your machine's password, please watch this script run."
echo "Note: your password will not be visible while you type."

echo "Installing clamav with brew..."
brew install clamav

echo "Downloading configs..."
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/clamd.conf \
    -o "$BASE_PATH/clamav/clamd.conf"
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/freshclam.conf \
    -o "$BASE_PATH/clamav/freshclam.conf"
if [[ "$ARCHITECTURE" == "i386" ]]; then
    sudo sed -i '' "s|/opt/homebrew/etc|/usr/local|g" "$BASE_PATH/clamav/freshclam.conf"
    sudo sed -i '' "s|/opt/homebrew/etc|/usr/local|g" "$BASE_PATH/clamav/clamd.conf"
fi

echo "Setting up clamav..."
sudo mkdir "$BASE_PATH/clamav/bin"
sudo mkdir "$BASE_PATH/clamav/quarantine"
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/bin/notify \
    -o "$BASE_PATH/clamav/bin/notify"
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/bin/scan_downloads \
    -o "$BASE_PATH/clamav/bin/scan_downloads"
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/bin/scan_home \
    -o "$BASE_PATH/clamav/bin/scan_home"
sudo chown -R clamav:clamav "$BASE_PATH/clamav/bin"
sudo chown -R clamav:clamav "$BASE_PATH/clamav/quarantine"
sudo chown -R clamav:clamav "$BASE_PATH/clamav/freshclam.conf"
sudo chown -R clamav:clamav "$BASE_PATH/clamav/clamd.conf"
sudo chmod -R 770 "$BASE_PATH/clamav/bin"
sudo chmod -R 640 "$BASE_PATH/clamav/quarantine"
sudo chmod -R 640 "$BASE_PATH/clamav/freshclam.conf"
sudo chmod -R 640 "$BASE_PATH/clamav/clamd.conf"
if [[ "$ARCHITECTURE" == "i386" ]]; then
    sudo sed -i '' "s|/opt/homebrew/etc/clamav|/usr/local/etc/clamav|g" "$BASE_PATH/clamav/bin/notify.conf"
    sudo sed -i '' "s|/opt/homebrew/etc/clamav|/usr/local/etc/clamav|g" "$BASE_PATH/clamav/bin/scan_downloads.conf"
    sudo sed -i '' "s|/opt/homebrew/etc/clamav|/usr/local/etc/clamav|g" "$BASE_PATH/clamav/bin/scan_home.conf"
fi

echo "Setting up logs"
sudo mkdir -p "$LOG_PATH/"
sudo touch "$LOG_PATH/freshclam.log"
sudo touch "$LOG_PATH/clamdscan.log"
sudo chown clamav:clamav "$LOG_PATH/freshclam.log"
sudo chown clamav:clamav "$LOG_PATH/clamdscan.log"
sudo chmod 644 "$LOG_PATH/freshclam.log"
sudo chmod 644 "$LOG_PATH/clamdscan.log"

echo "Starting clamd..."
sudo brew services start clamav

echo "Downloading daemons..."
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/daemons/com.vizerapp.clamav.clamdscan.downloads.plist \
    -o /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.downloads.plist
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/daemons/com.vizerapp.clamav.clamdscan.home.plist \
    -o /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.home.plist
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/daemons/com.vizerapp.clamav.freshclam.plist \
    -o /Library/LaunchDaemons/com.vizerapp.clamav.freshclam.plist
sudo chmod 644 /Library/LaunchDaemons/com.vizerapp.clamav.freshclam.plist
sudo chmod 644 /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.downloads.plist
sudo chmod 644 /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.home.plist
if [[ "$ARCHITECTURE" == "i386" ]]; then
    sudo sed -i '' "s|/opt/homebrew/etc/clamav|/usr/local/etc/clamav|g" /Library/LaunchDaemons/com.vizerapp.clamav.freshclam.plist
    sudo sed -i '' "s|/opt/homebrew/etc/clamav|/usr/local/etc/clamav|g" /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.downloads.plist
    sudo sed -i '' "s|/opt/homebrew/etc/clamav|/usr/local/etc/clamav|g" /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.home.plist
    sudo sed -i '' "s|/opt/homebrew/var/log|/var/log|g" /Library/LaunchDaemons/com.vizerapp.clamav.freshclam.plist
    sudo sed -i '' "s|/opt/homebrew/var/log|/var/log|g" /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.downloads.plist
    sudo sed -i '' "s|/opt/homebrew/var/log|/var/log|g" /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.home.plist
fi

echo "Starting daemons"
sudo launchctl load /Library/LaunchDaemons/com.vizerapp.clamav.freshclam.plist
sleep 5 # give freshclam a few moments to run
sudo launchctl load /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.downloads.plist
sudo launchctl load /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.home.plist

echo "Downloading test virus files..."
curl -s https://amtso.eicar.org/eicar.com -o ~/Downloads/eicar-standard-antivirus-test-file-d
cp ~/Downloads/eicar-standard-antivirus-test-file-d ~/eicar-standard-antivirus-test-file-h

echo 'Within 15 seconds, the eicar test files should be quarantined by clamav'
echo '🚨 IMPORTANT: please accept all permission requests from "clamd" and "clamdscan"'

i=15
while [ $i -gt 0 ]; do
    printf "\r$i"
    ((i--))
    sleep 1
done
echo

echo "✅ clamav setup complete"
