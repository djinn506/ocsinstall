#!/bin/bash

URL="${1:-"ocsglpi.unicen.edu.ar"}"  # defino ip default si recibo nada por argumento
VERSION="${2:-"2.10.0"}"  # defino version default si recibo nada por argumento
OCSUSER="${3:-"admin"}"  # defino usuario default si recibo nada por argumento
OCSPASS="${4:-"admin"}"  # defino password default si recibo nada por argumento

function descargarOCS(){
   wget https://www.github.com/OCSInventory-NG/UnixAgent/releases/download/v$VERSION/Ocsinventory-Unix-Agent-$VERSION.tar.gz
}

function buscarTar(){
   FILE=$(find . 2>/dev/null -type f -name "Ocsinventory*" | grep .tar.gz | sed 's/.tar.gz//g' | cut -c 3-)
}

function instalarDep(){
   sudo apt-get install perl libxml-simple-perl libdigest-md5-perl libxml-simple-perl libnet-ip-perl \
   libwww-perl libmac-sysprofile-perl libcrypt-ssleay-perl liblwp-protocol-https-perl libnet-snmp-perl \
   libnet-netmask-perl libnet-ping-perl libnmap-parser-perl libdata-uuid-perl libparse-edid-perl \
   libproc-daemon-perl libproc-pid-file-perl -y
}

#Paquetes necesarios
if instalarDep; then
   >&2 printf 'ERROR: Fallo Instalación de dependencias\n'
   else
      printf 'Instalación de dependencias completa\n'
fi

## Busco .tar.gz ##
buscarTar;
if ! [ -e "$FILE".tar.gz ]; then
   printf 'OcsInventory.tar.gz no encontrado, Descargando...\n'
   if ! descargarOCS ; then
      >&2 printf 'ERROR: Fallo al Descargar\n'
      exit 6
      else
         printf 'Descarga Completa\n'
   fi
fi

## Extraigo ##
if ! [ -d "$FILE" ]; then
   if ! tar -xvzf "$FILE.tar.gz"; then
      >&2 printf 'ERROR: Fallo Extracción\n'
      exit 4
      else
         printf 'Extracción Completa\n'
   fi
fi

cd "$FILE" || exit

## Compilar y Correr ##
if PERL_AUTOINSTALL=1 perl Makefile.PL; then
   printf 'OCS se compiló correctamente\n'
   if sudo ./ocsinventory-agent --devlib --server http://$URL/ocsinventory --user=$OCSUSER --password=$OCSPASS; then
      printf 'Se enviaron los datos correctamente\n'
      else
         >&2 printf 'ERROR: No se pudo enviar los datos\n'
         exit 3
      fi
   else
      >&2 printf 'ERROR: OCS Inventory se compiló mal\n'
      exit 2
   fi

exit 0
