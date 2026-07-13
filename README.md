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

## Ejecución
   1. git clone https://github.com/caspian175/1wazuh-1webserver-hardening.git
   2. cd ansible-hardening-lab
   3. chmod +x setup.sh
