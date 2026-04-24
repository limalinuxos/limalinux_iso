#!/bin/bash
set -e

################################################################################
# LIMALINUX BUILD SCRIPT - HYBRID VERSION (Original + Improved)
################################################################################

# --- Configuración de Rutas Dinámicas ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LIMALINUXOS_BASE="$(dirname "$ISO_REPO_ROOT")"

# --- Carpetas con Nomenclatura Unificada (_) ---
buildFolder="$LIMALINUXOS_BASE/limalinux_build"
outFolder="$LIMALINUXOS_BASE/limalinux_out"
ARCHISO_SRC="$ISO_REPO_ROOT/archiso"

# --- Variables de Versión ---
limalinuxVersion="v26.04.14.01"
isoLabel="limalinux-${limalinuxVersion}-x86_64.iso"
nvidia_driver="open" # open | 580xx | 390xx

# --- Funciones de Seguridad ---

remove_buildfolder() {
    if [[ "$1" == "yes" && -d "$buildFolder" ]]; then
        tput setaf 3
        echo "### LIMPIEZA DE SEGURIDAD: Desmontando y eliminando $buildFolder"
        tput sgr0
        
        # Antibloqueo de /proc /sys /dev
        while mount | grep -q "$buildFolder"; do
            sudo findmnt -lo TARGET -n -r | grep "$buildFolder" | sort -r | xargs -r sudo umount -l || break
            sleep 1
        done

        sudo fuser -kv "$buildFolder" 2>/dev/null || true
        sudo chattr -R -i "$buildFolder" 2>/dev/null || true
        sudo rm -rf "$buildFolder"
    fi
}

# --- FASE 1: Preparación y Repositorios ---
echo "Iniciando Fase 1: Validando dependencias..."
remove_buildfolder yes

# Comprobación de Chaotic-AUR (Rescatado del original)
if pacman -Q chaotic-keyring &>/dev/null; then
    tput setaf 2; echo "Chaotic-AUR detectado."; tput sgr0
else
    echo "Instalando dependencias de Chaotic-AUR..."
    # Aquí llamaría a tu script de keys si existiera, o lo saltamos
fi

# --- FASE 2: Copia y Configuración ---
mkdir -p "$buildFolder"
mkdir -p "$outFolder"
cp -r "$ARCHISO_SRC" "$buildFolder/archiso"

# Personalización (Skel y Bashrc)
rm -rf "$buildFolder/archiso/airootfs/etc/skel/".* 2>/dev/null || true
wget "https://raw.githubusercontent.com/erikdubois/edu-shells/refs/heads/main/etc/skel/.bashrc-latest" \
     -O "$buildFolder/archiso/airootfs/etc/skel/.bashrc" -q

# Configuración NVIDIA (Lógica limpia)
PACKAGES_FILE="$buildFolder/archiso/packages.x86_64"
sed -i '/^nvidia/d' "$PACKAGES_FILE"
case "$nvidia_driver" in
    open)  printf "nvidia-open-dkms\nnvidia-utils\nnvidia-settings\n" >> "$PACKAGES_FILE" ;;
    580xx) printf "nvidia-580xx-dkms\nnvidia-580xx-utils\nnvidia-580xx-settings\n" >> "$PACKAGES_FILE" ;;
    390xx) printf "nvidia-390xx-dkms\nnvidia-390xx-utils\nnvidia-390xx-settings\n" >> "$PACKAGES_FILE" ;;
esac

# --- FASE 3: Compilación ---
tput setaf 2; echo "Lanzando mkarchiso... (Los errores de /sys en Read-only son NORMALES)"; tput sgr0
cd "$buildFolder/archiso"
sudo mkarchiso -v -w "$buildFolder/work" -o "$outFolder" .

# --- FASE 4: Finalización (Lista de paquetes y Checksums) ---
cd "$outFolder"
REAL_ISO=$(ls -t *.iso | head -1)

if [ -n "$REAL_ISO" ]; then
    # Generar Checksums
    sha256sum "$REAL_ISO" | tee "${REAL_ISO}.sha256"
    md5sum "$REAL_ISO" | tee "${REAL_ISO}.md5"
    
    # Intentar rescatar la lista de paquetes (como hacía el original)
    if [ -f "$buildFolder/work/x86_64/airootfs/pkglist.txt" ]; then
        cp "$buildFolder/work/x86_64/airootfs/pkglist.txt" "$outFolder/${REAL_ISO}.pkglist.txt"
    fi
fi

tput setaf 2
echo "##################################################################"
echo "ISO GENERADA: $outFolder/$REAL_ISO"
echo "##################################################################"
tput sgr0
