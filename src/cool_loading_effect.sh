#!/bin/bash

echo -n "[                    ]"  # Initial empty bar
symbols=("#" "=" "o")  # Fun ASCII symbols to use

for i in {1..20}; do
    sleep 0.1  # Smooth animation speed
    echo -ne "\r["
    for j in $(seq 1 $i); do
        if [[ $j -eq $i ]]; then
            echo -n "${symbols[i % ${#symbols[@]}]}"  # Rotate through symbols
        else
            echo -n "="  # Consistent fill symbol
        fi
    done
    for j in $(seq $i 20); do
        echo -n " "  # Empty space
    done
    echo -n "]"
done

echo -e "\nDone!"
