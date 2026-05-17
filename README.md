# Conan Exiles Linux Mod Updater

Bash script to update a Conan Exiles Linux dedicated server and Steam Workshop mods with SteamCMD, rebuild modlist.txt, and restart the server in tmux.

This script is designed for servers installed at:

```text
/home/ubuntu/conan_exiles
```

It updates the Conan Exiles dedicated server, downloads the mods listed in `ServerSettings.ini`, rebuilds `modlist.txt` using relative `.pak` paths, and makes sure the server is running afterward in a `tmux` session.

## What it does

- Stops the running Conan server from `tmux`, if it is already running
- Sends `Ctrl-C`, waits 10 seconds, sends `Ctrl-C` again, then kills the session if it still has not stopped after 60 seconds
- Updates the Conan Exiles dedicated server using SteamCMD
- Reads mod IDs from `ServerModList=` in `ServerSettings.ini`
- Downloads each Steam Workshop mod
- Finds each `.pak` file
- Writes relative paths to:

```text
ConanSandbox/Mods/modlist.txt
```

- Backs up the old mod list to:

```text
ConanSandbox/Mods/modlist.txt.bak
```

- Starts the server in a `tmux` session named `conan`
- Prevents multiple updater copies from running at the same time
- Logs to:

```text
ConanSandbox/Mods/conan-mod-updater.log
```

## Requirements

- Linux
- Bash
- SteamCMD
- tmux
- A Conan Exiles Linux dedicated server installed in `/home/ubuntu/conan_exiles`

Install tmux if needed:

```bash
sudo apt update
sudo apt install -y tmux
```

## Install

Clone this repository:

```bash
cd /home/ubuntu
git clone https://github.com/YOUR_USERNAME/conan-exiles-linux-mod-updater.git
cd conan-exiles-linux-mod-updater
```

Copy the script to your Conan Exiles server folder:

```bash
cp conan-mod-updater.sh /home/ubuntu/conan_exiles/conan-mod-updater.sh
chmod +x /home/ubuntu/conan_exiles/conan-mod-updater.sh
```

## SteamCMD path

By default, the script expects SteamCMD here:

```text
/home/ubuntu/.local/share/Steam/steamcmd/steamcmd.sh
```

If your SteamCMD path is different, edit this line in `conan-mod-updater.sh`:

```bash
STEAMCMD="$HOME/.local/share/Steam/steamcmd/steamcmd.sh"
```

## Server path

By default, the script expects the Conan server here:

```text
/home/ubuntu/conan_exiles
```

If your server is installed somewhere else, edit this line:

```bash
BASE_PATH="/home/ubuntu/conan_exiles"
```

## Mod configuration

The script reads mod IDs from:

```text
/home/ubuntu/conan_exiles/ConanSandbox/Saved/Config/LinuxServer/ServerSettings.ini
```

Example:

```ini
ServerModList=880454836,1823412793,2050780234
```

The script will download those mods and generate:

```text
/home/ubuntu/conan_exiles/ConanSandbox/Mods/modlist.txt
```

Example generated entries:

```text
steamapps/workshop/content/440900/880454836/example.pak
steamapps/workshop/content/440900/1823412793/example.pak
```

## Usage

Run the updater:

```bash
/home/ubuntu/conan_exiles/conan-mod-updater.sh
```

Remove downloaded workshop mods that are no longer listed in `ServerModList`:

```bash
/home/ubuntu/conan_exiles/conan-mod-updater.sh --prune
```

Show help:

```bash
/home/ubuntu/conan_exiles/conan-mod-updater.sh --help
```

## tmux commands

Attach to the running Conan server:

```bash
tmux attach -t conan
```

Detach from the session:

```text
Ctrl+b, then d
```

Check if the session is running:

```bash
tmux ls
```

Manually stop the session:

```bash
tmux kill-session -t conan
```

## App IDs

This script uses:

| Purpose | Steam App ID |
|---|---:|
| Conan Exiles dedicated server | `443030` |
| Conan Exiles Workshop content | `440900` |

## Notes

The script assumes the Conan server is launched with:

```bash
/home/ubuntu/conan_exiles/ConanSandbox/Binaries/Linux/ConanSandboxServer-Linux-Shipping ConanSandbox
```

The server is started in a detached `tmux` session named:

```text
conan
```

## Troubleshooting

### SteamCMD is missing or non-executable

Check the path:

```bash
ls -l ~/.local/share/Steam/steamcmd/steamcmd.sh
```

Make it executable:

```bash
chmod +x ~/.local/share/Steam/steamcmd/steamcmd.sh
```

### tmux is missing

Install it:

```bash
sudo apt install -y tmux
```

### No mods are added

Check that `ServerModList=` exists in:

```text
ConanSandbox/Saved/Config/LinuxServer/ServerSettings.ini
```

Also check the log:

```bash
tail -n 100 /home/ubuntu/conan_exiles/ConanSandbox/Mods/conan-mod-updater.log
```

### The server does not stop cleanly

The updater sends `Ctrl-C`, waits 10 seconds, sends `Ctrl-C` again, then waits up to 60 seconds. If the server still does not stop, it kills the tmux session.

## Contributing

Pull requests are welcome. Keep the script simple and focused on Linux dedicated servers using SteamCMD and tmux.
