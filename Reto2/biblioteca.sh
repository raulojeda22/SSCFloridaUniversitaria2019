#!/bin/bash
###FUNCIONES###
MOSTRAR_BANNER() {
    echo "BIBLIOTECA"
}

MOSTRAR_OPCIONES() {
    echo "1.Gestión libros
2.Gestión usuarios
3.Gestión préstamos
4.Salir"
}

MOSTRAR_OPCIONES_OBJETO() {
    echo "${opcionesGestion[$opcion]}" | tr "_" " "
    echo "1.Alta
2.Baja
3.Consulta
4.Salir"
}

MOSTRAR_OPCIONES_PRESTAMO() {
    echo "${opcionesGestion[$opcion]}" | tr "_" " "
    echo "1.Alta
2.Baja
3.Listado
4.Consulta
5.Salir"
}

CARGAR_CONFIGURACION(){
    todosCampos=( $(echo "${!variableArchivo}" | tr "," " ") ) #Extraer todos los campos                  
    campos=( $(echo "${!variableArchivo}" | cut -d"," -f 2- | rev | cut -d',' -f2- | rev | tr "," " ") ) #Extraer solo los campos del Alta
    camposConsulta=( "${todosCampos[0]}" "${campos[0]}" ) #Extraer los campos que serviran para la consulta
}

CARGAR_CONFIGURACION_PRESTAMO(){
    todosCampos=( $(echo "${!variableArchivo}" | tr "," " ") ) #Extraer todos los campos                  
    campos=( $(echo "${!variableArchivo}" | cut -d"," -f 2- | tr "," " ") ) #Extraer solo los campos del Alta
    camposConsulta=( ${campos[@]} ) #Extraer los campos que serviran para la consulta
}

GESTIONAR_OBJETO(){
    salirGestion=false
    while [ "$salirGestion" = false ]
    do
        clear
        MOSTRAR_OPCIONES_OBJETO
        read -rp "Escoge opción por su número: " opcionObjeto
        ((opcionObjeto--)) #Resto uno a la opción porque las arrays empiezan por 0
        if [[ $opcionObjeto =~ $numero ]] #Comprobar que has introducido un número
        then
            if [ "$opcionObjeto" -lt "${#opcionesObjeto[@]}" ] #Comprobar que es una opción válida
            then
                $(echo "${opcionesObjeto[$opcionObjeto]}") #Ejecutar opción
            else
                echo "Introduce una opción valida." 
            fi
        else
            echo "Introduce un número."
        fi
        if [ "$salirGestion" = false ]
        then
            read -rp "Pulsa enter..."
        fi
    done
}

GESTIONAR_PRESTAMO(){
    salirGestion=false
    while [ "$salirGestion" = false ]
    do
        clear
        MOSTRAR_OPCIONES_PRESTAMO
        read -rp "Escoge opción por su número: " opcionPrestamo
        ((opcionPrestamo--)) #Resto uno a la opción porque las arrays empiezan por 0
        if [[ $opcionPrestamo =~ $numero ]] #Comprobar que has introducido un número
        then
            if [ "$opcionPrestamo" -lt "${#opcionesPrestamo[@]}" ] #Comprobar que es una opción válida
            then
                $(echo "${opcionesPrestamo[$opcionPrestamo]}") #Ejecutar opción
            else
                echo "Introduce una opción valida." 
            fi
        else
            echo "Introduce un número."
        fi
        if [ "$salirGestion" = false ]
        then
            read -rp "Pulsa enter..."
        fi
    done
}

GESTION_LIBROS(){
    CARGAR_CONFIGURACION
    GESTIONAR_OBJETO
}

GESTION_USUARIOS(){      
    CARGAR_CONFIGURACION
    GESTIONAR_OBJETO
}

GESTION_PRESTAMOS(){     
    CARGAR_CONFIGURACION_PRESTAMO
    GESTIONAR_PRESTAMO
}

ALTA(){
    nuevosCampos=''
    for campo in "${campos[@]}" #Por cada campo
    do
        nombreCampo=$(echo "$campo" | cut -d"-" -f1) #Nombre campo
        regexCampo=$(echo "$campo" | cut -d"-" -f2) #Tipo campo
        campoIntroducido=false
        while [ $campoIntroducido = false ]
        do
            read -rp "Introduce $nombreCampo...($regexCampo): " nuevoCampo
            if [[ $nuevoCampo =~ ${!regexCampo} ]] #Comprobar si se ha introducido un valor correcto respecto al tipo
            then
                if [ "$nuevosCampos" != '' ] #Comprobar si no es el primer campo para no ponerle coma
                then
                    nuevosCampos=$nuevosCampos,$nuevoCampo
                else
                    nuevosCampos=$nuevoCampo
                fi
                campoIntroducido=true
            else
                echo "Debe de ser $regexCampo..."
            fi
        done
    done
    if [ "$(cat "$archivo" | wc -l)" -eq 0 ] #Si el archivo no tiene lineas poner el id=0
    then
        id=1
    else
        id=$(($(cat "$archivo" | tail -n1 | cut -d"," -f1)+1)) #Añadir el elemento con el id del último id +1
    fi
    if [ "$1" == 'PRESTAMO' ] #Si es un prestamo
    then
        libroValido=false
        usuarioValido=false        
        for idLibro in "${idLibrosDisponibles[@]}" #Comprobar que el id de libro introducido está en los ids permitidos
        do
            if [ "$(echo "$nuevosCampos" | cut -d"," -f1)" -eq $idLibro ]
            then
                libroValido=true
            fi
        done
        for idUsuario in "${idUsuariosDisponibles[@]}" #Comprobar que el id de usuario introducido está en los ids permitidos
        do
            if [ "$(echo "$nuevosCampos" | cut -d"," -f2)" -eq $idUsuario ]
            then
                usuarioValido=true
            fi
        done
        if [ "$libroValido" = true ] && [ "$usuarioValido" = true ] #Si los dos ids son válidos
        then
            totalPrestamos=$(cat "${nombreArchivos[1]}" | grep -w "^$(echo "$nuevosCampos" | cut -d"," -f2)" | rev | cut -d"," -f1 | rev) #El total de prestamos del usuario
            awk -v m=$(echo "$nuevosCampos" | cut -d"," -f1) $'BEGIN{FS=OFS=","} $1==m{$7="1"}1' ${nombreArchivos[0]} > ${nombreArchivos[0]}.tmp && mv ${nombreArchivos[0]}.tmp ${nombreArchivos[0]} #Asignar el 1 al libro para mostrar que está prestado
            awk -v m=$(echo "$nuevosCampos" | cut -d"," -f2) -v p=$(($totalPrestamos+1)) 'BEGIN{FS=OFS=","} $1==m{$6=p}1' ${nombreArchivos[1]} > ${nombreArchivos[1]}.tmp && mv ${nombreArchivos[1]}.tmp ${nombreArchivos[1]} #Sumar 1 a los prestamos del usuario
            nuevosCampos=$id,$nuevosCampos
            echo "$nuevosCampos" >> $archivo #Añadir al archivo
        else
            if [ "$libroValido" != true ] #Si el id de libro no era válido
            then
                echo "No es un libro válido"
            fi
            if [ "$usuarioValido" != true ] #Si el id de usuario no era válido
            then
                echo "No es un usuario válido"
            fi
        fi
    else
        nuevosCampos=$id,$nuevosCampos,0
        echo "$nuevosCampos" >> $archivo #Añadir al archivo
    fi
}

BAJA(){
    read -rp "Introduce el id del elemento que quieras borrar: " idElemento
    elemento=$(cat "$archivo" | grep -w "^$idElemento") #Seleccionar elemento
    if [ "$elemento" != '' ] #Si el elemento existe
    then
        if [ "$1" == 'PRESTAMO' ] #Si es un prestamo
        then
            prestamos=0 #Forzar que prestamos es igual a 0 para que borre el prestamo
            totalPrestamos=$(cat "${nombreArchivos[1]}" | grep -w "^$(echo "$elemento" | cut -d"," -f3)" | rev | cut -d"," -f1 | rev) #Contar numero de prestamos del usuario
            awk -v m=$(echo "$elemento" | cut -d"," -f2) $'BEGIN{FS=OFS=","} $1==m{$7="0"}1' ${nombreArchivos[0]} > ${nombreArchivos[0]}.tmp && mv ${nombreArchivos[0]}.tmp ${nombreArchivos[0]} #Quitar prestamo del libro
            awk -v m=$(echo "$elemento" | cut -d"," -f3) -v p=$(($totalPrestamos-1)) 'BEGIN{FS=OFS=","} $1==m{$6=p}1' ${nombreArchivos[1]} > ${nombreArchivos[1]}.tmp && mv ${nombreArchivos[1]}.tmp ${nombreArchivos[1]} #Quitar prestamo del usuario
        else
            prestamos=$(echo "$elemento" | rev | cut -d"," -f1 | rev) #Comprobar si el elemento no ha hecho ningún prestamo
        fi
        if [ "$prestamos" -eq 0 ] #Si no hay prestamos pendientes
        then
            cat $archivo | grep -wv "^$idElemento"> $archivo.tmp #Borrar elemento
            cat $archivo.tmp > $archivo
            rm $archivo.tmp
        else
            echo "No puedes eliminar el elemento si tiene relación con otros"
        fi
    else
        echo "No existe ningún elemento con ese id"
    fi
}

CONSULTA(){
    menuConsulta="¿Que campo desea utilizar para la búsqueda?\n"
    contador=0
    for campo in "${camposConsulta[@]}" #Mostrar campos disponibles para realizar la búsqueda
    do
        menuConsulta="$menuConsulta$contador.$(echo "$campo" | cut -d"-" -f1) ($(echo "$campo" | cut -d"-" -f2))\n"
        ((contador++))
    done
    echo -en "$menuConsulta"
    read -rp "Introduce el numero deseado: " opcionConsulta
    if [[ $opcionConsulta =~ $numero ]] #Comprobar que es un número
    then
        if [ "$opcionConsulta" -lt "${#camposConsulta[@]}" ] #Comprobar que es un número válido
        then
            campoConsulta=${camposConsulta[$opcionConsulta]}
            read -rp "Busca por $(echo "$campoConsulta" | cut -d"-" -f1)...: " busqueda #Introducir búsqueda
            if [ "$opcionConsulta" -eq 0 ] #Si la opción es la primera
            then
                if [ "$1" == "PRESTAMO" ] #Si es un prestamo
                then
                    resultado=$(cat "$archivo" | awk -v b="$busqueda" -F, '$2==b') #Coger valor del segundo campo
                else
                    resultado=$(cat "$archivo" | awk -v b="$busqueda" -F, '$1==b') #Coger valor del primer campo
                fi
            elif [ "$opcionConsulta" -eq 1 ] #Si la opción es la primera
            then
                if [ "$1" == "PRESTAMO" ] #Si es un prestamo
                then
                    resultado=$(cat "$archivo" | awk -v b="$busqueda" -F, '$3==b') #Coger valor del tercer campo
                else
                    resultado=$(cat "$archivo" | awk -v b="$busqueda" -F, '$2==b') #Coger valor del segundo campo
                fi
            fi
            if [ "$resultado" == '' ] #Si no se ha encontrado nada
            then
                echo "No se ha encontrado ningun $(echo "$campoConsulta" | cut -d"-" -f1) con la busqueda: $busqueda"  
            else
                echo -e "$resultado" #Mostrar resultado
            fi
        else
            echo "Introduce una opción valida." 
        fi
    else
        echo "Introduce un número."
    fi
}

ALTA_PRESTAMO(){
    echo ""
    echo "Libros disponibles:" #Mostrar libros y usuarios disponibles
    MOSTRAR_LIBROS_DISPONIBLES
    echo ""
    echo "Usuarios disponibles:"
    MOSTRAR_USUARIOS_DISPONIBLES
    echo ""
    ALTA 'PRESTAMO' #Realizar alta del prestamo
}

BAJA_PRESTAMO(){
    BAJA 'PRESTAMO'
}

LISTADO_PRESTAMO(){
    cat $archivo
}

CONSULTA_PRESTAMO(){
    CONSULTA 'PRESTAMO'
}

MOSTRAR_LIBROS_DISPONIBLES(){
    cat ${nombreArchivos[0]} | rev | awk -F, '$1==0' | rev #Mostrar libros que no hayan sido prestados
    idLibrosDisponibles=( $(cat ${nombreArchivos[0]} | rev | awk -F, '$1==0' | rev | cut -d"," -f1) )    
}

MOSTRAR_USUARIOS_DISPONIBLES(){
    cat ${nombreArchivos[1]} | rev | awk -F, '$1<3' | rev #Mostrar usuarios que tengan menos de 3 préstamos
    idUsuariosDisponibles=( $(cat ${nombreArchivos[1]} | rev | awk -F, '$1<3' | rev | cut -d"," -f1) )
}

SALIR(){
    salir=true
}

SALIR_GESTION(){
    salirGestion=true
}

###VARIABLES###
opcion=''
campos=()
camposConsulta=()
opcionesGestion=( 'GESTION_LIBROS' 'GESTION_USUARIOS' 'GESTION_PRESTAMOS' 'SALIR' ) #Funciones de gestion
nombreArchivos=( 'libros.bd' 'usuarios.bd' 'prestamos.bd' ) #Archivos utilizados
variableArchivo=''
variablesArchivos=( 'archivoLibros' 'archivoUsuarios' 'archivoPrestamos' ) #Nombre de strings con los campos de los archivos
opcionesObjeto=( 'ALTA' 'BAJA' 'CONSULTA' 'SALIR_GESTION' ) #Funciones de gestión de objetos
opcionesPrestamo=( 'ALTA_PRESTAMO' 'BAJA_PRESTAMO' 'LISTADO_PRESTAMO' 'CONSULTA_PRESTAMO' 'SALIR_GESTION' ) #Funciones de gestión de préstamos
numero='^[0-9]+$' #Regex de número
cadena="^[a-zA-Z[:space:]]+$" #Regex de string sin números con espacios
booleano='^[0-1]$' #Regex de booleano
archivo='' #Nombre del archivo actual
archivoLibros='id_libro-numero,título-cadena,autor-cadena,genero-cadena,año-numero,estantería-numero,prestado-booleano'
archivoUsuarios='id_usuario-numero,nombre-cadena,apellido1-cadena,apellido2-cadena,curso-numero,num_préstamos-numero'
archivoPrestamos='id_prestamo-numero,id_libro-numero,id_usuario-numero'
salir=false
salirGestion=false

###MENU###
while [ "$salir" = false ]
do
    clear
    MOSTRAR_BANNER
    MOSTRAR_OPCIONES
    read -rp "Escoge opción por su número: " opcion
    ((opcion--)) #Resto uno a la opción porque las arrays empiezan por 0
    if [[ $opcion =~ $numero ]] #Comprobar si es un número
    then
        if [ "$opcion" -lt "${#opcionesGestion[@]}" ] #Comprobar si es una opción válida
        then
            archivo=${nombreArchivos[$opcion]} #Nombre del archivo
            variableArchivo=${variablesArchivos[$opcion]} #Variable con los campos del archivo
            $(echo "${opcionesGestion[$opcion]}") #Ejecutar función elegida
        else
            echo "Introduce una opción valida." 
        fi
    else
        echo "Introduce un número."
    fi
    if [ "$salir" = false ]
    then
        read -rp "Pulsa enter..."
    fi
done