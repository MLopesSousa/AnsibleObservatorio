#!/bin/bash

trap ctrl_c INT

if [[ -n $1 && $1 == '-f' ]]; then force="true"; shift 1; fi
if [ -z $1 ]; then exit; else ambiente=$1; fi
if [ -z $2 ]; then exit; else serverGroup=$2; fi
if [ -n $3 ]; then usuarioSSH=$3; fi

function ctrl_c() {
        tput sgr0;
        echo
        exit
}

function pegarApi() {
        APIS=("dese=http://dese:8060" "homol=http://homol:8070" "prod=http://prod:8080")

        for api in ${APIS[@]}; do
                if [ $(echo $api |awk -F'=' '{print $1}') == ${ambiente} ]; then
                        echo $(echo $api |awk -F'=' '{print $2}')
                        break
                fi
        done
}

function pegarServidores() {
        if [ ! -z $1 ]; then
                apiURL=$1
                JQ="/usr/bin/jq"
                CURL="/usr/bin/curl -s $apiURL/Observer/v2/targets"

                echo $($CURL | $JQ ".[] |{target: .desc, server: [.server[].host]} | select(.target == \"${serverGroup}\" ) | .server[]" |sed 's/"//g')
        fi
}

function pegarAmbiente() {
        if [ ! -z $1 ]; then
                apiURL=$1
                JQ="/usr/bin/jq"
                CURL="/usr/bin/curl -s $apiURL/Observer/v2/targets"

                echo $($CURL | $JQ ".[] |{target: .desc, ambiente: .env } | select(.target == \"${serverGroup}\" ) | .ambiente" |sed 's/"//g' |awk -F'-' '{print $2}')
        fi
}

function criarInventario() {
        arquivoTemporario=/tmp/.$$.file
        echo '' > $arquivoTemporario

        for servidor in $servidores; do
                echo "${servidor}:893" >> $arquivoTemporario
        done

        echo $arquivoTemporario
}

function executarComando() {
        if [[ $ambiente != "DMZ" && $ambiente != "INTRANET" ]]; then
                ambiente=""
        else
                if [ $ambiente == "DMZ" ]; then ambiente="SEFAZCE\\"; fi
                if [ $ambiente == "INTRANET" ]; then ambiente="SEFAZ\\"; fi
        fi


        inventario=$(criarInventario)
        if [ -f $inventario ]; then
                if [ -z $usuarioSSH ]; then
                        echo -n "Informe o usuario SSH do dominio: ${ambiente}: "
                        read usuario
                else
                        usuario=$usuarioSSH
                fi

                ansible '*' -i $inventario -m shell -a "${comando}" -u "${ambiente}${usuario}" -k -s
                rm -rf $inventario
        fi
}

function main() {
        echo -n "Digite os comandos desejados separados por virgulas: "
        tput setaf 2;
        read comando;
        tput sgr0

        apiURL=$(pegarApi)
        if [ ! -n $apiURL ]; then
                tput setaf 1; echo "Erro ao executar a funcao: pegarApi"; tput sgr0
                exit 1;
        fi

        servidores=$(pegarServidores $apiURL)
        if [ ! -n "$servidores" ]; then
                tput setaf 1; echo "Erro ao executar a funcao: pegarServidores"; tput sgr0
                exit 1;
        fi

        ambiente=$(pegarAmbiente $apiURL)
        if [ ! -n "$ambiente" ]; then
                tput setaf 1; echo "Erro ao executar a funcao: pegarAmbiente"; tput sgr0
                exit 1;
        fi

        tput setaf 1; echo -n "[ALERTA]: "; tput sgr0
        echo -n "O comando: "; tput setaf 2; echo -n ${comando}; tput sgr0; echo -n " sera executado nos servidores: ";
        tput setaf 2; echo ${servidores}; tput sgr0

        if [ -z $force ]; then
                echo -n "deseja continuar? [S/N] "
                read opcao;
        else
                opcao="s"
        fi

        opcao=$(echo $opcao |tr '[:upper:]' '[:lower:]')
        if [ $opcao == "s" ]; then
                executarComando
        fi
}

main
