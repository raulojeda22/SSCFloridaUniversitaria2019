#!/bin/bash
# Suponemos que los csv de entrada estan en el mismo directorio que el script

# genera un archivo temporal sin la cabezera, para tratar los datos sin alterar el contenido del csv original(se supone que se tienen permisos de escritura en el directorio actual)
cat games.csv | tail -n $(($(cat games.csv | wc -l)-1)) > tempfile.tmp

# saca los 5 campeones que han ganado cada partida para tener asi solo los ganadores
awk -F"," '{
    if ($5==1) 
        print $12,$15,$18,$21,$24
    else
        print $37,$40,$43,$46,$49
     
}' tempfile.tmp > champs.tmp

# recorre el fichero de campeones i va sumando las parejas
# el array siempre tiene el valor mas pequeño de la pareja a la izquierda para evitar repeticiones(p.e. array[13,25] y array[25,13] son la misma pareja)
awk '{
    for (i=1;i<=5;++i){
        for (j=i+1;j<=5;++j){
            if ($i < $j){
                array[$i,$j] += 1
            } else {
                array[$j,$i] += 1
            }
        }
    }
}
END{
    for (key in array){
        print key","array[key]
    }
}' champs.tmp | tr "" "," | sort -t"," -k3 -nr | head > tenpairs.tmp

# substitucion de IDs por nombres
awk  -F, '{gsub(/\r/,"")} NR==FNR{a[$1]=$2;next}{print a[$1]","a[$2]","$3}' champions.csv tenpairs.tmp > result.csv

rm *.tmp