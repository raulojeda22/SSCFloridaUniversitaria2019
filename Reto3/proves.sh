#!/bin/bash
gameFile='games.csv'
games=$(cat games.csv | cut -d"," -f5,12,15,18,21,24,37,40,43,46,49 | tail -n+2)  #Carga los campos importantes para calcular las mejores parejas
winners1=$(echo "$games" | tr " " "\n" | grep ^1, | cut -d"," -f2,3,4,5,6 ) #Coge los campeones ganadores en el equipo 1
winners2=$(echo "$games" | tr " " "\n" | grep ^2, | cut -d"," -f7- ) #Coge los campeones ganadores en el equipo 2
winners="$winners1 $winners2" #Agrupar ganadores
