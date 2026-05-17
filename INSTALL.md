# Quick Install

```bash
cd /home/ubuntu
git clone https://github.com/brandonjank/conan-exiles-linux-mod-updater.git
cd conan-exiles-linux-mod-updater

cp conan-mod-updater.sh /home/ubuntu/conan_exiles/conan-mod-updater.sh
chmod +x /home/ubuntu/conan_exiles/conan-mod-updater.sh

# Optional: set before running if paths differ from defaults (see README)
# export CONAN_BASE_PATH="/home/ubuntu/conan_exiles"
# export STEAMCMD_PATH="$HOME/.local/share/Steam/steamcmd/steamcmd.sh"

/home/ubuntu/conan_exiles/conan-mod-updater.sh
```

With pruning:

```bash
/home/ubuntu/conan_exiles/conan-mod-updater.sh --prune
