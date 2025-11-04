#!/usr/bin/env bash

if ! command -v brew &>/dev/null; then
    echo "brew is required for this script"
    exit 1
fi

if ! command -v curl &>/dev/null; then
    echo "curl is required for this script"
    exit 1
fi

echo "Running clamav setup"
echo "🚨 IMPORTANT: you will soon be prompted for your machine's password, please watch this script run."
echo "Note: your password will not be visible while you type."

echo "Installing clamav with brew..."
brew install clamav

echo "Downloading configs..."
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/clamd.conf \
    -o /opt/homebrew/etc/clamav/clamd.conf
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/freshclam.conf \
    -o /opt/homebrew/etc/clamav/freshclam.conf

echo "Setting up clamav..."
sudo mkdir /opt/homebrew/etc/clamav/{bin,quarantine}
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/bin/notify \
    -o /opt/homebrew/etc/clamav/bin/notify
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/bin/scan_downloads \
    -o /opt/homebrew/etc/clamav/bin/scan_downloads
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/bin/scan_home \
    -o /opt/homebrew/etc/clamav/bin/scan_home
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/bin/scan_volumes \
    -o /opt/homebrew/etc/clamav/bin/scan_volumes
sudo chown -R clamav:clamav /opt/homebrew/etc/clamav/{bin,quarantine,freshclam.conf,clamd.conf}
sudo chmod -R 770 /opt/homebrew/etc/clamav/bin
sudo chmod -R 640 /opt/homebrew/etc/clamav/{quarantine,freshclam.conf,clamd.conf}

echo "Setting up logs"
sudo mkdir -p /opt/homebrew/var/log/
sudo touch /opt/homebrew/var/log/{freshclam,clamdscan}.log
sudo chown clamav:clamav /opt/homebrew/var/log/{freshclam,clamdscan}.log
sudo chmod 644 /opt/homebrew/var/log/{freshclam,clamdscan}.log

echo "Starting clamd..."
sudo brew services start clamav

echo "Downloading daemons..."
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/daemons/com.vizerapp.clamav.clamdscan.downloads.plist \
    -o /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.downloads.plist
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/daemons/com.vizerapp.clamav.clamdscan.home.plist \
    -o /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.home.plist
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/daemons/com.vizerapp.clamav.clamdscan.volumes.plist \
    -o /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.volumes.plist
sudo curl -s https://raw.githubusercontent.com/vizerapp/clamav-install/HEAD/assets/daemons/com.vizerapp.clamav.freshclam.plist \
    -o /Library/LaunchDaemons/com.vizerapp.clamav.freshclam.plist
sudo chmod 644 /Library/LaunchDaemons/com.vizerapp.clamav.freshclam.plist
sudo chmod 644 /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.downloads.plist
sudo chmod 644 /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.home.plist
sudo chmod 644 /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.volumes.plist

echo "Starting daemons"
sudo launchctl load /Library/LaunchDaemons/com.vizerapp.clamav.freshclam.plist
sleep 5 # give freshclam a few moments to run
sudo launchctl load /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.downloads.plist
sudo launchctl load /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.home.plist
sudo launchctl load /Library/LaunchDaemons/com.vizerapp.clamav.clamdscan.volumes.plist

echo "Downloading test virus files..."
curl -s https://amtso.eicar.org/eicar.com -o ~/Downloads/eicar-standard-antivirus-test-file-d
cp ~/Downloads/eicar-standard-antivirus-test-file-d ~/eicar-standard-antivirus-test-file-h
sudo mkdir /Volumes/clamav-virus-test
sudo cp ~/Downloads/eicar-standard-antivirus-test-file-d /Volumes/clamav-virus-test/eicar-standard-antivirus-test-file-v

echo 'Within 60 seconds, two of the three eicar test files should be quarantined by clamav'
echo '🚨 IMPORTANT: please accept all permission requests from "clamd" and "clamdscan"'

i=60
while [ $i -gt 0 ]; do
    printf "\r$i"
    ((i--))
    sleep 1
done
echo

echo "Running cleanup"
sudo rm -rfv /Volumes/clamav-virus-test
sudo rm -vf /opt/homebrew/etc/clamav/quarantine/eicar-standard-antivirus-test-file-*

echo "✅ clamav setup complete"
