#!/bin/bash
# Code basé sur la version PVEDiscordDark de Weilbyte - https://github.com/Weilbyte/PVEDiscordDark
# Fork pour adapté a mes gouts et traduction :)

umask 022

#region Consts
RED='\033[0;31m'
BRED='\033[0;31m\033[1m'
GRN='\033[92m'
WARN='\033[93m'
BOLD='\033[1m'
REG='\033[0m'
CHECKMARK='\033[0;32m\xE2\x9C\x94\033[0m'

TEMPLATE_FILE="/usr/share/pve-manager/index.html.tpl"
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
SCRIPTPATH="${SCRIPTDIR}$(basename "${BASH_SOURCE[0]}")"

OFFLINEDIR="${SCRIPTDIR}offline"

REPO=${REPO:-"Kaiz3r63/PVEDarkTheme"}
DEFAULT_TAG="master"
TAG=${TAG:-$DEFAULT_TAG}
BASE_URL="https://raw.githubusercontent.com/$REPO/$TAG"

OFFLINE=false
#endregion Consts

#region Prerun checks
if [[ $EUID -ne 0 ]]; then
    echo -e >&2 "${BRED}Les privilèges root sont nécéssaires pour effectuer cette opération${REG}";
    exit 1
fi

hash sed 2>/dev/null || { 
    echo -e >&2 "${BRED}sed est requis, mais il est absent de votre système${REG}";
    exit 1;
}

hash pveversion 2>/dev/null || { 
    echo -e >&2 "${BRED}Une installation PVE est requise pour effectuer cette opération${REG}";
    exit 1;
}

if test -d "$OFFLINEDIR"; then
    echo "Repertoire Offline détecté, passage en mode Offline"
    OFFLINE=true
else
    hash curl 2>/dev/null || { 
        echo -e >&2 "${BRED}cURL est requis, mais il est absent de votre système${REG}";
        exit 1;
    }
fi

if [ "$OFFLINE" = false ]; then
    curl -sSf -f https://github.com/robots.txt &> /dev/null || {
        echo -e >&2 "${BRED}Impossible d'établir une connexion avec GitHub (github.com)${REG}";
        exit 1;
    }

    if [ $TAG != $DEFAULT_TAG ]; then
        if !([[ $TAG =~ [0-9] ]] && [ ${#TAG} -ge 7 ] && (! [[ $TAG =~ ['!@#$%^&*()_+.'] ]]) ); then 
            echo -e "${WARN}Il semble que vous utilisiez une balise autre que celle par défaut. Pour des raisons de sécurité, veuillez utiliser le hachage SHA-1 de ladite balise à la place${REG}"
        fi
    fi
fi
#endregion Prerun checks

PVEVersion=$(pveversion --verbose | grep pve-manager | cut -c 14- | cut -c -6) # Below pveversion pre-run check
PVEVersionMajor=$(echo $PVEVersion | cut -d'-' -f1)

#region Helper functions
function checkSupported {   
    if [ "$OFFLINE" = false ]; then
        local SUPPORTED=$(curl -f -s "$BASE_URL/meta/supported")
    else
        local SUPPORTED=$(cat "$OFFLINEDIR/meta/supported")
    fi

    if [ -z "$SUPPORTED" ]; then 
        if [ "$OFFLINE" = false ]; then
            echo -e "${WARN}Impossible d'atteindre le fichier de version pris en charge ($BASE_URL/meta/supported). Vérification de support ignorée.${REG}"
        else
            echo -e "${WARN}Impossible d'atteindre le fichier de version pris en charge ($OFFLINEDIR/meta/supported). Vérification de support ignorée.${REG}"
        fi
    else 
        local SUPPORTEDARR=($(echo "$SUPPORTED" | tr ',' '\n'))
        if ! (printf '%s\n' "${SUPPORTEDARR[@]}" | grep -q -P "$PVEVersionMajor"); then
            echo -e "${WARN}Vous risquez de rencontrer des problèmes car votre version ($PVEVersionMajor) ne correspont pas aux versions supportées ($SUPPORTED)."
            echo -e "Si vous rencontrez des problèmes sur les versions >newer<, vous pouvez ouvrir un incident a l'adresse https://github.com/Weilbyte/PVEDiscordDark/issues.${REG}"
        fi
    fi
}

function isInstalled {
    if (grep -Fq "<link rel='stylesheet' type='text/css' href='/pve2/css/dd_style.css'>" $TEMPLATE_FILE &&
        grep -Fq "<script type='text/javascript' src='/pve2/js/dd_patcher.js'></script>" $TEMPLATE_FILE &&
        [ -f "/usr/share/pve-manager/css/dd_style.css" ] && [ -f "/usr/share/pve-manager/js/dd_patcher.js" ]); then 
        true
    else 
        false
    fi
}

#endregion Helper functions

#region Main functions
function usage {
    if [ "$_silent" = false ]; then
        echo -e "Utilisation: $0 [OPTIONS...] {COMMAND}\n"
        echo -e "Pour gérer le theme PVEDarkTheme."
        echo -e "  -h --help            Afficher cette aide"
        echo -e "  -s --silent          Mode silencieux \n"
        echo -e "Commandes:"
        echo -e "  status               Check l'état du thème (0 si installé, and 1 si non installé)"
        echo -e "  install              Installe le thème"
        echo -e "  uninstall            Désinstalle le thème"
        echo -e "  update               Met a jour le thème (Va executer uninstall, puis install)"
    #    echo -e "  utility-update       Update this utility\n" (to be implemented)
        echo -e "Exit codes:"
        echo -e "  0                    OK"
        echo -e "  1                    Erreur"
        echo -e "  2                    Déja installé, ou non installé (si utilisé install/uninstall)\n"
        echo -e "Report issues at: <https://github.com/Weilbyte/PVEDiscordDark/issues>"
    fi
}

function status {
    if [ "$_silent" = false ]; then
        echo -e "Theme"
        if isInstalled; then
            echo -e "  Status:      ${GRN}present${REG}"
        else
            echo -e "  Status:      ${RED}non present${REG}"
        fi
        echo -e "  CSS:         $(sha256sum /usr/share/pve-manager/css/dd_style.css 2>/dev/null  || echo N/A)"
        echo -e "  JS:          $(sha256sum /usr/share/pve-manager/js/dd_patcher.js 2>/dev/null  || echo N/A)\n"
        echo -e "PVE"
        echo -e "  Version:     $PVEVersion (major $PVEVersionMajor)\n"
        echo -e "Utility hash:  $(sha256sum $SCRIPTPATH 2>/dev/null  || echo N/A)"
        echo -e "Offline mode:  $OFFLINE"
    fi
    if isInstalled; then exit 0; else exit 1; fi
}

function install {
    if isInstalled; then
        if [ "$_silent" = false ]; then echo -e "${RED}Thème déja installé${REG}"; fi
        exit 2
    else
        if [ "$_silent" = false ]; then checkSupported; fi
	
	if [ "$_silent" = false ]; then
	echo -e "--- "
	echo -e "-------------------- INSTALLATION DE ---------------------"
        echo -e "___  _  _ ____ ___  ____ ____ _  _ ___ _  _ ____ _  _ ____" 
	echo -e "|__] |  | |___ |  \ |__| |__/ |_/   |  |__| |___ |\/| |___" 
	echo -e "|     \/  |___ |__/ |  | |  \ | \_  |  |  | |___ |  | |___"                                                           
        echo -e " "                                                                
    fi
        if [ "$_silent" = false ]; then echo -e "${CHECKMARK} Sauvegarde du fichier de template"; fi
        cp $TEMPLATE_FILE $TEMPLATE_FILE.bak

        if [ "$_silent" = false ]; then echo -e "${CHECKMARK} Téléchargement de la feuille de style"; fi

        if [ "$OFFLINE" = false ]; then
            curl -s $BASE_URL/PVEDarkTheme/sass/PVEDarkTheme.css > /usr/share/pve-manager/css/dd_style.css
        else
            cp "$OFFLINEDIR/PVEDarkTheme/sass/PVEDarkTheme.css" /usr/share/pve-manager/css/dd_style.css
        fi

        if [ "$_silent" = false ]; then echo -e "${CHECKMARK} Téléchargement du patcher"; fi
        if [ "$OFFLINE" = false ]; then
            curl -s $BASE_URL/PVEDarkTheme/js/PVEDarkTheme.js > /usr/share/pve-manager/js/dd_patcher.js
        else
            cp "$OFFLINEDIR/PVEDarkTheme/js/PVEDarkTheme.js" /usr/share/pve-manager/js/dd_patcher.js
        fi

        if [ "$_silent" = false ]; then echo -e "${CHECKMARK} Application des changements au fichier de template"; fi
        if !(grep -Fq "<link rel='stylesheet' type='text/css' href='/pve2/css/dd_style.css'>" $TEMPLATE_FILE); then
            echo "<link rel='stylesheet' type='text/css' href='/pve2/css/dd_style.css'>" >> $TEMPLATE_FILE
        fi 
        if !(grep -Fq "<script type='text/javascript' src='/pve2/js/dd_patcher.js'></script>" $TEMPLATE_FILE); then
            echo "<script type='text/javascript' src='/pve2/js/dd_patcher.js'></script>" >> $TEMPLATE_FILE
        fi 

        if [ "$OFFLINE" = false ]; then
            local IMAGELIST=$(curl -f -s "$BASE_URL/meta/imagelist")
        else 
            local IMAGELIST=$(cat "$OFFLINEDIR/meta/imagelist")
        fi

        local IMAGELISTARR=($(echo "$IMAGELIST" | tr ',' '\n'))
        if [ "$_silent" = false ]; then echo -e "Téléchargement des images (0/${#IMAGELISTARR[@]})"; fi
        ITER=0
        for image in "${IMAGELISTARR[@]}"
        do
                if [ "$OFFLINE" = false ]; then
                    curl -s $BASE_URL/PVEDarkTheme/images/$image > /usr/share/pve-manager/images/$image
                else
                    cp "$OFFLINEDIR/PVEDarkTheme/images/$image" /usr/share/pve-manager/images/$image
                fi
                ((ITER++))
                if [ "$_silent" = false ]; then echo -e "\e[1A\e[KTéléchargement des images ($ITER/${#IMAGELISTARR[@]})"; fi
        done
        if [ "$_silent" = false ]; then echo -e "\e[1A\e[K${CHECKMARK} Téléchargement des images (${#IMAGELISTARR[@]}/${#IMAGELISTARR[@]})"; fi

        if [ "$_silent" = false ]; then echo -e "Thème installé - Veuillez raffraichir la page pour en profiter :-) "; fi
        if [ "$_noexit" = false ]; then exit 0; fi
    fi
}

function uninstall {
    if ! isInstalled; then
        echo -e "${RED}Theme non installé${REG}"
        exit 2
    else
    if [ "$_silent" = false ]; then
	echo -e ""
	echo -e "------------------ DESINSTALLATION DE --------------------"
        echo -e "___  _  _ ____ ___  ____ ____ _  _ ___ _  _ ____ _  _ ____" 
	echo -e "|__] |  | |___ |  \ |__| |__/ |_/   |  |__| |___ |\/| |___" 
	echo -e "|     \/  |___ |__/ |  | |  \ | \_  |  |  | |___ |  | |___"                                                           
        echo -e " "                                                                
    fi
        if [ "$_silent" = false ]; then echo -e "${CHECKMARK} Suppression de la feuille de style"; fi
        rm /usr/share/pve-manager/css/dd_style.css

        if [ "$_silent" = false ]; then echo -e "${CHECKMARK} Suppression du patcher"; fi
        rm /usr/share/pve-manager/js/dd_patcher.js

        if [ "$_silent" = false ]; then echo -e "${CHECKMARK} Retour en arriére sur les changements du fichier de template"; fi
        sed -i "/<link rel='stylesheet' type='text\/css' href='\/pve2\/css\/dd_style.css'>/d" /usr/share/pve-manager/index.html.tpl
        sed -i "/<script type='text\/javascript' src='\/pve2\/js\/dd_patcher.js'><\/script>/d" /usr/share/pve-manager/index.html.tpl

        if [ "$_silent" = false ]; then echo -e "${CHECKMARK} Suppression des images"; fi
        rm /usr/share/pve-manager/images/dd_*

        if [ "$_silent" = false ]; then echo -e "Thème désintallé - Veuillez raffraichir la page pour en profiter :-) "; fi
        if [ "$_noexit" = false ]; then exit 0; fi
    fi
}

#endregion Main functions

_silent=false
_command=false
_noexit=false

parse_cli()
{
	while test $# -gt -0
	do
		_key="$1"
		case "$_key" in
			-h|--help)
				usage
				exit 0
				;;
            -s|--silent)
                _silent=true
                ;;
            status) 
                if [ "$_command" = false ]; then
                    _command=true
                    status
                fi
                ;;
            install) 
                if [ "$_command" = false ]; then
                    _command=true
                    install
                    exit 0
                fi
                ;;
            uninstall)
                if [ "$_command" = false ]; then
                    _command=true
                    uninstall
                    exit 0
                fi
                ;;
            update)
                if [ "$_command" = false ]; then
                    _command=true
                    _noexit=true
                    uninstall
                    install
                    exit 0
                fi
                ;;
	     *)
				echo -e "${BRED}Erreur: Erreur inattendue \"$_key\"${REG}\n"; 
                usage;
                exit 1;
				;;
		esac
		shift
	done
}

parse_cli "$@"
