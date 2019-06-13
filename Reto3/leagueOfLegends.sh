#!/bin/bash
gameFile='games.csv'
championsFile='champions.csv'
resultsFile='result.csv'
games=$(cat games.csv | cut -d"," -f5,12,15,18,21,24,37,40,43,46,49 | tail -n+2)  #Carga los campos importantes para calcular las mejores parejas
winners1=$(echo "$games" | tr " " "\n" | grep ^1, | cut -d"," -f2,3,4,5,6 ) #Coge los campeones ganadores en el equipo 1
winners2=$(echo "$games" | tr " " "\n" | grep ^2, | cut -d"," -f7- ) #Coge los campeones ganadores en el equipo 2
winners="$winners1 $winners2" #Agrupar ganadores
#El comando siguiente agrupa las mejores parejas de campeones con el siguiente algoritmo:
#1. De cada equipo ganador crea todas las posibles combinaciones de campeones sin repetir
#2. Pone el id de campeón menor primero para que todas las parejas coincidan de orden
#3. Cuenta las veces que se repite cada pareja, las ordena numéricamente y corta la salida en 10 campos
bestCouples=$(echo "$winners" | tr " " "\n" | awk 'BEGIN{FS=OFS=","} { print $1"-"$2,$1"-"$3,$1"-"$4,$1"-"$5,$2"-"$3,$2"-"$4,$2"-"$5,$3"-"$4,$3"-"$5,$4"-"$5 }' | tr ",-" "\n," | awk 'BEGIN{FS=OFS=","} {if ($1 < $2)print $1,$2;else print $2,$1;}' | awk 'BEGIN{OFS=","} { a[$1]++ }END{ for(i in a) print a[i],i }' | sort -nrk1 | head)
echo -n '' > $resultsFile #Limpia el archivo de resultados
for champs in $bestCouples #Por cada pareja
do
    firstChamp=$(cat "$championsFile" | grep ^$(echo "$champs" | cut -d"," -f2), | cut -d"," -f2 ) #Obtener nombre del campeón por su id
    secondChamp=$(cat "$championsFile" | grep ^$(echo "$champs" | cut -d"," -f3), | cut -d"," -f2 )
    total=$(echo -n "$champs" | cut -d"," -f1) #Total de veces ganadas
    echo "$firstChamp,$secondChamp,$total" | tr -d '\015' >> $resultsFile #Cargar resultados en archivo
done