#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# First install required tools
pkg install -y coreutils >/dev/null 2>&1 &

# Progress bar function
progress_bar() {
    local pid=$1
    local delay=0.2
    local spin='-\|/'

    i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(((i + 1) % 4))
        printf "\r⏳ Progress: [${spin:$i:1}]"
        sleep $delay
    done
    printf "\r✅ Done!                    \n"
}

clear
echo -e "${CYAN}==============================="
echo -e " 🚀 Universal Ngrok Installer "
echo -e "   For Termux (ARM/x86/64)    "
echo -e "===============================${NC}\n"

# Update packages
echo -e "${YELLOW}📦 Updating Termux packages...${NC}"
(yes | pkg update -y && yes | pkg upgrade -y) >/dev/null 2>&1 &
progress_bar $!
echo

# Install dependencies
echo -e "${YELLOW}🔧 Installing dependencies...${NC}"
(yes | pkg install wget unzip -y) >/dev/null 2>&1 &
progress_bar $!
echo

# Detect CPU architecture
ARCH=$(dpkg --print-architecture)
echo -e "${CYAN}🔍 Detected architecture: $ARCH${NC}\n"

case "$ARCH" in
aarch64) NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.zip" ;;
arm | armhf) NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.zip" ;;
i*86 | i386 | i686) NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.zip" ;;
x86_64 | amd64) NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip" ;;
*)
    echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"
    exit 1
    ;;
esac

# Download Ngrok with real progress bar
echo -e "${YELLOW}⬇ Downloading Ngrok binary...${NC}"

# Use wget with progress=dot and custom parser
wget --progress=dot "$NGROK_URL" -O ngrok.zip 2>&1 |
    grep --line-buffered "%" |
    sed -u -e "s,\.,,g" |
    awk '{printf("\r   Progress: %s", $2)} END {print ""}'

echo -e "${GREEN}✅ Download complete!${NC}\n"

# Extract
echo -e "${YELLOW}📂 Installing Ngrok...${NC}"
unzip -o ngrok.zip >/dev/null 2>&1 &
progress_bar $!
mv ngrok $PREFIX/bin/
chmod +x $PREFIX/bin/ngrok
rm ngrok.zip
echo -e "${GREEN}✅ Ngrok installed successfully!${NC}\n"

# Auth Token
echo -e "${CYAN}👉 Enter your Ngrok Auth Token (or press ENTER to skip if you don't have one yet):${NC}"
read TOKEN
if [ -n "$TOKEN" ]; then
    ngrok config add-authtoken $TOKEN >/dev/null 2>&1
    echo -e "${GREEN}✅ Auth token saved successfully!${NC}\n"
else
    echo -e "${YELLOW}⚠ You skipped entering the auth token. You can add it later using:${NC}"
    echo "   ngrok config add-authtoken YOUR_TOKEN"
    echo
fi

# Done
echo -e "${CYAN}==============================="
echo -e " ✅ Ngrok installation complete!"
echo -e "===============================${NC}\n"
echo -e "💡 Start a tunnel with:"
echo -e "   ${YELLOW}ngrok http <PORT>${NC}\n"
echo -e "⚠ Make sure Mobile Hotspot or Wi-Fi is ON before starting Ngrok."
echo -e "\n👨‍💻 Script by: ${CYAN}Sameer Deshmukh${NC}"

# Fix USER warning for ngrok
if [ ! -f ~/.bashrc ]; then
    touch ~/.bashrc
fi

if ! grep -q "export USER=termux" ~/.bashrc; then
    echo 'export USER=termux' >>~/.bashrc
fi

# Apply immediately for current session
export USER=termux

if [ -n "$BASH_VERSION" ]; then
    source ~/.bashrc
elif [ -n "$ZSH_VERSION" ]; then
    source ~/.zshrc
fi
