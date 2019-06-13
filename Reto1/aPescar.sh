#!/bin/bash
##FUNCIONES##
MOSTRAR_BANNER(){
    echo '    _     ___  ___  ___   ___    _    ___  _ 
   /_\   | _ \| __|/ __| / __|  /_\  | _ \| |
  / _ \  |  _/| _| \__ \| (__  / _ \ |   /|_|
 /_/ \_\ |_|  |___||___/ \___|/_/ \_\|_|_\(_)
'
}

MOSTRAR_MESA(){
    clear
    MOSTRAR_BANNER
    echo "Oponente: $mensaje1" | tr "_" " "
    echo "               _____
              |     |
              | | | |
              |_____|
        ____ ___|_|___ ____
       ()___)         ()___)
       // /|           | \ \\\\
     (___) |___________| (___) Oponente - Cartas: ${#cartas1[@]}, Grupos: [ ${grupos1[*]} ]
     .-------------------------.
   .'$ganador ${cartas0[*]}                         
 .'-------------------------------'.
 '.................................' Cartas Mazo: ${#totalCartas[@]}
   \   _______________________   /
    | |_)                   (_| | 
    | |                       | | Usuario - Cartas: ${#cartas0[*]}, Grupos: [ ${grupos0[*]} ]
   (___)                     (___)"
    echo "Usuario: $mensaje0" | tr "_" " "
}

PARTIDA(){
    BARAJAR_CARTAS
    REPARTIR_CARTAS
    partida=0
    while [ $partida -eq 0 ] #La partida acaba cuando no quedan cartas ni en la mano ni en la pila
    do
        solicitante=0
        while [ "$solicitante" -lt "$jugadores" ] #Se ejecuta una vez por jugador, si el jugador acierta carta, repite turno
        do  
            oponente=$(( 1-solicitante ))
            MOSTRAR_MESA
            sleep 1
            TURNO_$solicitante
            if [ "$acertarCartaOponente" -eq 0 ] #Si no ha acertado la carta
            then                                
                eval mensaje$oponente='No._A_pescar!' #Establecer mensajes de solicitante y oponente dinámicamente
                eval mensaje$solicitante=""
                totalCartas=(${totalCartas[@]:0:$posicionCarta} ${totalCartas[@]:$((posicionCarta + 1))})  
                ((solicitante++))
            elif [ "$acertarCartaOponente" -eq 2 ] #Si no quedan cartas en la pila
            then
                ((solicitante++))
            else #Si acierta la carta
                eval mensaje$oponente='Sí'
                eval mensaje$solicitante=""
            fi
            sleep 1
            if [ ${#totalCartas[@]} -eq 0 ] && [ ${#cartas0[@]} -eq 0 ] && [ ${#cartas1[@]} -eq 0 ] #Condiciones fin de partida
            then
                partida=1
                break
            fi
        done
    done
    CALCULAR_GANADOR
    MOSTRAR_MESA
    sleep 5
}

TURNO_0(){ #Turno del USUARIO
    if [ ${#cartas1} -ne 0 ] #Si el contrincante tiene cartas
    then
        isNotValidNumber=0
        while [ $isNotValidNumber -eq 0 ] #Comprovación de número válido
        do
            read -r -p "Tienes algún... ?(Número): " numeroCarta
            if [[ $numeroCarta =~ $validNumberRegex ]]
            then
               isNotValidNumber=1
            else
                echo "Introduce un número válido..."
            fi
        done
    else #Si el contrincante no tiene cartas
        echo "Como no tienes cartas, te importa que coja del mazo?"
        numeroCarta=0 #Utilizo la carta 0 porque no existe esa carta por lo que irá a coger del mazo
    fi
    pescar=$(PESCAR_CARTA $numeroCarta "${cartas1[@]}") #Pescar carta por parte del usuario, se buscará el número de carta en las cartas del contrincante
    if [ $? -ne 1 ] #Comprobar si se ha robado una carta con éxito
    then
        posicionCarta=$(echo "$pescar" | cut -d" " -f1) #Para quitar cartas del total en PARTIDA
        cartaPescada=$(echo "$pescar" | cut -d" " -f2) #Para añadir cartas al mazo del usuario
        acertarCartaOponente=$(echo "$pescar" | cut -d" " -f3) #Establecer si ha pescado la carta satisfactóriamente o no
        cartas1=( $(echo "$pescar" | cut -d" " -f 4-) ) #Array con las cartas que le quedan a la máquina
        cartas0+=( $(echo "$cartaPescada" | tr ":" " " ) ) #Añadir cartas al usuario
        nuevoGrupo=$(COMPROBAR_GRUPOS "${cartas0[@]}") #Comprobar si se ha formado un nuevo grupo con los últimos movimientos del usuario
        if [ "$nuevoGrupo" != "" ]
        then
            cartas0=( $(QUITAR_GRUPOS_CARTAS "$nuevoGrupo" "${cartas0[@]}") ) #Quitar las 4 cartas del grupo de la mano del usuario
            grupos0+=( "$nuevoGrupo" ) #Añadir el grupo a la array de grupos del usuario
        fi
    else #Si no quedan cartas en la pila
        acertarCartaOponente=2 
        mensaje0="No puedo pescar cartas del mazo porque no quedan"
    fi
}

TURNO_1(){ #Turno del OPONENTE
    numeroCarta=$(CALCULAR_MEJOR_CARTA) #Calcular la carta que solicitará la máquina
    if [ ${#cartas0} -ne 0 ] #Si el usuario tiene alguna carta
    then
        mensaje1="Tienes_algún_$numeroCarta?"
        mensaje0=""
    else #Si el usuario no tiene cartas
        mensaje1="Como no tienes cartas, te importa que coja del mazo?"
        numeroCarta=0 #Utilizo la carta 0 porque no existe esa carta por lo que irá a coger del mazo
    fi
    MOSTRAR_MESA
    sleep 1
    pescar=$(PESCAR_CARTA $numeroCarta "${cartas0[@]}")
    if [ $? -ne 1 ] #Comprobar si se ha robado una carta con éxito
    then
        posicionCarta=$(echo "$pescar" | cut -d" " -f1) #Para quitar cartas del total en PARTIDA
        cartaPescada=$(echo "$pescar" | cut -d" " -f2) #Para añadir cartas al mazo de la máquina
        acertarCartaOponente=$(echo "$pescar" | cut -d" " -f3) #Establecer si ha pescado la carta satisfactóriamente o no
        cartas0=( $(echo "$pescar" | cut -d" " -f 4-) ) #Array con las cartas que le quedan al usuario
        cartas1+=( $(echo "$cartaPescada" | tr ":" " " ) ) #Añadir cartas a la máquina
        nuevoGrupo=$(COMPROBAR_GRUPOS "${cartas1[@]}") #Comprobar si se ha formado un nuevo grupo con los últimos movimientos de la máquina
        if [ "$nuevoGrupo" != "" ] #Si ha detectado un nuevo grupo
        then
            cartas1=( $(QUITAR_GRUPOS_CARTAS "$nuevoGrupo" "${cartas1[@]}") ) #Quitar las 4 cartas del grupo de la mano de la máquina
            grupos1+=( "$nuevoGrupo" ) #Añadir el grupo a la array de grupos de la máquina
        fi
    else #Si no quedan cartas en la pila
        acertarCartaOponente=2
        mensaje1="No puedo pescar cartas del mazo porque no quedan"
    fi
}

PESCAR_CARTA(){ 
    pescarCarta=$1 #Número de la carta que se desea pescar
    shift #Eliminar primer parámetro de la función
    cartasObjetivo=( "$@" ) #Cartas en las que se va a pescar
    cartasPescadas=""
    posicionCartas=""
    contador=0
    if [ ${#cartasObjetivo[@]} -ne 0 ] #Si el objetivo tiene cartas en la mano
    then
        while [ $contador -lt ${#cartasObjetivo[@]} ] #Buscar si la carta está en la mano y cuantas veces
        do
            if [ "$pescarCarta" -eq "$(echo ${cartasObjetivo[$contador]} | cut -d"-" -f1)" ]
            then
                posicionCartas=$contador":"$posicionCartas #Añadir posicion a la string de posiciones
                cartasPescadas=$cartasPescadas":"${cartasObjetivo[$contador]} #Añadir carta a la string de cartas
            fi
            ((contador++))
        done
    fi
    if [ "$posicionCartas" != "" ] #Si se ha detectado la carta en la mano
    then
        acertarCartaOponente=1
        for posicionCarta in $(echo $posicionCartas | tr ":" " " )
        do
            cartasObjetivo=( ${cartasObjetivo[@]:0:$posicionCarta} ${cartasObjetivo[@]:$(($posicionCarta + 1))} ) #Eliminar cartas robadas de la mano objetivo
        done
    else #Si no se ha detectado la carta en la mano
        acertarCartaOponente=0
        pescarMazo=$(PESCAR_CARTA_MAZO) #Si no se ha acertado la carta se recoje una del mazo
        if [ $? -ne 1 ] #Si se ha recogido la carta del mazo satisfactoriamente
        then
            posicionCartas=$(echo "$pescarMazo" | cut -d" " -f1)
            cartasPescadas=$(echo "$pescarMazo" | cut -d" " -f2)
        else #Si no, devuelve error
            return 1
        fi
    fi
    echo "$posicionCartas" "$cartasPescadas" "$acertarCartaOponente" "${cartasObjetivo[@]}" #Devolver las variables y la array del objetivo modificada
}

PESCAR_CARTA_MAZO(){ #Coger carta aleatória del mazo
    if [ ${#totalCartas[@]} -ne 0 ]
    then
        posicionElegida=$(( RANDOM % ${#totalCartas[@]} ))
        cartaElegida=${totalCartas[$posicionElegida]}
        echo "$posicionElegida" "$cartaElegida"
    else
        return 1
    fi
}

CALCULAR_MEJOR_CARTA(){ #La máquina escogerá una carta aleatoria que no haya sido agrupada ya
    numeroNoAgrupado=0
    while [ $numeroNoAgrupado -eq 0 ]
    do
        numeroCarta=$(( (RANDOM % limiteCartas) + 1  )) #Numero aleatorio entre el limite de cartas y 1
        grupos=( ${grupos0[@]} ${grupos1[@]} ) #Juntar las dos arrays de los grupos de cartas en 1
        if [ ${#grupos[@]} -ne 0 ]
        then
            for grupo in "${grupos[@]}" #Comprobar si la carta aleatoria ya se encuentra entre los grupos
            do
                if [ "$numeroCarta" -eq "$grupo" ] #Si ha sido agrupada ya, se volverá a ejecutar el bucle hasta que se encuentre una carta no agrupada
                then
                    numeroNoAgrupado=0
                    break
                else
                    numeroNoAgrupado=1
                fi
            done
        else
            numeroNoAgrupado=1
        fi
    done
    echo $numeroCarta #Devolver numero de carta escogido
}

COMPROBAR_GRUPOS(){ #Comprobar si las cartas de una mano tienen 4 numeros que se repitan y devolverlos
    agruparCartas=""
    for carta in "$@"
    do
        agruparCartas="$agruparCartas $(echo "$carta" | cut -d'-' -f1)" #Quitar la parte no numérica de las cartas
    done
    echo "$agruparCartas" | tr " " "\n" | sort | uniq -c | sort -nr -k1 | sed -e 's/^[ \t]*//' | grep -w "^4" | tr -s " " " " | cut -d" " -f2  
}

QUITAR_GRUPOS_CARTAS(){ #Quitar 4 cartas de una mano para formar un grupo
    grupo=$1 #El numero que forma el grupo
    shift
    cartas=( $@ ) #Todas las cartas de la mano
    posicionCartas=""
    contador=0
    while [ $contador -lt ${#cartas[@]} ]
    do
        if [ "$(echo "$grupo" | cut -d"-" -f1)" -eq "$(echo "${cartas[$contador]}" | cut -d"-" -f1)" ] #Si el numero del grupo coincide con la carta
        then
            posicionCartas=$contador":"$posicionCartas #Se añade a la string de posiciones en la array de la mano
        fi
        ((contador++))
    done
    for posicionCarta in $(echo $posicionCartas | tr ":" " " ) #Por cada posición en la mano
    do
        cartas=( ${cartas[@]:0:$posicionCarta} ${cartas[@]:$((posicionCarta + 1))} ) #Que quite esa carta de la mano
    done
    echo "${cartas[@]}" #Devolver la nueva array con las cartas quitadas
}

CALCULAR_GANADOR(){ #Comprobar que jugador tiene más grupos formados
    if [ ${#grupos0[@]} -gt ${#grupos1[@]} ]
    then
        ganador="Has ganado!"
    elif [ ${#grupos0[@]} -lt ${#grupos1[@]} ]
    then
        ganador="Has perdido!"
    else
        ganador="Habeis empatado!"
    fi
}

REPARTIR_CARTAS(){
    contador=0
    while [ $contador -lt $jugadores ] #Se ejecutará una vez por jugador
    do
        contadorCartas=0
        limiteCartasJugador=7
        while [ $contadorCartas -lt $limiteCartasJugador ] #Por cada carta que se tenga que repartir por jugador
        do
            elegida=$(( RANDOM % ${#totalCartas[@]} )) #Asignar carta aleatória de la baraja
            eval cartas$contador[$contadorCartas]=${totalCartas[$elegida]} #Asignar carta en la array de cartas del jugador
            totalCartas=(${totalCartas[@]:0:$elegida} ${totalCartas[@]:$(($elegida + 1))})  #Quitar carta seleccionada del total
            ((contadorCartas++))
        done
        ((contador++))
    done
}

GENERAR_CARTAS(){
    palos=( O E C B )
    for palo in "${palos[@]}" #Se ejecuta una vez por palo: Oros Espadas Copas y Bastos
    do
        contadorCartas=1
        limiteCartas=12
        while [ $contadorCartas -le $limiteCartas ] #Crear cartas
        do
            totalCartas+=("$contadorCartas-$palo") #Añadir carta a la array de cartas
            ((contadorCartas++))
        done
    done
}

BARAJAR_CARTAS() {
   totalCartas=( $(shuf -e "${totalCartas[@]}") ) #Desordenar array de cartas
}

##VARIABLES##
salir=0
jugadores=2 #Hay 2 jugadores en la partida
validNumberRegex='^[1-9][0-9]?$|^100$' #Solo se aceptan numeros del 1 al 100
#Aclaración: Todas las variables y arrays con un 0 detrás pertenecen al usuario y todas las que tienen un 1 pertenecen a la máquina
#E.g.: ${cartas0[@]} Son las cartas en la mano del usuario
#Las cartas tienen el formato <numero>-<palo> (1 2 3 4 5 6 7 8 9 10 11 12)-(O E B C). Los palos son Oros Espadas Bastos y Copas.

##MENU##
while [ $salir -eq 0 ]
do
    totalCartas=() #Variables de la partida
    grupos0=()
    grupos1=()
    mensaje0=""
    mensaje1=""
    ganador=""
    acertarCartaOponente=0
    clear
    MOSTRAR_BANNER
    GENERAR_CARTAS
    echo "1.Empezar partida"
    echo "2.Salir"
    echo ""
    read -r -p "¿Qué desea hacer?(Número): " eleccion
    case $eleccion in
        1)  PARTIDA ;;
        2)  salir=1 ;;
        *)  read -r -p "Introducción errónea"    ;;
    esac
done
echo "Hasta la próxima!"