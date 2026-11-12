#!/bin/bash

export MSYS=winsymlinks:nativestrict
export CHERE_INVOKING=1
export MSYS2_PATH_TYPE='inherit'
export MSYSTEM='UCRT64'
export MSYSCON='mintty.exe'

C:/msys64/usr/bin/mintty.exe -i 'C:/msys64/ucrt64.exe' -o 'AppLaunchCmd=C:/msys64/ucrt64.exe' -o 'AppID=MSYS2.Shell.UCRT64.9' -o 'AppName=MSYS2 UCRT64 Shell' -t 'MSYS2 UCRT64 Shell' --store-taskbar-properties -w max -- bash -lc "cd ~; tmux new -A -s main"
