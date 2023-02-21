#!/bin/bash

function talk_gpt {
  # Definir la URL de la api de OpenAI
  url="https://api.openai.com/v1/completions"
  # la api key generadad
  YOUR_API_KEY="YOUR_API_KEY"
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
    input_text=$(echo "$input_text" | jq -R '.' | jq -s -c '{"model": "text-davinci-003" , "prompt" : "\(.)", "temperature": 0.3, "max_tokens" : 600}')

    # response, enviamos los datos:
    response=$(curl -s -X POST -H "$content_type" -H "$authorization" -d "$input_text" $url)
    output=$(echo $response | jq -r '.choices[0].text')

    total_line "-"
    p_text "OpenAI: $output" "1" "blue"
    echo "OpenAI: $output" >> $chat_file
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


function main {
  clear
  while true; do
    p_text "1. Recuperar un chat" "1" "green"
    p_text "2. Crear nuevo chat" "1" "green"
    p_text "3. Salir" "1" "red"

    read -p "Seleccione una opción: " option
      case $option in
      1)
      #En caso de que seleccione uno entra en la función X
      open_file 
      break
      ;;
      2)
      # En caso de que seleccione dos entran en la función Y
      create_file
      break
      ;;
      3)
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

function create_file {
  clear
  # solicitar nombre para la conversación
  read -p "Ingrese un nombre corto para el chat: " new_chat
  # Creamos un archivo con un número al azar
  number=$(shuf -i1-9999 -n1)
  chat_file="chat$number.txt"
  touch $chat_file
  #guarmos los datos en un archivo ht.t 
  echo "$new_chat |$chat_file" >> ht.t
  talk_gpt $chat_file
}


function open_file {
  clear
  while true; do
    contador=1
    while IFS="|" read -r description file
    do
      p_text "$contador) $description" "0" "green"
      contador=$((contador+1))
    done < ht.t
    read -p "Ingrese el número de chat a recuperar: " number_chat
    if [ $number_chat -gt $contador ]; then
      p_text "El número es mayor que la cantidad de chat generados." "1" "red"
    else
      read -r linea < ht.t
      chat_file=$(echo $linea | cut -d "|" -f 2)
      talk_gpt $chat_file
      break  
    fi
  done

}


main

