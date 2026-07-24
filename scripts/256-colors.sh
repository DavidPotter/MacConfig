#!/bin/sh -e

for fgbg in 38 48 ; do # Foreground / Background
    for color in $(seq 0 255) ; do # Colors
        # Display the color
        printf "\033[${fgbg};5;%sm  %3s  \033[0m" $color $color
        # Display 6 colors per lines
        if [ $(((color + 1) % 6)) -eq 4 ] ; then
            echo # New line
        fi
    done
    echo # New line
done

exit 0
