#!/bin/bash
# Compila la ISO de Renace OS.
#
#   ./build.sh            Usa Docker (funciona en Linux, macOS y Windows con Docker Desktop)
#   sudo ./build.sh --dentro   Compila directamente (solo en Debian 13, como root)
#
# Resultado: out/renace-os-amd64.iso
set -euo pipefail
cd "$(dirname "$0")"
ORIGEN=$PWD

if [ "${1:-}" != "--dentro" ]; then
    command -v docker >/dev/null || {
        echo "Hace falta Docker, o ejecutar en Debian 13: sudo ./build.sh --dentro" >&2
        exit 1
    }
    exec docker run --rm --privileged -v "$ORIGEN":/src -w /src debian:trixie \
        bash ./build.sh --dentro
fi

[ "$(id -u)" = 0 ] || { echo "Debe ejecutarse como root." >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends live-build debootstrap ca-certificates \
    xorriso squashfs-tools cpio

# Se compila en una carpeta propia de Linux: las carpetas compartidas con
# Windows/macOS no admiten los permisos y dispositivos que necesita el chroot.
TRABAJO=${RENACE_TRABAJO:-/var/tmp/renace-build}
rm -rf "$TRABAJO"
mkdir -p "$TRABAJO"
cp -a "$ORIGEN/auto" "$ORIGEN/config" "$TRABAJO/"
cd "$TRABAJO"

# Los archivos pueden venir de Windows: normalizar fines de línea y permisos
find auto config -type f -exec sed -i 's/\r$//' {} +
chmod 755 auto/*
find config/hooks -type f -exec chmod 755 {} +
chmod 755 config/includes.chroot/usr/local/sbin/* \
          config/includes.chroot/usr/local/bin/* \
          config/includes.chroot/usr/lib/systemd/system-sleep/* \
          config/includes.chroot/usr/share/renace/calamares/*

lb config
lb build 2>&1 | tee "$TRABAJO/build.log" || true   # el fallo se detecta abajo, tras guardar el registro

mkdir -p "$ORIGEN/out"
ISO=$(ls -1 "$TRABAJO"/*.iso 2>/dev/null | head -n1 || true)
if [ -z "$ISO" ]; then
    cp "$TRABAJO/build.log" "$ORIGEN/out/build.log"
    echo "ERROR: no se generó la ISO. Revise out/build.log" >&2
    exit 1
fi
cp "$ISO" "$ORIGEN/out/renace-os-amd64.iso"
cp "$TRABAJO/build.log" "$ORIGEN/out/build.log"
cp "$TRABAJO/chroot/usr/share/renace/opcionales.txt" "$ORIGEN/out/opcionales.txt" 2>/dev/null || true
( cd "$ORIGEN/out" && sha256sum renace-os-amd64.iso > renace-os-amd64.iso.sha256 )
ls -lh "$ORIGEN/out"
echo "Listo: out/renace-os-amd64.iso"
