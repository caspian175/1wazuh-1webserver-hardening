#!/bin/bash

# Asegurar que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Este script debe ejecutarse con privilegios de root (sudo ./setup.sh)."
  exit 1
fi

echo "===================================================="
# HARDENING AUTOMATION SYSTEM
echo "===================================================="

# 1. VERIFICACIÓN E INSTALACIÓN DE ANSIBLE
if ! command -v ansible &> /dev/null; then
    echo "[INFO] Ansible no está instalado. Iniciando instalación..."
    dnf install epel-release -y --setopt=ip_resolve=4
    dnf install ansible-core -y --setopt=ip_resolve=4
    if [ $? -eq 0 ]; then
        echo "[OK] Ansible se instaló correctamente."
    else
        echo "[ERROR] Falló la instalación de Ansible. Revisa la conexión a internet."
        exit 1
    fi
else
    echo "[OK] Ansible ya está instalado en el sistema."
fi

# 2. VERIFICACIÓN DE CONEXIÓN SSH HACIA LA VM1 (SERVIDOR WEB)
echo ""
echo "--- Configuración de conectividad con el Servidor Web (VM1) ---"
read -p "Introduce el usuario SSH de la VM1 (ej. user1): " WEB_USER
read -p "Introduce la dirección IP de la VM1: " WEB_IP

echo "[INFO] Verificando si existe acceso SSH sin contraseña hacia $WEB_USER@$WEB_IP..."

# Intenta conectar sin pedir contraseña
ssh -o PasswordAuthentication=no -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new "${WEB_USER}@${WEB_IP}" "exit" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[OK] Acceso por llave SSH verificado con éxito."
else
    echo "[WARN] No se detectó acceso sin contraseña. Configurando llaves SSH..."
    
    # Generar llave si el root no tiene una creada
    if [ ! -f /root/.ssh/id_rsa ]; then
        echo "[INFO] Generando par de llaves SSH para el usuario root..."
        ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
    fi
    
    # Copiar la llave a la VM1 (solicitará la contraseña por única vez)
    echo "[INFO] Copiando llave SSH a la VM1. Por favor, introduce la contraseña del usuario remoto cuando se te solicite:"
    ssh-copy-id "${WEB_USER}@${WEB_IP}"
    
    # Validar nuevamente
    ssh -o PasswordAuthentication=no -o ConnectTimeout=3 "${WEB_USER}@${WEB_IP}" "exit" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[OK] Llave SSH copiada y verificada correctamente."
    else
        echo "[ERROR] No se pudo establecer el acceso SSH sin contraseña. Revisa las credenciales."
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

# 4. MENÚ DE EJECUCIÓN
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
        echo "[EJECUCIÓN] Iniciando Hardening en Wazuh Manager..."
        ansible-playbook -i wazuh-manager/inventory.ini wazuh-manager/hardening_manager.yml
        ;;
    2)
        echo "[EJECUCIÓN] Iniciando Hardening en Servidor Web..."
        ansible-playbook -i web-server/inventory.ini web-server/hardening_web.yml
        ;;
    3)
        echo "[EJECUCIÓN] Iniciando Hardening en ambos servidores..."
        ansible-playbook -i wazuh-manager/inventory.ini wazuh-manager/hardening_manager.yml
        ansible-playbook -i web-server/inventory.ini web-server/hardening_web.yml
        ;;
    4)
        echo "Proceso cancelado."
        exit 0
        ;;
    *)
        echo "Opción no válida."
        exit 1
        ;;
esac
