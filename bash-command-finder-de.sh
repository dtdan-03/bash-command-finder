#!/bin/bash

function welcome() {
    echo "> Willkommen beim Befehlsfinder!"
    echo "> Hilf mir mit deinem Input, die Befehle zu finden."
}

function collect_input() {
    echo -n "> Wie viele Zeichen hat dein Befehl? (Gebe einen Wert ein oder Enter für beliebig): "
    read length_input

    if [[ -n "$length_input" && ! "$length_input" =~ ^[0-9]+$ ]]; then
        echo "> Ungültige Eingabe. Bitte nur Zahlen oder Enter."
        collect_input
        return
    fi

    [[ -n "$length_input" ]] && echo "> Alles klar, die Anzahl der Zeichen lautet: $length_input" || echo "> Keine Längenbeschränkung aktiviert."

    echo -n "> Füge mit Komma getrennt bekannte Buchstaben ein (Beispiel: a,b,c,x): "
    read letter_input
    letter_input=$(echo "$letter_input" | tr -d '[:space:]')
    IFS=',' read -r -a known_letters <<< "$letter_input"

    echo -n "> Füge mit Komma getrennt **auszuschließende** Buchstaben ein (Beispiel: e,z,q), oder Enter für keine: "
    read excluded_input
    excluded_input=$(echo "$excluded_input" | tr -d '[:space:]')
    IFS=',' read -r -a excluded_letters <<< "$excluded_input"

    echo -n "> Füge Buchstaben ein, die **nicht an bestimmten Positionen stehen dürfen**, aber enthalten sind (Format: r@2,p@1), Enter für keine: "
    read misplaced_input
    misplaced_input=$(echo "$misplaced_input" | tr -d '[:space:]')
    IFS=',' read -r -a misplaced_letters <<< "$misplaced_input"

    position_letters=()
    if [[ -n "$length_input" ]]; then
        echo "> Gib bekannte Buchstaben an bestimmten Positionen ein (falls bekannt):"
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
    echo "> Deine Eingabe lautet: $summary  | enthalten: ${known_letters[*]}  | ausgeschlossen: ${excluded_letters[*]}  | enthalten, aber nicht an Position: ${misplaced_letters[*]}"
    echo -n "> Ist die Eingabe korrekt (k) oder soll sie wiederholt werden (w)? "
    read confirm
    [[ "$confirm" == "w" ]] && collect_input
}

function find_matches() {
    mapfile -t all_cmds < <(compgen -c | sort -u)
    possible_cmds=()

    for cmd in "${all_cmds[@]}"; do
        # Länge
        [[ -n "$length_input" && "${#cmd}" -ne "$length_input" ]] && continue

        # Feste Positionen
        if [[ -n "$length_input" ]]; then
            mismatch=false
            for ((i=0; i<length_input; i++)); do
                [[ "${position_letters[$i]}" != "_" && "${cmd:$i:1}" != "${position_letters[$i]}" ]] && mismatch=true && break
            done
            $mismatch && continue
        fi

        # Buchstaben, die enthalten sein müssen
        for letter in "${known_letters[@]}"; do
            [[ -n "$letter" && "$cmd" != *"$letter"* ]] && continue 2
        done

        # Buchstaben, die **nicht enthalten** sein dürfen
        for bad in "${excluded_letters[@]}"; do
            [[ -n "$bad" && "$cmd" == *"$bad"* ]] && continue 2
        done

        # Buchstaben, die **enthalten sein müssen**, aber **nicht an einer bestimmten Position**
        for entry in "${misplaced_letters[@]}"; do
            [[ "$entry" =~ ^([a-zA-Z])@([0-9]+)$ ]] || continue
            letter="${BASH_REMATCH[1]}"
            pos_index=$((BASH_REMATCH[2] - 1))
            # Muss enthalten sein
            [[ "$cmd" != *"$letter"* ]] && continue 2
            # Aber NICHT an genau dieser Position
            [[ "${cmd:$pos_index:1}" == "$letter" ]] && continue 2
        done

        possible_cmds+=("$cmd")
    done

    if [[ ${#possible_cmds[@]} -eq 0 ]]; then
        echo "> Keine passenden Befehle gefunden."
    else
        echo "> Mögliche Kombinationen:"
        printf '  - %s\n' "${possible_cmds[@]}"
    fi
}

function main() {
    while true; do
        welcome
        collect_input
        find_matches
        echo -n "> Weitere Hinweise eingeben? (y/n): "
        read more
        if [[ "$more" != "y" ]]; then
            echo -n "> Befehlsfinder neu starten? (y/n): "
            read restart
            [[ "$restart" == "y" ]] && continue || { echo "> Auf Wiedersehen!"; break; }
        fi
    done
}

main
