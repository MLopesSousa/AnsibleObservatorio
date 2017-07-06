Com o objetivo de integrar o ansible ao observatorio, foi desenvolvido um script que monta um arquivo de inventário baseado nas informaçoes
providas pela API do observatório.

A opção -f pode ser utilizada para suprimir a validação da execução:
bash ansibleObservatorio.sh -f homol sg-web usuarioSsh
