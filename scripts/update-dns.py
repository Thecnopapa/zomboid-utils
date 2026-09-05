#!/usr/bin/env python3
# By LuisPa 2024
# Copiar en /usr/bin/arsys_update.py
#
# Este script modifica la IP de mi servidor en mi dominio en internet.
# Recibo una IP dinámica y necesito actualizarla cada vez que reconecto.
#
#
# Conjunto de tres ficheros
# /etc/systemd/system/arsys_update.timer
# /etc/systemd/system/arsys_update.service
# /usr/bin/arsys_update.py
#
# Dependencias
# apt install -y python3-requests python3-dnslib
#
# cp arsys_update.py /usr/bin
# chmod +x /usr/bin/arsys_update.py
#
import requests, sys, os
import base64
import argparse
from dnslib import DNSRecord, QTYPE
import xml.etree.ElementTree as ET
from xml.dom.minidom import parseString

# Variables de autenticación
loginAPI = os.environ.get("DNS_LOGIN")
claveAPI = os.environ.get("DNS_TOKEN")
funcion = 'ModifyDNSEntry'

# Parámetros obligatorios
domain = os.environ.get("DNS_DOMAIN")
dns = os.environ.get("DNS_SUBDOMAIN")
currenttype = 'A'

# Variables para opciones
verbose = True
dry_run = False
execute = False

# Parsear argumentos
parser = argparse.ArgumentParser()
parser.add_argument('-v', action='store_true', help='Verbosity')
parser.add_argument('-n', action='store_true', help='Dry run (mostrar lo que haría pero sin hacerlo)')
parser.add_argument('-u', action='store_true', help='Ejecutar el programa para actualizar la entrada DNS')
args = parser.parse_args()

verbose = args.v
dry_run = args.n
execute = args.u

# Obtener IP @ Arsys (check host_a_cambiar.TODOMINIO.TLD)
def get_ip_arsys(dns):
    # COMPRUEBA EN TU PANEL Y CAMBIA "NN" POR LO QUE VEAS EN ÉL
    resolver = ['dns43.servidoresdns.net', 'dns44.servidoresdns.net']
    for res in resolver:
        try:
            q = DNSRecord.question(dns)
            a_pkt = q.send(res)
            a = DNSRecord.parse(a_pkt)
            for rr in a.rr:
                if QTYPE[rr.rtype] == 'A':
                    return str(rr.rdata)
        except Exception as e:
            if verbose:
                print(f"Error resolviendo {dns} con {res}: {e}")
    raise Exception(f"Error resolviendo {dns}")

IP_ARSYS = get_ip_arsys(dns)

# Consigo mi dirección pública IP en internet
IP_LOCAL = requests.get('https://api.ipify.org').text

# Verificar que IP_LOCAL se ha obtenido correctamente
if not IP_LOCAL:
    raise Exception("Error obteniendo la dirección IP del interfaz ppp0")

print(f" * Current IP: {IP_LOCAL}")

# Función para mostrar la operación sin ejecutarla
def dry_run_output(currentvalue, newvalue):
    print("DRY RUN: Se actualizaría la entrada DNS de", dns)
    print("IP antigua:", currentvalue)
    print("IP nueva:", newvalue)

# Función para ejecutar la actualización
def execute_update(currentvalue, newvalue):
    credentials = base64.b64encode(f"{loginAPI}:{claveAPI}".encode()).decode()
    headers = {
        'Authorization': f"Basic {credentials}",
        'Content-Type': 'text/xml; charset=ISO-8859-1'
    }
    body = f"""<?xml version="1.0" encoding="ISO-8859-1"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <soap:Body>
        <{funcion} xmlns="ModifyDNSEntry">
          <input>
            <newvalue xsi:type="xsd:string">{newvalue}</newvalue>
            <currentvalue xsi:type="xsd:string">{currentvalue}</currentvalue>
            <dns xsi:type="xsd:string">{dns}</dns>
            <domain xsi:type="xsd:string">{domain}</domain>
            <currenttype xsi:type="xsd:string">{currenttype}</currenttype>
          </input>
        </{funcion}>
      </soap:Body>
    </soap:Envelope>"""

    # Mostrar el cuerpo de la solicitud en formato bonito
    if verbose:
        print(f"Body:{body}")
    #    xml_pretty = parseString(body).toprettyxml()
    #    print("Cuerpo de la solicitud (bonito):\n", xml_pretty)

    response = requests.post("https://api.servidoresdns.net:54321/hosting/api/soap/index.php", headers=headers, data=body)

    # Depuración de la respuesta
    if verbose:
        print("HTTP Status Code:", response.status_code)
        print("HTTP Response Content (raw):", response.content)

    if response.status_code != 200:
        raise Exception(f"Error en la solicitud SOAP: {response.status_code} {response.reason}")

    # Mostrar el contenido de la respuesta en formato bonito
    response_xml_pretty = parseString(response.content).toprettyxml()
    if verbose:
        print("Contenido de la respuesta (bonito):\n", response_xml_pretty)

    root = ET.fromstring(response.content)

    print(f"ARSYS: Cambios solicitado, IP antigua: {currentvalue} > IP nueva: {newvalue}")
    print("Resultado de la petición:", response.status_code)

# Lógica para dry run y ejecución
if dry_run:
    dry_run_output(IP_ARSYS, IP_LOCAL)
elif execute:
    if IP_ARSYS and IP_LOCAL:
        if IP_ARSYS != IP_LOCAL:
            execute_update(IP_ARSYS, IP_LOCAL)
        else:
            print("ARSYS: Las IP son iguales, no es necesario actualizar.")
    else:
        raise Exception("Error obteniendo las direcciones IP.")
else:
    print("Uso: script.py [-v] [-n] [-u]")
    print("  -v  Verbosity")
    print("  -n  Dry run (mostrar lo que haría pero sin hacerlo)")
    print("  -u  Ejecutar el programa para actualizar la entrada DNS")
    
