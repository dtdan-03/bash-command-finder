#!/bin/bash

function welcome() {
    echo "> Welcome to the Command Finder!"
    echo "> Help me narrow down the matching commands."
}

function collect_input() {
    echo -n "> How many characters does the command have? (Enter a number or press Enter for any length): "
    read length_input

    if [[ -n "$length_input" && ! "$length_input" =~ ^[0-9]+$ ]]; then
        echo "> Invalid input. Please enter numbers only or leave empty."
        collect_input
        return
    fi

    [[ -n "$length_input" ]] && echo "> Got it, expected length: $length_input" || echo "> No length restriction."

    echo -n "> Enter known letters separated by commas (example: a,b,c,x): "
    read letter_input
    letter_input=$(echo "$letter_input" | tr -d '[:space:]')
    IFS=',' read -r -a known_letters <<< "$letter_input"

    echo -n "> Enter letters to exclude, separated by commas (example: e,z,q), or press Enter for none: "
    read excluded_input
    excluded_input=$(echo "$excluded_input" | tr -d '[:space:]')
    IFS=',' read -r -a excluded_letters <<< "$excluded_input"

    echo -n "> Enter letters that must NOT be at certain positions, but must be included (format: r@2,p@1), or press Enter for none: "
    read misplaced_input
    misplaced_input=$(echo "$misplaced_input" | tr -d '[:space:]')
    IFS=',' read -r -a misplaced_letters <<< "$misplaced_input"

    position_letters=()
    if [[ -n "$length_input" ]]; then
        echo "> Enter known letters at specific positions (if any):"
        for ((i=1; i<=length_input; i++)); do
            echo -n "> Position $i: "
            read char
            if [[ -n "$char" ]]; then
                position_letters[$((i-1))]=$char
            else
                position_letters[$((i-1))]='_'
            fi
        done
    fi

    summary=""
    for ch in "${position_letters[@]}"; do
        summary+="$ch "
    done
    echo "> Your input: $summary  | included: ${known_letters[*]}  | excluded: ${excluded_letters[*]}  | must not be at: ${misplaced_letters[*]}"
    echo -n "> Confirm input (c) or re-enter (r)? "
    read confirm
    [[ "$confirm" == "r" ]] && collect_input
}

function find_matches() {
    mapfile -t all_cmds < <(compgen -c | sort -u)
    possible_cmds=()

    for cmd in "${all_cmds[@]}"; do
        # Check length
        [[ -n "$length_input" && "${#cmd}" -ne "$length_input" ]] && continue

        # Check fixed positions
        if [[ -n "$length_input" ]]; then
            mismatch=false
            for ((i=0; i<length_input; i++)); do
                [[ "${position_letters[$i]}" != "_" && "${cmd:$i:1}" != "${position_letters[$i]}" ]] && mismatch=true && break
            done
            $mismatch && continue
        fi

        # Check required letters
        for letter in "${known_letters[@]}"; do
            [[ -n "$letter" && "$cmd" != *"$letter"* ]] && continue 2
        done

        # Check excluded letters
        for bad in "${excluded_letters[@]}"; do
            [[ -n "$bad" && "$cmd" == *"$bad"* ]] && continue 2
        done

        # Check misplaced letters
        for entry in "${misplaced_letters[@]}"; do
            [[ "$entry" =~ ^([a-zA-Z])@([0-9]+)$ ]] || continue
            letter="${BASH_REMATCH[1]}"
            pos_index=$((BASH_REMATCH[2] - 1))
            [[ "$cmd" != *"$letter"* ]] && continue 2
            [[ "${cmd:$pos_index:1}" == "$letter" ]] && continue 2
        done

        possible_cmds+=("$cmd")
    done

    if [[ ${#possible_cmds[@]} -eq 0 ]]; then
        echo "> No matching commands found."
    else
        echo "> Matching commands:"
        printf '  - %s\n' "${possible_cmds[@]}"
    fi
}

function main() {
    while true; do
        welcome
        collect_input
        find_matches
        echo -n "> Do you want to refine further? (y/n): "
        read more
        if [[ "$more" != "y" ]]; then
            echo -n "> Start over? (y/n): "
            read restart
            [[ "$restart" == "y" ]] && continue || { echo "> Goodbye!"; break; }
        fi
    done
}

main
