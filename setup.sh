#!/bin/bash

echo "===================================================="
# HARDENING AUTOMATION SYSTEM (EJECUCIÓN CON PRIVILEGIOS SUDO)
echo "===================================================="

# 1. VERIFICACIÓN E INSTALACIÓN DE ANSIBLE Y COLECCIONES
if ! command -v ansible &> /dev/null; then
    echo "[INFO] Ansible no está instalado. Iniciando instalación con sudo..."
    sudo dnf install epel-release -y --setopt=ip_resolve=4
    sudo dnf install ansible-core -y --setopt=ip_resolve=4
    if [ $? -eq 0 ]; then
        echo "[OK] Ansible se instaló correctamente."
    else
        echo "[ERROR] Falló la instalación de Ansible. Revisa la conexión a internet o los repositorios."
        exit 1
    fi
else
    echo "[OK] Ansible ya está instalado en el sistema."
fi

# Instalar de forma explícita la colección requerida para la gestión de firewalld
echo "[INFO] Verificando e instalando la colección ansible.posix con sudo..."
sudo ansible-galaxy collection install ansible.posix

# 2. VERIFICACIÓN DE CONEXIÓN SSH HACIA LA VM1 (SERVIDOR WEB)
echo ""
echo "--- Configuración de conectividad con el Servidor Web (VM1) ---"
read -p "Introduce el usuario SSH de la VM1 (ej. user1): " WEB_USER
read -p "Introduce la dirección IP de la VM1: " WEB_IP

echo "[INFO] Verificando acceso SSH sin contraseña desde el entorno root hacia $WEB_USER@$WEB_IP..."

# Evalúa si el usuario root (vía sudo) ya cuenta con acceso directo por llave
sudo ssh -o PasswordAuthentication=no -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new "${WEB_USER}@${WEB_IP}" "exit" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[OK] Acceso por llave SSH verificado con éxito."
else
    echo "[WARN] No se detectó acceso sin contraseña para root. Configurando llaves SSH..."
    
    # Genera el par de llaves en /root/.ssh si no existen
    if [ ! -f /root/.ssh/id_rsa ]; then
        echo "[INFO] Generando par de llaves RSA para el entorno root..."
        sudo ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
    fi
    
    # Copia la llave pública de root al nodo remoto
    echo "[INFO] Copiando llave SSH a la VM1. Introduce la contraseña del usuario remoto si se solicita:"
    sudo ssh-copy-id "${WEB_USER}@${WEB_IP}"
    
    # Validación final de la conexión
    sudo ssh -o PasswordAuthentication=no -o ConnectTimeout=3 "${WEB_USER}@${WEB_IP}" "exit" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[OK] Llave SSH copiada y verificada correctamente."
    else
        echo "[ERROR] No se pudo establecer el acceso SSH sin contraseña. Revisa la configuración del servicio remoto."
        exit 1
    fi
fi

# 3. ACTUALIZACIÓN DINÁMICA DEL INVENTARIO DE LA VM1
echo "[INFO] Actualizando archivo de inventario con los datos provistos..."
cat << EOF > web-server/inventory.ini
[web_server]
${WEB_IP} ansible_user=${WEB_USER}
EOF
echo "[OK] Inventario web-server/inventory.ini actualizado."

# 4. MENÚ DE EJECUCIÓN DE PLAYBOOKS
echo ""
echo "===================================================="
echo "Selecciona una opción para aplicar la línea base:"
echo "1) Hardening del Wazuh Manager (VM2 - Localhost)"
echo "2) Hardening del Servidor Web (VM1 - Remoto)"
echo "3) Hardening Completo (Ambas VMs)"
echo "4) Salir"
echo "===================================================="
read -p "Opción [1-4]: " OPCION

case $OPCION in
    1)
        echo "[EJECUCIÓN] Iniciando Hardening en Wazuh Manager con sudo..."
        sudo ansible-playbook -i wazuh-manager/inventory.ini wazuh-manager/hardening_manager.yml
        ;;
    2)
        echo "[EJECUCIÓN] Iniciando Hardening en Servidor Web con sudo..."
        sudo ansible-playbook -i web-server/inventory.ini web-server/hardening_web.yml -K
        ;;
    3)
        echo "[EJECUCIÓN] Orquestando Hardening Completo en ambas plataformas con sudo..."
        sudo ansible-playbook -i wazuh-manager/inventory.ini wazuh-manager/hardening_manager.yml
        sudo ansible-playbook -i web-server/inventory.ini web-server/hardening_web.yml -K
        ;;
    4)
        echo "Proceso finalizado por el usuario."
        exit 0
        ;;
    *)
        echo "Opción no válida."
        exit 1
        ;;
esac
