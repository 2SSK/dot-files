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

# Miniconda
export PATH="$PATH:/opt/miniconda3/bin"
