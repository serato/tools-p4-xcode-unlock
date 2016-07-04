#!/bin/bash
 
###
#   1.5 - 04/07/2016 - Maxime Viargues
#         Fixed hang on Xcode 7.
#         Allow to not have a password in the keychain.
#         Added logging to a tmp folder.
#   1.4 - 20/07/2015 - Maxime Viargues
#         Read the Perforce password from the keychain
#         Only display a message if an error occurs (removed timout)
#   1.3 - Released 11-01-2013 - jaime_rios
#         Updated shell script to work with Xcode5
#   1.2 - Released 9/27/2012 - tomahony
#         Updated to handle spaces in the folder/flle names
#   1.1 - Released 6/25/2012 - jhalbig
#
# A shell script for an Xcode behavior to automatically check out a file
# whenever it is "unlocked" (made writable) in Xcode.
#
###

############ Put your personal settings here ############

# TODO for you:
# Set those constants with your details unless your P4 environment variables
# are already set, i.e. P4USER, P4PORT, P4CLIENT
# To login automatically, create a Perforce password on your keychain, called "perforce",
# otherwise you have to be logged in Perforce before unlocking.

# Your Perforce user name
readonly USER_NAME=maxime.viargues
# Workspace of the current machine
readonly WORKSPACE=maxime.viargues_MacBook-Pro13
# Perforce server and port
readonly P4_SERVER=perforce:1666

# Logging output file
readonly LOG_FILE='/tmp/xcode_unlock.log'
# Set to 1 to log more info
readonly DEBUG_LOG=1

#########################################################

if [[ -f $LOG_FILE ]]; then
	rm $LOG_FILE
fi

function log
{
	echo $@
	echo $@ >> $LOG_FILE
}

function dlog
# Debug logging
{
    if [[ ${DEBUG_LOG} -eq 1 ]]; then
        log "DEBUG: $@"
    fi
}

function show_error
{
    log "ERROR: $@"
    # This freezes Xcode 7 so I disabled it
    #old version: osascript -e "tell application \"xcode\" to display dialog (system attribute \"XC_RES\") buttons {\"OK\"} default button 1"
}

#########################################################

# Get the Perforce password from the keychain. Returns the following line:
#password: "the password"
dlog "getting password..."
PASSWORD=`security 2>&1 > /dev/null find-generic-password -gl perforce`
if [[ $? -ne 0 ]]; then
    show_error "No Perforce password found, please add it to your keychain."
    log "Trying to use p4 without password"
    #exit -1
else
    # remove 'password: "' (I'll assume it won't change anytime soon and use a hard coded string)
    START_STRING="password: \""
    START_LENGTH=${#START_STRING}
    PASSWORD=${PASSWORD:START_LENGTH}
    # remove the last quote
    PASSWORD_LENGTH=${#PASSWORD}
    PASSWORD_LENGTH=`expr $PASSWORD_LENGTH - 1`
    PASSWORD=${PASSWORD:0:PASSWORD_LENGTH}

    export P4PASSWD=$PASSWORD
    dlog "got it!"
fi

# set up Perforce
if [[ -z ${P4USER} ]]; then
    export P4USER=${USER_NAME}
fi
if [[ -z ${P4CLIENT} ]]; then
    export P4CLIENT=${WORKSPACE}
fi
if [[ -z ${P4PORT} ]]; then
    export P4PORT=${P4_SERVER}
fi

# Check for p4 command
dlog "Checking p4..."
which p4
if [[ $? -ne 0 ]]; then
    show_error "p4 command not found, make sure it's in your bin or PATH"
    exit 1
fi
dlog "p4 found"

dlog "Getting affected files and paths..."
fn=${XcodeAlertAffectedPaths}
fn=$(printf $(echo -n $fn | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g') )
 
# Get the enclosing directory for the file being unlocked:
fp=$(dirname "${fn}")
dlog "working directory: " ${fp}
 
# A check to confirm the current P4CONFIG setting:
conf=$(p4 -d "${fp}" set P4CONFIG 2>&1)
 
if [ -a "${fn}" ]; then 
    # Check the file out from Perforce:
    dlog "Checking out ${fn}"
    res=$(p4 -d "${fp}" edit "${fn}" 2>&1)
    res_code=$?
    log "p4 edit ouput: ${res}"
 
    if [ $res_code -ne 0 ]; then
        show_error "Failed to unlock: ${res}"

        # relock the file if something wrong happened
        # This doesn't work as XCode unlocks the file after the script has been run
        exit -1
    fi
else
    log "FnF" "${fn}"
fi



###
# Copyright (c) Perforce Software, Inc., 1997-2012. All rights reserved
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the 
# documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE
# SOFTWARE, INC. BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.