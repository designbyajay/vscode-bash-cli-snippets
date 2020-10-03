#!/bin/bash
#------------- Cleanup -------------

# This section contains all of the logic needed to return the environment to its previous state upon exiting. The reason the cleanup function is first in this script is because it needs to run, even if the script is killed before the shell has a chance to execute each line.

clean-up () {

    if [ "$SCRIPT_IS_DONE" -eq 0 ] # If unclean exit, run all commands in SCRIPT_UNDO ↓ in the reverse order that they were added to the array in.
    then
        for (( i=${#SCRIPT_UNDO[@]} ; i>0 ; i-- ))
        do
            INDEX=$(( $i-1 ))
            ${SCRIPT_UNDO[$INDEX]}
        done
    fi

    #Unset all variables that you made while the script was running ↓
    unset PUBLISHER_TO_USE    # ← unset your variables here.

}

trap clean-up EXIT #this runs the "clean-up" function ↑ before exiting this script

#------------ Variables -------------

SCRIPT_IS_DONE=0
PUBLISHER_TO_USE=

#--------- Helper Functions ---------

# This section contains all of repeated pieces of logic needed to run the "Main Script" ↓. Helper functions abstract away repeated subroutines and frequently-used branches of execution. If you find yourself copying-and-pasting one or more instructions, put them in a function so that your code doesn't turn into copypasta.


check-os () {

    which sw_vers &>/dev/null
    if [ $? -eq 0 ]; then
        MACOS_VERSION=$(sw_vers -productVersion)
        sw_vers -productVersion | grep 10.15 &>/dev/null
        if [ $? -eq 0 ]; then
            printf "\nYou are running \e[1mMacOS 10.15\e[0m" | fold -w $(tput cols) 1>&2
        else
            printf "\nSorry, you are not running \e[1mMacOS 10.15\e[0m. This script is not designed to work with other versions of MacOS\n" | fold -w $(tput cols) 1>&2
            exit 1 #catchall
        fi
        
    else
        printf "\nIt doesn't look like you are on MacOS. I can tell because the command \e[38;5;0m\e[48;5;220mwhich sw_vers\e[0m does not return \e[1m/usr/bin/sw_vers\e[0m. This script can only be run on MacOS." | fold -w $(tput cols) 1>&2
        exit 1 #catchall
    fi

}

check-node-installed () {

    node -v &>/dev/null
    if [ $? -eq 0 ]; then
        printf "\n\e[1mNode\e[0m is installed." | fold -w $(tput cols) 1>&2
    else
        printf "\nSorry, \e[1mnode\e[0m is not installed, so I cannot run the rest of this script. Please go to \e[1mhttps://nodejs.org/en/\e[0m and install it. Then re-run this script." | fold -w $(tput cols) 1>&2
    fi

}


check-npm-installed () {

    npm -v &>/dev/null
    if [ $? -eq 0 ]; then
        printf "\n\e[1mNPM\e[0m is installed." | fold -w $(tput cols) 1>&2
    else
        printf "\nSorry, \e[1mNPM\e[0m is not installed, so I cannot run the rest of this script. Please go to \e[1mhttps://nodejs.org/en/\e[0m and install it. Then re-run this script." | fold -w $(tput cols) 1>&2
    fi

}

install-vsce () {
    which vsce &>/dev/null
    if [ $? -ne 0 ]; then
        npm install -g vsce
    fi
}


get-package-publisher () {

 PUBLISHER_TO_USE=$(grep publisher package.json | awk 'BEGIN {FS = ":"} ;{print $2}' | tr -d '",\,[:blank:]')

}

print-log-into-publisher-message-and-exit () {
    printf "\n\nPlease log in to the \e[1mVScode extension marketplace\e[0m with \e[38;5;0m\e[48;5;220mvsce login $PUBLISHER_TO_USE\e[0m. Make sure you have the \e[1mpersonal access token\e[0m for \e[1m$PUBLISHER_TO_USE\e[0m handy.\n\nFor more information on publishers, see \n\e[1mhttps://code.visualstudio.com/api/working-with-extensions/publishing-extension#create-a-publisher\e[0m.\n\nFor more information on creating a \e[1mpersonal access token\e[0m see \n\e[1mhttps://code.visualstudio.com/api/working-with-extensions/publishing-extension#get-a-personal-access-token\e[0m" | fold -w $(tput cols) 1>&2
    exit 1

}

check-vsce-publishers () {

    #---- Local Variables ----

    PUBLISHERS=($(vsce ls-publishers))

    #---- Function Logic ----
    
    
    if [ ${#PUBLISHERS[@]} -eq 0 ]
    then
        print-log-into-publisher-message-and-exit
    fi
    

    for PUBLISHER in ${PUBLISHERS[@]}
    do
        
        if [ $PUBLISHER_TO_USE == $PUBLISHER ]
        then
            break;
        else
            print-log-into-publisher-message-and-exit
        fi
        
    done
    
    unset $PUBLISHERS

}


increment-version-and-publish () {

printf "\n\nDo you want to publish a major version release, a minor version release or a patch?\n" | fold -w $(tput cols) 1>&2

PS3_OLD=PS3 # This preserves whatever the value of the bash builtin environment variable PS3 was.
PS3=$'\n'"pick option 1, 2 or 3: "

select VERSION in "major" "minor" "patch";    # ← the first argument should be a variable name for an item, and the second argument should be an array of items
do
    
    case $VERSION in
        "major" )
            vsce publish major
            break
        ;;    
        "minor" )
            vsce publish minor
            break
        ;;
        *) # This catches all cases that weren't previously listed. That's why it has the wildcard "*" operator.
            vsce publish patch
            break
        ;;
    esac
    
done
PS3=$PS3_OLD
unset PS3_OLD

}


#----------- Main Script -----------

# This section contains the script that will actually run. The reason this section is last in this file is because this script references all of the above variables and helper functions. Shells execute scripts one line at a time, and they don't hoist variables and function definitions prior to execution.

    # ← put your script's logic here.
    check-os
    check-node-installed
    check-npm-installed
    install-vsce
    get-package-publisher
    check-vsce-publishers
    increment-version-and-publish

SCRIPT_IS_DONE=1 # DO NOT DELETE THIS LINE ... the "clean-up" function ↑ needs it in order to know whether or not it should undo changes made by this script.