#!/bin/bash


##########
#talk_gpt
#
#funcion para conectarse y mantener conversación 
#con ChatGPT.
##########
function talk_gpt {
  # Definir la URL de la api de OpenAI
  #url="https://api.openai.com/v1/completions"
  # la api key generadad
  YOUR_API_KEY="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"
  authorization="Authorization: Bearer $YOUR_API_KEY"
  content_type="Content-Type: application/json"
  chat_file=$1
  clear

  # Loop infinito para mantener la conversación
  while true; do
    total_line "-"
    p_text "$(whoami)" "0" "red"
    read -p "> " input_text
    
    if [[ "$input_text" == "borrar_cache" ]]; then
      > $chat_file #se borra el contenido del archivo cache
      p_text "Se ha borrado todo el contenido de la conversación." "1" "blue"
      continue
    fi

    if [[ "$input_text" == "chau" ]]; then
      p_text "¡Adiós! ¡Hasta la próxima!, este chat quedo registrado en el archivo $chat_file." "1" "green"
      break 
    fi
    if [[ "$input_text" == "volver" ]]; then
      main
      break
    fi

    echo "yo:
    $input_text
    " >> $chat_file

    #Escapar caracteres especiales en la entrada del usuario
    input_text=$(echo "$input_text" | jq -R '.' | jq -s -c --arg modelo "$modelo" --argjson temperatura "$temperatura" --argjson max_token "$max_token" '{"model": $modelo , "prompt" : "\(.)", "temperature": $temperatura, "max_tokens" : $max_token}')

    # response, enviamos los datos:
    response=$(curl -s -X POST -H "$content_type" -H "$authorization" -d "$input_text" $url)
    output=$(echo $response | jq -r '.choices[0].text')

    total_line "-"
    p_text "OpenAI: $output" "1" "blue"
    echo "OpenAI: $output" >> $chat_file
    if [[ "$voz" == "true" ]]; then
      espeak-ng -v es-419 "$output"
    fi
  done
}


##########
#p_text
#
#imprime el texto dado tiene dos argumentos
#1) numero 0 o 1 (NEGRITA O NO)
#2) color: black, red, green, yellow, blue, magenta, cyan, white
##########
p_text() {
  case "$3" in
    black) color_code="30";;
    red) color_code="31";;
    green) color_code="32";;
    yellow) color_code="33";;
    blue) color_code="34";;
    magenta) color_code="35";;
    cyan) color_code="36";;
    white) color_code="37";;
    *) color_code="0";;
  esac
  echo -e "\e[0;${2};${color_code}m$1\e[0m"
}

##########
#total_line
#
#un argumento con el caracter a imprimir, 
#imprime toda la pantalla.
##########
total_line() {
	get_term_x
	repeat_char $1 $?
}

##########
#repeat_char
#
#imprime el primer argumento la cantidad de
#veces pasado en el segundo argumento.
##########

repeat_char() {
  char="$1"
  count="$2"
  printf "%${count}s" | tr " " "${char}"
  echo
}

##########
#get_term_x
#
#devuelve el numero de columna disponible en la terminal
#########
get_term_x() {
	return $(tput cols)
}


##########
#main
#
#funcion de entrada, muestra las opciones disponibles
##########
function main {
  clear
  while true; do
    p_text "1. Recuperar un chat" "1" "green"
    p_text "2. Crear nuevo chat" "1" "green"
    p_text "3. Configurar opciones" "1" "green"
    p_text "4. Configuraciones por defecto" "1" "blue"
    p_text "5. Borrar todos los chats" "1" "blue"
    p_text "0. Salir" "1" "red"

    read -p "Seleccione una opción: " option
      case $option in
      1)
      #En caso de que seleccione uno entra en la función X
      open_file 
      break
      ;;
      2)
      # En caso de que seleccione dos entran en la funcióY
      create_file
      break
      ;;
      3)
      # Selecciono para que se modifique el archivo config.cfg
      config
      break
      ;;
      4)
      clear_config
      break
      ;;
      5)
      clear_chats
      break
      ;;
      0)
      p_text "Adiós!, Hasta la próxima!" "1" "green"
      break
      ;;
      *)
      #Si selecciona algo invalido mostramos un mensaje de error y se repite el bucle.
      p_text "Opción Invalida. Intente nuevamente" "1" "red"
      ;;
      esac
  done

}
###########
#create_file
#
#Crea un archivo donde guarda el detalle de la conversación
#y luego llama a talk_gpt y pasa como argumento el nombre del
#archivo generado
###########

function create_file {
  clear
  # solicitar nombre para la conversación
  read -p "Ingrese un nombre corto para el chat: " new_chat
  # Creamos un archivo con un número al azar
  number=$(shuf -i1-9999 -n1)
  chat_file="$ruta_principal/chat$number.txt"
  touch $chat_file
  #guarmos los datos en un archivo ht.t 
  echo "$new_chat |$chat_file" >> "$ruta_principal/ht.t"
  talk_gpt $chat_file
}


##########
#open_file
#
#lee el archivo ht.t y luego muestras la opciones
#disponibles al usuario que selecciona y luego pasa 
#el del archivo de la conversación a talk_gpt
##########

function open_file {
  clear
  if [ ! -s "$ruta_principal/ht.t" ] || [ ! -f "$ruta_princial/ht.t" ]; then
    touch "$ruta_principal/ht.t"
    p_text "No existen chats para cargar, presione enter para volver..." "1" "red"
  read -p ""
  main
  else

    while true; do
      contador=1
      while IFS="|" read -r description file
      do
        p_text "$contador) $description" "0" "green"
        contador=$((contador+1))
      done < "$ruta_principal/ht.t"
      read -p "Ingrese el número de chat a recuperar: " number_chat
      if [ $number_chat -gt $contador ]; then
        p_text "El número es mayor que la cantidad de chat generados." "1" "red"
      else
        read -r linea < "$ruta_principal/ht.t"
        chat_file=$(echo $linea | cut -d "|" -f 2)
        talk_gpt $chat_file
        break  
      fi
    done
  fi

}



function init {
        ruta_principal="$HOME/.config/talk_gpt"
        config_file="$ruta_principal/config.cfg"
    # Si el archivo de configuración existe, cargar las variables desde él
    if [ -f "$config_file" ]; then
        source "$config_file"
    else
        # Definir el archivo de configuración y las variables predeterminadas
        temperatura="0.3"
        modelo="text-davinci-003"
        voz="false"
        max_token="600"
        url="https://api.openai.com/v1/completions"
        # si el archivo de configuración no existe se crea.
        mkdir -p $ruta_principal
        echo "ruta_principal=$ruta_principal" >> $config_file
        echo "config_file=$config_file" >> $config_file
        echo "temperatura=$temperatura" >> $config_file
        echo "modelo=$modelo" >> $config_file
        echo "voz=$voz" >> $config_file
        echo "max_token=$max_token" >> $config_file
        echo "url=$url" >> $config_file
        source "$config_file"
    fi
  
  main
}
# Definir la función para modificar una variable
function modificar_variable {
    clear
    variable=$1
    valor_actual=$2
    read -p "$variable ($valor_actual): " input
    valor=${input:-$valor_actual}
    if [ "$variable" = "temperatura" ]; then
        if (( $(echo "$valor < 0.1" | bc -l) || $(echo "$valor > 1.0" | bc -l) )); then
            echo "Error: La temperatura debe ser un número decimal entre 0.1 y 1.0"
            return
        fi
    elif [ "$variable" = "voz" ]; then
        valor=$(echo "$valor" | tr '[:upper:]' '[:lower:]')
        if [[ "$valor" != "true" && "$valor" != "false" ]]; then
            echo "Error: La entrada de voz debe ser 'true' o 'false'"
            return
        fi
    elif [ "$variable" = "max_token" ]; then
        if ! [[ "$valor" =~ ^[0-9]+$ ]]; then
            echo "Error: El número máximo de tokens debe ser un entero"
            return
        fi
    fi
    sed -i "s/^$variable=.*/$variable=\"$valor\"/" "$config_file"
    p_text "¡$variable actualizado a '$valor'!" "1" "green"
    source $config_file
}

# Definir la función para mostrar el menú principal
function show_menu {
    clear
    p_text "Seleccione una opción para modificar:" "1" "green"
    p_text " 1) Ruta principal ($ruta_principal)" "1" "blue"
    p_text " 2) Temperatura ($temperatura)" "1" "blue"
    p_text " 3) Modelo ($modelo)" "1" "blue"
    p_text " 4) Voz ($voz)" "1" "blue"
    p_text " 5) Máximo de tokens ($max_token)" "1" "blue"
    p_text " 6) URL de la API ($url)" "1" "blue"
    p_text " 7) Salir" "1" "red"
}

function config {
# Mostrar el menú principal
while true; do
    show_menu
    read -p "Opción: " opcion
    case $opcion in
        1)
            modificar_variable "ruta_principal" "$ruta_principal"
            ;;
        2)
            modificar_variable "temperatura" "$temperatura"
            ;;
        3)
            read -p "Modelo ($modelo): " input
            modelo=${input:-$modelo}
            sed -i "s/^modelo=.*/modelo=\"$modelo\"/" "$config_file"
            p_text "¡Modelo actualizado a '$modelo'!" "0" "green"
            ;;
        4)
            modificar_variable "voz" "$voz"
            ;;
        5)
            modificar_variable "max_token" "$max_token"
            ;;
        6)
            read -p "URL de la API ($url): " input
            url=${input:-$url}
            sed -i "s/^url=.*/url=\"$url\"/" "$config_file"
            ;;
        7)
            main
            break
            ;;
        *)
            p_text "Opción inválida." "1" "red"
            ;;
    esac
done
}

function clear_chats {
  rm $ruta_principal/chat*.txt
  rm "$ruta_principal/ht.t"
  read -r nada
  main
}

function clear_config {
  rm $config_file
  init
}

function detect_os {
clear
# Comprobar la distribución de Linux y el gestor de paquetes

p_text "----------------------" "1" "green"
p_text "   talk_gpt 0.3v      " "1" "blue"
p_text "   author: devMB      " "1" "red"
p_text "----------------------" "1" "green"
echo 
echo
p_text "Comienzan las comprobaciones del sistema..." "1" "red"

if [[ -e /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
    if [[ $ID =~ "debian" ]]; then
        PACKAGE_MANAGER="apt-get"
        INSTALL="sudo $PACKAGE_MANAGER install "
        READ="command -v"
    elif [[ $ID =~ "fedora" ]]; then
        PACKAGE_MANAGER="dnf"
        INSTALL="sudo $PACKAGE_MANAGER install -y "
        READ="command -v"
    elif [[ $ID =~ "centos" ]]; then
        PACKAGE_MANAGER="yum"
        INSTALL="sudo $PACKAGE_MANAGER -y "
        READ="rpm -q"
    elif [[ $ID =~ "ubuntu" ]]; then
        PACKAGE_MANAGER="apt"
        INSTALL="sudo $PACKAGE_MANAGER update && sudo $PACKAGE_MANAGER install -y "
        READ="command -v"
    elif [[ $ID =~ "arch" ]]; then
         PACKAGE_MANAGER="pacman"
         INSTALL="sudo $PACKAGE_MANAGER -S --noconfirm "
         READ="pacman -Q"
    else
        PACKAGE_MANAGER="unknown"
    fi
elif [[ `uname` == 'Darwin' ]]; then
      OS='Mac OS X'
      PACKAGE_MANAGER='brew'
else
      OS='unknown'
      PACKAGE_MANAGER='unknown'
fi

  p_text "Distribución de Linux detectada: $OS" "0" "blue"
  p_text "Gestor de paquetes detectado: $PACKAGE_MANAGER" "0" "blue"
  sleep 1
# Continúa con el resto de tu script aquí
 # Comprobar si jq está instalado
if ! $READ  jq &> /dev/null; then
    p_text "[-] JQ no está instalado. Instalando..." "1" "blue"
    $INSTALL jq
  else
    p_text "[X] JQ INSTALADO" "1" "green"
    sleep 1
fi

# Comprobar si bc está instalado
if ! $READ bc &> /dev/null; then
    echo "[-] BC no está instalado. Instalando..."
    $INSTALL bc
  else
    p_text "[X] BC INSTALADO" "1" "green"
    sleep 1
fi

# Comprobar si curl está instalado
if ! $READ curl &> /dev/null; then
    echo "[-] CURL no está instalado. Instalando..."
    $INSTALL curl
  else
    p_text "[X] CURL INSTALADO" "1" "green"
    sleep 1
fi

# Comprobar si espeak-bg está instalado
if ! $READ espeak-ng &> /dev/null; then
    echo "[-] ESPEAK-NG no está instalado. Instalando..."
    $INSTALL espeak-bg
  else
    p_text "[X] ESPEAK-NG INSTALADO" "1" "green"
    sleep 1
fi

# Continúa con el resto de tu script aquí

p_text "Las comprobaciones del sistema han terminado..." "1" "blue"
sleep 2
}

detect_os

init
