![Logo](./images/grid_0.png)

# TALK GPT 0.2v

This is a simple Bash script that uses OpenAI's GPT-3 API to chat with an AI. The script allows you to create a new chat, or to continue a previous one. The responses are in text and can now also be generated with a robotic voice.
The configuration and chat files are now by default saved in $HOME/.config/talk_gpt, allowing for separation of the script and files and making it possible to include them in the same system.


## Requirements

To use this script, you need to have **curl**, **jq**, **bc**, **espeak-ng** installed on your system. You also need to have an OpenAI API key to use the GPT-3 API.
Usage

To use the script, simply run the ./talk_gpt.sh command. You will be presented with a menu:

You should also generate an API KEY at https://platform.openai.com/account/api-keys and replace it in the variable YOUR_API_KEY.


1. Recuperar un chat 
2. Crear un nuevo chat
3. Configurar opciones
4. Configuraciones por defecto
5. Borrar todos los chats
0. Salir

  *  Opción 1 Permite continuar una conversación anterior.
  *  Opción 2 Crea un nuevo chat
  *  Opción 3 Se pueden modificar las opciones, temperatura, modelo, ruta, url, si habla o no
  *  Opción 4 Borra las configuraciones y las lleva a por defecto.
  *  Opción 5 Borra todos los chats
  *  Opción 0 Sale del script.

