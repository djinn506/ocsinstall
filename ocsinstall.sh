#!/bin/bash

TAG="${1:-"aula"}"  # defino tag default si recibo nada por argumento
URL="${2:-"ocsglpi.unicen.edu.ar"}"  # defino ip default si recibo nada por argumento
VERSION="${3:-"2.10.0"}"  # defino version default si recibo nada por argumento
OCSUSER="${4:-"admin"}"  # defino usuario default si recibo nada por argumento
OCSPASS="${5:-"admin"}"  # defino password default si recibo nada por argumento

function descargarOCS(){
   wget https://www.github.com/OCSInventory-NG/UnixAgent/releases/download/v$VERSION/Ocsinventory-Unix-Agent-$VERSION.tar.gz
}

function buscarTar(){
   FILE=$(find . 2>/dev/null -type f -name "Ocsinventory*" | grep .tar.gz | sed 's/.tar.gz//g' | cut -c 3-)
}

function instalarDep(){
   sudo apt-get install perl libdigest-md5-perl libxml-simple-perl libnet-ip-perl \
   libwww-perl libmac-sysprofile-perl libcrypt-ssleay-perl liblwp-protocol-https-perl libnet-snmp-perl \
   libnet-netmask-perl libnet-ping-perl libnmap-parser-perl libdata-uuid-perl libparse-edid-perl \
   libproc-daemon-perl libproc-pid-file-perl -y
   sudo apt install libxml-simple-perl -y
}

#Paquetes necesarios
if instalarDep; then
   >&2 printf 'ERROR: Fallo Instalación de dependencias\n'
   else
      printf 'Instalación de dependencias completa\n'
fi

buscarTar;
## Busco .tar.gz ##
if ! [ -e "$FILE".tar.gz ]; then
   printf 'OcsInventory.tar.gz no encontrado, Descargando...\n'
   if ! descargarOCS ; then
      >&2 printf 'ERROR: Fallo al Descargar\n'
      exit 6
      else
         printf 'Descarga Completa\n'
   fi
fi

buscarTar;
## Extraigo ##
if ! [ -d "$FILE" ]; then
   tar -xvzf "$FILE.tar.gz"
fi

cd "$FILE" || exit

## Compilar y Correr ##
if PERL_AUTOINSTALL=1 perl Makefile.PL; then
   printf 'OCS se compiló correctamente\n'
   if sudo ./ocsinventory-agent --devlib --server http://$URL/ocsinventory --user=$OCSUSER --password=$OCSPASS --tag=$TAG; then
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
