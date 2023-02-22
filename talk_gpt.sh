#!/bin/bash


function convert_img {
  imagenes=$(find "$ruta_imagenes" \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \))
  num_imagenes=$(echo "$imagenes" | wc -l)

  # Ingresar comando
  comando=$1
  
  # Extraer el numero de la imagen
  numero=$(echo $comando | cut -d ',' -f 1 | cut -d '(' -f 2)

  # Extraer el texto
  texto=$(echo $comando | cut -d ',' -f 2 | cut -d '"' -f 2)


  # Comprobar si el número de imagen está dentro del rango de la lista de imágenes
  if [[ "$numero" -gt 0 && "$numero" -le "$num_imagenes" ]]; then
    # Buscar la ruta de la imagen correspondiente utilizando sed
    ruta=$(echo "$imagenes" | sed -n "${numero}p")
  else
    echo "El número de imagen está fuera del rango."
  fi
  number=$(shuf -i1-9999 -n1)
  new_file_tmp="tmp_img_$number"
  convert $ruta -quality 20 -resize 30x30! $ruta_imagenes$new_file_tmp
  # Convertir la imagen a Base64
  base64=$(base64 $ruta_imagenes$new_file_tmp)
  rm $ruta_imagenes$new_file_tmp 
  echo "te envio esta imagen en base64,$texto: $base64"
  return 0
  
}

##########
#talk_gpt
#
#funcion para conectarse y mantener conversación 
#con ChatGPT.
##########
function talk_gpt {
  # Definir la URL de la api de OpenAI
  authorization="Authorization: Bearer $YOUR_API_KEY"
  content_type="Content-Type: application/json"
  chat_file=$1
  clear
  # Loop infinito para mantener la conversación
  while true; do
    imagen="false" #si imagen es false, quiere decir que no vamos a enviar imagenes por lo que sigue, sino se cambiar u no sigue con texto
    continuar="true" #esto es para saltar en el caso de que haya que mostrar algo por pantalla
    type="text" # esto va a definir que tiene que hacer por ahora va text o imagen, pero quiero agregar code
    total_line "-" 
    p_text "$(whoami)" "0" "red"
    read -p "> " input_text
    # entra en ayuda
    if [[ $input_text == "ayuda" ]]; then
      print_ayuda
      continuar="false"
    fi
    # muestra valores de las variables
    if [[ $input_text == "ver_valores" ]]; then
      ver_valores
      continuar="false"
    fi
    # para setear voz
    if [[ $input_text == "m_voz" ]]; then
      modificar_variable "voz" "$voz"
      continuar="false"
    fi
    # para modificar la cantidad de imagenes que genera
    if [[ $input_text == "m_n" ]]; then
      modificar_variable "n" "$n"
      continuar="false"
    fi
    # para modificar el tamaños de las imagenes solicitadas
    if [[ $input_texyt == "m_size" ]]; then
      modificar_variable "size" "$size"
    fi
    # para borrar la cache de la converasción
    if [[ "$input_text" == "borrar_cache" ]]; then
      > $chat_file #se borra el contenido del archivo cache
      p_text "Se ha borrado todo el contenido de la conversación." "1" "blue"
      continue
    fi
    # para subir imagenes a la AI de text
    if [[ $input_text == "imagen("* ]]; then
      input_text=$(echo $input_text | cut -d'(' -f2 | cut -d')' -f1)
      type="imagen"
    fi
    # para solicitar imagenes
    if [[ $input_text == *"img("* ]]; then
      valor=$(echo $input_text | grep -o "img.*)")
      input_text="$(convert_img "$valor")"
      imagen="true"
    fi
    # mustra las imagenes que tenemos en el directorio
    if [[ "$input_text" == "ver_img" ]];then
      find $ruta_imagenes -name "*.jpg" -o -name "*.png" -o -name "*.gif" | nl
      continue
    fi
    # sale del programa
    if [[ "$input_text" == "chau" ]]; then
      p_text "¡Adiós! ¡Hasta la próxima!, este chat quedo registrado en el archivo $chat_file." "1" "green"
      break 
    fi
    # vuelve al menu principal
    if [[ "$input_text" == "volver" ]]; then
      main
      break
    fi
    # comprueba si es o no una imagen con la que queremos trabajar
    # en el caso de que si no va guardar el input
    if [[  $imagen == "true" ]]; then
      input_text_final=$input_text
      echo "se envio imagen..." >> $chat_file
    else
      echo "yo:
      $input_text
      " >> $chat_file
      read -d '' input_text_final < "$chat_file"
      if expr length "$input_text_final" \> 4000 >/dev/null; then
          input_text_final=$(echo "${input_text_final: -4000}")
      fi
    fi
    # comprueba que tipo solicitud vamos a hacer...
    if [[ $type == "text" ]]; then
        if [[ $continuar == "true" ]]; then
            #Escapar caracteres especiales en la entrada del usuario
            input_text=$(echo "$input_text_final" | jq -R '.' | jq -s -c --arg modelo "$modelo" --argjson temperatura "$temperatura" --argjson max_token "$max_token" '{"model": $modelo , "prompt" : "\(.)", "temperature": $temperatura, "max_tokens" : $max_token}')
            # response, enviamos los datos:
            response=$(curl -s -X POST -H "$content_type" -H "$authorization" -d "$input_text" $url)
            output=$(echo $response | jq -r '.choices[0].text')
            total_line "-"
            p_text "OpenAI: $output" "1" "blue"
            echo "OpenAI: $output" >> $chat_file
          
            if [[ $output == *"null" ]]; then
              echo $input_text
              echo $response
            else 
              echo $input_text >> "$ruta_principal/tgpt.log"
              echo $response >> "$ruta_principal/tgpt.log"
            fi
            if [[ "$voz" == "true" ]]; then
              espeak-ng -v es-419 "$output"
            fi
        fi
    else
        input_text=$(echo "$input_text" | jq -R '.' | jq -s -c --argjson n $n --arg size "$size" '{"prompt" : "\(.)", "n" : $n, "size" : $size }')
        p_text "Se esta enviando la solicitud, puede demorar un rato" "1" "green"
        response=$(curl -s $url_image -H "$content_type" -H "$authorization" -d "$input_text")
        link_image=$(echo $response | jq -r '.data[].url')
        for url_tmp in $link_image; do
            number=$(shuf -i1-9999 -n1)
            filename="$ruta_imagenes_d/$number.png"
            p_text "[X] Se ha descargado la imagen en la direccion $filename" "1" "blue"
            wget -q "$url_tmp" -O $filename
            if [ "$TERM" == "xterm-kitty" ]; then
              convert $filename -resize 300x300! "$ruta_imagenes_d/mini_$number.png"
              kitty +kitten icat "$ruta_imagenes_d/mini_$number.png"
            fi

        done
        
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
    p_text "6. Comprobar el sistema" "1" "blue"
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
      6)
      requirements
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
  if [ ! -s "$ruta_principal/ht.t" ] || [ -f "$ruta_princial/ht.t" ]; then
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
      if [ $number_chat -gt $((contador-1)) ] ||  [[ ! "$number_chat" =~ ^[0-9]+$ ]]; then
        clear
        p_text "El número es mayor que la cantidad de chat generados o ingreso un caracter incorrecto" "1" "red"
        continue
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
        url_image="https://api.openai.com/v1/images/generations"
        ruta_imagenes="$ruta_principal/imagenes/"
        ruta_textos="$ruta_principal/textos/"
        n=2
        ruta_imagenes_d="$ruta_principal/descargas"
        size="1024x1024"
        YOUR_API_KEY1="YOUR_API_KEY1"
        YOUR_API_KEY2="YOUR_API_KEY2"
        YOUR_API_KEY3="YOUR_API_KEY3"
        YOUR_API_KEY4="YOUR_API_KEY4"
        YOUR_API_KEY5="YOUR_API_KEY5"
        # si el archivo de configuración no existe se crea.
        mkdir -p $ruta_principal
        echo "ruta_principal=$ruta_principal" >> $config_file
        echo "config_file=$config_file" >> $config_file
        echo "temperatura=$temperatura" >> $config_file
        echo "modelo=$modelo" >> $config_file
        echo "voz=$voz" >> $config_file
        echo "max_token=$max_token" >> $config_file
        echo "url=$url" >> $config_file
        echo "url_image=$url_image" >> $config_file
        echo "YOUR_API_KEY=$YOUR_API_KEY" >> $config_file
        echo "ruta_imagenes=$ruta_imagenes" >> $config_file
        echo "ruta_imagenes_d=$ruta_imagenes_d" >> $config_file
        echo "ruta_textos=$ruta_textos" >> $confi_file
        echo "n=$n" >>   $config_file
        echo "size=$size" >> $config_file
        echo "YOUR_API_KEY1=$YOUR_API_KEY1" >> $config_file 
        echo "YOUR_API_KEY2=$YOUR_API_KEY2" >> $config_file 
        echo "YOUR_API_KEY3=$YOUR_API_KEY3" >> $config_file 
        echo "YOUR_API_KEY4=$YOUR_API_KEY4" >> $config_file 
        echo "YOUR_API_KEY5=$YOUR_API_KEY5" >> $config_file 
        source "$config_file"
    fi
    if [[ ! -d $ruta_imagenes ]]; then
      mkdir $ruta_imagenes
    fi
    if [[ ! -d $ruta_textos ]]; then
      mkdir $ruta_textos
    fi
    if [[ ! -d $ruta_imagenes_d ]]; then
      mkdir $ruta_imagenes_d
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
    p_text " 7) Setear valor Api Key (secret)" "1" "red"
    p_text " 8) Setear galeria imagenes ($ruta_imagenes)" "1" "green"
    p_text " 9) Setear galeria texto ($ruta_textos)" "1" "green"
    p_text "10) Setear cantidad de imagenes ($n)" "1" "green"
    p_text "11) Setear tamaño de las imagenes ($size)" "1" "green"
    p_text "12) Ruta de descarga de imagenes ($ruta_imagenes_d)" "1" "green"
    p_text "13) Almacenar API KEYS" "1" "green"
    p_text " 0) Salir" "1" "red"
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
            modificar_variable "YOUR_API_KEY" "$YOUR_API_KEY"
            ;;
        8)
            modificar_variable "ruta_imagenes" "$ruta_imagenes"
            ;;
        9) 
            modificar_variable "ruta_textos" "$ruta_textos"
            ;;
        10)
            modificar_variable "n" "$n"
            ;;
        11)
            modificar_variable "size" "$size"
            ;;
        12)
            modificar_variable "ruta_imagenes_d" "$ruta_imagenes_d"
            ;;
        13)
            store_api_key
            ;;
        0)
            main
            break
            ;;
        *)
            p_text "Opción inválida." "1" "red"
            ;;
    esac
done
}

function store_api_key {
    clear
    while true; do
    p_text "LISTADO ACTUAL DE APIS KEY" "1" "blue"
    p_text "1) API KEY 1 ($YOUR_API_KEY1)" "1" "green"
    p_text "2) API KEY 2 ($YOUR_API_KEY2)" "1" "green"
    p_text "3) API KEY 3 ($YOUR_API_KEY3)" "1" "green"
    p_text "4) API KEY 4 ($YOUR_API_KEY4)" "1" "green"
    p_text "5) API KEY 5 ($YOUR_API_KEY5)" "1" "green"
    p_text "0) Salir" "1" "red"
    read -p "Ingrese el número de API KEY A Setear: " option_api_key
    if [[ option_api_key == "0" ]]; then
      break
    else
    read -p "Ingrese la nueva API KEY: " new_api_key
    read -p "Ingrese la cuenta a la que pertenece: " account_key
    variable="YOUR_API_KEY${option_api_key}"
    echo "El valor de la variable ${variable} es: ${!variable}"
    valor="$new_api_key:$account_key"
    echo $valor
    sed -i "s/^${variable}=.*/${variable}=\"$valor\"/" "$config_file"
    p_text "¡$variable actualizado a '$valor'!" "1" "green"
    source $config_file
    fi
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

function requirements {
  clear
  # Comprobar la distribución de Linux y el gestor de paquetes

  p_text "----------------------" "1" "green"
  p_text "   talk_gpt 0.5v      " "1" "blue"
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
          INSTALL="sudo $PACKAGE_MANAGER install -y "
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

  # Comprobar si imagemagick está instalado
  if ! $READ imagemagick &> /dev/null; then
      echo "[-] IMAGEMAGICK no está instalado. Instalando..."
      $INSTALL imagemagick
    else
      p_text "[X] IMAGEMAGICK INSTALADO" "1" "green"
      sleep 1
  fi
  # Comprobar si wget está instalado
  if ! $READ wget &> /dev/null; then
      echo "[-] WGET no está instalado. Instalando..."
      $INSTALL wget
    else
      p_text "[X] WGET INSTALADO" "1" "green"
      sleep 1
  fi 
  # Comprobar si espeak-bg está instalado
  if ! $READ espeak-ng &> /dev/null; then
      echo "[-] ESPEAK-NG no está instalado. Instalando..."
      $INSTALL espeak-ng
    else
      p_text "[X] ESPEAK-NG INSTALADO" "1" "green"
      sleep 1
  fi

  # Continúa con el resto de tu script aquí

  p_text "Las comprobaciones del sistema han terminado..." "1" "blue"
  p_text "volveremos al main en" "1" "blue"
  p_text "3" "1" "red"
  sleep 1
  p_text "2" "1" "red"
  sleep 1
  p_text "1" "1" "red" 
  sleep 1

  main
  }


function print_ayuda {
      total_line "*"
      p_text "A continuación se listan una serie de comandos que pueden ser incluidos en el prompt y que " "0" "blue"
      p_text "se reconoceran, casi todos deben estar solos, img() si si esta acompañada se separa pero el resto no" "0" "blue"
      total_line "*"
      p_text "ver_img" "1" "blue"
      p_text "        devuelve las imagenes disponibles en el directorio definido para" "0" "green"
      p_text "        trabajar con imagenes." "0" "green"
      p_text "img(<valor1>,<valor2>)" "1" "blue"
      p_text "        <valor1> tiene que ser el número de imagen que se quiere trabajar que fue" "0" "green"
      p_text "        devuelto por ver_img, tomara esa imagen y la reducira y luego la convertira en base64" "0" "green"
      p_text "        <valor2> es un string que ira acompañado de la imagen para pasarle como mensaje." "0" "green"
      p_text "borrar_cache" "1" "blue"
      p_text "        borra el archivo chat* con el que se esta trabajando actualmente por si la conversación se volvio" "0" "green"
      p_text "        muy extensa, a veces es conveniente porque puede mezclar temas" "0" "green"
      p_text "volver" "1" "blue"
      p_text "        Vuelve al menú inicial cortando el flujo de la conversación, por lo tanto no se guarda." "0" "green"
      p_text "chau" "1" "blue"
      p_text "        Sale directamente del programa, cortando el flujo de la conversación y devuelve el nombre del" "0" "green"
      p_text "        archivo chat* donde se estuvo guardando la conversación" "0" "green"
      p_text "ver_valores" "1" "blue"
      p_text "        Muestras los valores actuales con los que esta trabajando" "0" "green"
      p_text "m_voz" "1" "blue"
      p_text "        Permite modificar el valor de la variable voz, para que lea el contenido o no, es false o true" "0" "green"
      p_text "imagen()" "1" "blue"
      p_text "        Se envia un prompt entre comillas dobles, esto descargara las imagenes si es una terminal kitty se mostraran" "0" "green"
      p_text "        en pantalla a tamaño reducido, si no se indicara la ruta, es importante que esten seteados los valores correctamente. " "0" "green"
      p_text "        ver m_n y m_size" "0" "green"
      p_text "m_n" "1" "blue"
      p_text "        Este valor define la cantidad de imagenes que queremos generar." "0" "green"
      p_text "m_size" "1" "blue"
      p_text "        Esto definira los valores para el tamaño de las imagenes que solicitemos." "0" "green"
      p_text "ayuda" "1" "blue"
      p_text "        Es donde estas, bobo" "0" "red"

}

function ver_valores {
    p_text "Valores seteados:" "1" "green"
    p_text " 1) Ruta principal = ($ruta_principal)" "1" "blue"
    p_text " 2) Temperatura = ($temperatura)" "1" "blue"
    p_text " 3) Modelo = ($modelo)" "1" "blue"
    p_text " 4) Voz = ($voz)" "1" "blue"
    p_text " 5) Máximo de tokens = ($max_token)" "1" "blue"
    p_text " 6) URL de la API = ($url)" "1" "blue"
    p_text " 7) Galeria imagenes = ($ruta_imagenes)" "1" "blue"
    p_text " 8) Galeria texto = ($ruta_textos)" "1" "blue" 
    p_text "10) Cantidad de imagenes ($n)" "1" "blue"
    p_text "11) Tamaño de las imagenes ($size)" "1" "blue"
    p_text "12) Ruta de descarga de imagenes ($ruta_imagenes_d)" "1" "blue"
}

if [[ $1 == "-config" ]]; then
  requirements
else
  init
fi
