# PATH configurations

# ==============================
# Android SDK
# ==============================

export ANDROID_HOME=/home/ssk/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# ==============================
# Programming Languages
# ==============================

# Go
export PATH=$PATH:$HOME/go/bin

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Java
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# ==============================
# Package Managers
# ==============================

# Snap
export PATH=$PATH:/snap/bin

# pnpm
export PNPM_HOME="/home/ssk/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# npm global packages
export PATH="$HOME/.npm-global/bin:$PATH"

# Miniconda
export PATH="$PATH:/opt/miniconda3/bin"

# spicetify 
export PATH=$PATH:~/.spicetify
export PATH=$HOME/.local/bin:$PATH
PATH='/home/ssk/.serenedb/server/latest':/home/ssk/.local/bin:/home/ssk/.npm-global/bin:/home/ssk/.local/share/pnpm:/usr/lib/jvm/java-17-openjdk/bin:/home/ssk/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/opt/android-sdk/platform-tools:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin:/home/ssk/Android/Sdk/emulator:/home/ssk/Android/Sdk/tools:/home/ssk/Android/Sdk/tools/bin:/home/ssk/Android/Sdk/platform-tools:/home/ssk/go/bin:/snap/bin:/opt/miniconda3/bin:/home/ssk/.spicetify
