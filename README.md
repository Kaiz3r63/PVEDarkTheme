
<p align="center">THEME EN COURS DE DEVELOPPEMENT</p>
                                                           
![](https://raw.githubusercontent.com/Kaiz3r63/PVEDarkTheme/master/screen%20capture%20install.png)

<p align="center">Dark theme for Proxmox web GUI,<br/> <i>Forked from PVEDiscordDark by Weilbyte</i></p>

<p align="center">Fully dark theme, include graphs and context menus.

## Installation 
The installation is done via the CLI utility. Run the following commands on the PVE node serving the Web UI:

```
~# wget https://raw.githubusercontent.com/Kaiz3r63/PVEDarkTheme/master/PVEDarkTheme.sh
~# bash PVEDarkTheme.sh install
```
Or this oneliner
```
bash <(curl -s https://raw.githubusercontent.com/Kaiz3r63/PVEDarkTheme/master/PVEDarkTheme.sh ) install
```


## Uninstallation
 To uninstall the theme, simply run the utility with the `uninstall` command.
 
## Installer & Security
The new installer relies on the `/meta/supported` and `/meta/imagelist` files being present in the repository. It also includes a silent mode. Run `bash PVEDiscordDark.sh -h` for usage instructions. 

Furthermore, you will be able to provide the environment variables `REPO` and `TAG` to specify from what repository and from what commit tag to install the theme from.   
`REPO` is in format `Username/Repository` and defaults to `Weilbyte/PVEDiscordDark` (this repository).    
`TAG` defaults to `master`, but it is strongly recommended to use the SHA-1 commit hash for security.

## Offline bundle
If desired, the installation utility can be run offline. Upon detecting a folder called `offline` in the current working directory, the script will enter offline mode and use the resources within that folder instead of retrieving them from GitHub.    

The `offline` folder must have the following files: `meta/[imagelist, supported]`, `PVEDiscordDark/images/*`, `PVEDiscordDark/js/PVEDiscordDark.js`, `PVEDiscordDark/sass/PVEDiscordDark.css`

You can find a zip containing the installer and offline folder under the artifact section of the GitHub Actions under this repository or as an asset attached to releases.

## Notes
Thanks to [jonasled](https://github.com/jonasled) for helping out with the old version, and thanks to [SmallEngineMechanic](https://github.com/smallenginemechanic) for catching bugs for the rewrite!

*Awoo'ing on this repo is encouraged.*
