#!/bin/bash
 
###
#   1.4 - 20/07/2015 - Maxime Viargues
#         Read the Perforce password from the keychain
#         Only display a message if an error occurs (removed timout)
#   1.3 - Released 11-01-2013 - jaime_rios
#         Updated shell script to work with Xcode5
#   1.2 - Released 9/27/2012 - tomahony
#         Updated to handle spaces in the folder/flle names
#   1.1 - Released 6/25/2012 - jhalbig
#
# A shell script for an Xcode 5 behavior to automatically check out a file
# whenever it is "unlocked" (made writable) in Xcode.
#
###

############ Put your personal settings here ############

# Create a Perforce password on your keychain, called "perforce"

P4USER=maxime.viargues
# Workspace of the current machine
P4CLIENT=MaximeViarguesMac
P4PORT=perforce:1666

#########################################################


# Get the Perforce password from the keychain. Returns the following line:
#password: "the password"
PASSWORD=`security 2>&1 > /dev/null find-generic-password -gl perforce`
if [[ $? -ne 0 ]]; then
    MSG="No Perforce password found, please add it to your keychain."
    echo $MSG
    export XC_RES=${MSG}
    osascript -e "tell application \"xcode\" to display dialog (system attribute \"XC_RES\") buttons {\"OK\"} default button 1"
    exit -1
fi

# remove 'password: "' (I'll assume it won't change anytime soon and use a hard coded string)
START_STRING="password: \""
START_LENGTH=${#START_STRING}
PASSWORD=${PASSWORD:START_LENGTH}
# remove the last quote
PASSWORD_LENGTH=${#PASSWORD}
PASSWORD_LENGTH=`expr $PASSWORD_LENGTH - 1`
PASSWORD=${PASSWORD:0:PASSWORD_LENGTH}

# set up Perforce
export P4PASSWD=$PASSWORD
export P4USER=$P4USER
export P4CLIENT=$P4CLIENT
export P4PORT=$P4PORT

 
fn=${XcodeAlertAffectedPaths}
fn=$(printf $(echo -n $fn | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g') )
 
# Get the enclosing directory for the file being unlocked:
fp=$(dirname "${fn}")
echo "fp=" ${fp}
 
# A check to confirm the current P4CONFIG setting:
conf=$(/usr/bin/p4 -d "${fp}" set P4CONFIG 2>&1)
echo ${conf}
 
if [ -a "${fn}" ]; then 
    # Check the file out from Perforce:
    res=$(/usr/bin/p4 -d "${fp}" edit "${fn}" 2>&1)
    res_code=$?
    echo "res=" ${res}
 
    if [ $res_code -ne 0 ]; then
        # Save the result as an environment variable
        export XC_RES="Failed to unlock: ${res}"
 
        # Tell Xcode to display a dialog to with the result of the command.
        osascript -e "tell application \"xcode\" to display dialog (system attribute \"XC_RES\") buttons {\"OK\"} default button 1"

        # relock the file if something wrong happened
        # This doesn't work as XCode unlocks the file after the script has been run
        exit -1
    fi
else
    echo "FnF" "${fn}"
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