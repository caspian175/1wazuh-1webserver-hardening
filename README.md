# 1wazuh-1webserver-hardening
Markdown
# Infraestructura como Código (IaC): Hardening de Seguridad con Ansible

Este repositorio contiene una solución modular, reproducible y automatizada para aplicar una línea base de seguridad inspirada en los controles **CIS Benchmarks** sobre dos entornos distintos: el **Wazuh Manager (VM2)** y el **Servidor Web / Base de Datos (VM1)**.

Toda la orquestación se realiza de forma centralizada desde el Nodo de Control (VM2) utilizando privilegios elevados a través de un script automatizador interactivo.

## Controles de Seguridad Automatizados

Los playbooks de Ansible incluidos ejecutan de manera limpia y segura las siguientes tareas de robustecimiento:
1. **Gestión de Políticas de Contraseñas:** Configuración de tiempos de expiración y políticas estrictas de complejidad de caracteres mediante `pam_pwquality`.
2. **Remoción de Servicios Inseguros:** Deshabilitación permanente de servicios innecesarios o propensos a vulnerabilidades como `postfix`, `avahi-daemon` y `cockpit`.
3. **Firewall Estricto:** Activación y configuración selectiva de `firewalld`, permitiendo únicamente los puertos legítimos de cada rol (22, 80, 443, 1514, 1515) sin comprometer el acceso de los administradores.
4. **Restricción de Acceso Remoto:** Hardening del servicio SSH (`sshd_config`), bloqueando el acceso directo del usuario `root` desde el exterior y limitando los reintentos de autenticación.

## Requisitos Previos

* El script debe ser ejecutado obligatoriamente en la **VM2 (Wazuh Manager)**.
* Disponer de las credenciales de un usuario administrador (con permisos de sudo) en la VM1.

## Modo de Uso

1. Clona este repositorio en tu máquina virtual Wazuh Manager (VM2):
   ```bash
   git clone <URL_DE_TU_REPOSITORIO_GITHUB>
   cd ansible-hardening-lab
