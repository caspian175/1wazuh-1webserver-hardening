# Hardening de Seguridad con Ansible

Este repositorio contiene una solución modular y automatizada para aplicar una línea base de seguridad inspirada en los controles **CIS Benchmarks** sobre dos entornos distintos: el **Wazuh Manager (VM2)** y el **Servidor Web (VM1)**. 

Toda la configuración y el robustecimiento del sistema se realizan de manera centralizada desde el Nodo de Control (VM2) a través de un asistente interactivo en Bash (`setup.sh`).

---

## Alcance del Proyecto

* **Automatizado por este repositorio:** La instalación de Ansible Core, la gestión automatizada de llaves SSH criptográficas entre nodos, la actualización dinámica de inventarios y la ejecución completa de los playbooks de hardening.
* **Excluido de la automatización (Configuración Manual):** La instalación, aprovisionamiento inicial y despliegue del software de monitoreo SIEM (tanto el Wazuh Manager en la VM2 como el Wazuh Agent en la VM1) deben realizarse previamente de forma manual por el administrador.

---

## Requisitos Previos

Antes de ejecutar el script de automatización, la infraestructura debe cumplir obligatoriamente con las siguientes condiciones previas (no configuradas por este script):

1. **Despliegue de Sistemas:** Ambas máquinas virtuales (VM1 y VM2) deben estar encendidas y operacionales bajo un sistema operativo compatible (familia RHEL/Rocky Linux 9).
2. **Topología de Red de Doble Adaptador:**
   * **Adaptador 1 (`enp0s3`):** Configurado en modo Puente (Bridge) con direccionamiento dinámico por DHCP y conectividad activa a Internet.
   * **Adaptador 2 (`enp0s8`):** Configurado en modo Red Interna (Internal Network) dentro del segmento aislado `192.168.100.0/24`.
3. **Direccionamiento IP Estático (Interfaz `enp0s8`):**
   * **VM1 (Servidor Web):** Debe tener asignada fijamente la IP `192.168.100.10`.
   * **VM2 (Wazuh Manager):** Debe tener asignada fijamente la IP `192.168.100.20`.
4. **Despliegue Manual de Wazuh:** El servidor Wazuh Manager y su respectivo Dashboard deben estar instalados de forma manual en la VM2, y el agente de Wazuh debe estar desplegado y vinculado manualmente en la VM1.
5. **Credenciales de Administración:** Existencia de un usuario con privilegios de ejecución de comandos mediante `sudo` en la VM1.

---

## Diagrama de Arquitectura de Red y Flujo de Logs

```mermaid
graph TD
    classDef vms fill:#2b2b2b,stroke:#4e4e4e,stroke-width:2px,color:#ffffff;
    classDef nets fill:#1f3a52,stroke:#2e5c84,stroke-width:1px,color:#ffffff;
    classDef inter fill:#3a3a3a,stroke:#555,stroke-width:1px,stroke-dasharray: 5 5,color:#ffffff;

    NET[Red Externa / Internet <br> Modo Puente - DHCP] ::: nets
    LAN[Subnet de Gestión Aislada <br> Red Interna - 192.168.100.0/24] ::: nets

    subgraph VM1 [VM1 - SERVIDOR WEB]
        direction TB
        enp0s3_1[Interfaz: enp0s3 <br> IP: Dinámica DHCP] ::: inter
        enp0s8_1[Interfaz: enp0s8 <br> IP: 192.168.100.10] ::: inter
        APP[Aplicación Web / Apache]
        AG[Wazuh Agent]
        SSH1[Servicio: sshd Port 22]
    end
    style VM1 fill:#1a1a1a,stroke:#ff9900,stroke-width:2px,color:#ffffff;

    subgraph VM2 [VM2 - WAZUH MANAGER]
        direction TB
        enp0s3_2[Interfaz: enp0s3 <br> IP: Dinámica DHCP] ::: inter
        enp0s8_2[Interfaz: enp0s8 <br> IP: 192.168.100.20] ::: inter
        DASH[Wazuh Dashboard & Engine]
        ANS[Ansible Core]
    end
    style VM2 fill:#1a1a1a,stroke:#00aaff,stroke-width:2px,color:#ffffff;

    NET === enp0s3_1
    NET === enp0s3_2
    enp0s8_1 === LAN
    enp0s8_2 === LAN

    ANS -- "Orquestación Automatizada <br> Puerto 22/TCP SSH" --> SSH1
    AG -- "Envío de Telemetría y Logs <br> Puerto 1514/TCP" --> DASH

   git clone https://github.com/caspian175/1wazuh-1webserver-hardening.git
   cd ansible-hardening-lab
   chmod +x setup.sh
