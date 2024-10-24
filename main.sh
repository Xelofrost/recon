#!/bin/bash
bash ./reset.sh
figlet -f slant ILLOWARE
if [ -z "$1" ]; then
    echo "Error: No enviaste un dominio"
    echo "Uso: ./main.sh <dominio>"
    exit
fi

domain=$1
echo "Escaneando $domain"

#Estructura de carpetas

timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
ruta_resultados=./resultados/$domain/$timestamp
mkdir -p "$ruta_resultados"
mkdir -p $ruta_resultados/raw
mkdir -p $ruta_resultados/clean
#Analisis infraestructura

dig +short A $domain > $ruta_resultados/clean/IP
dig +short MX $domain > $ruta_resultados/clean/MX
dig +short TXT $domain > $ruta_resultados/clean/TXT
dig +short NS $domain > $ruta_resultados/clean/NS
dig +short SRV $domain > $ruta_resultados/clean/SRV
dig +short AAAA $domain > $ruta_resultados/clean/AAAA
dig +short CNAME $domain > $ruta_resultados/clean/CNAME
dig +short SOA $domain > $ruta_resultados/clean/SOA

echo "Extrayendo rangos de IP"
while IFS= read -r ip; do
    whois -b "$ip" | grep 'inetnum' | awk '{print $2, $3, $4}' >> $ruta_resultados/clean/rangos_ripe
done < $ruta_resultados/clean/IP

echo "Realizando whois"
whois $domain > $ruta_resultados/raw/whois
echo "Realizando dig"
dig $domain > $ruta_resultados/raw/dig

curl -I https://$domain > $ruta_resultados/raw/headers
cat $ruta_resultados/raw/headers | grep -i Server | awk '{print $2}' > $ruta_resultados/clean/header_server

# Revisar y eliminar archivos vacíos en la carpeta /clean
for file in "$ruta_resultados/clean"/*; do
  if [ ! -s "$file" ]; then
    echo "Eliminando archivo vacío: $file"
    rm "$file"
  fi
done