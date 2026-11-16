# Renace OS

Un sistema operativo ligero, basado en **Debian 13**, para darle una segunda vida a los
**Mac Intel antiguos**. Su foco es el problema que más gente abandona: **el Wi-Fi**.

> **Estado: primera versión, aún sin compilar ni probar en un Mac real.**
> Los scripts pasan la validación de sintaxis, pero la ISO todavía no se ha generado.
> Cuenta con que la primera compilación necesite algún ajuste (ver «Pendiente de verificar»).

## Qué resuelve

| Necesidad | Cómo lo hace Renace OS |
|---|---|
| Wi-Fi de Mac que no funciona en Linux | Todos los controladores Broadcom van **dentro de la ISO** (no hace falta Internet para tener Internet). `renace-wifi` detecta el chip en cada arranque, carga el controlador correcto y, si falla, prueba el siguiente. |
| Poca RAM | Escritorio XFCE, memoria comprimida (zram), servicios innecesarios apagados y protección contra bloqueos por falta de memoria. Objetivo: ~500–700 MB en reposo con escritorio, ~200 MB sin él. |
| Gente que no usa la terminal | **Centro Renace**: una ventana con botones para Wi-Fi, apariencia y modo servidor. Instalador gráfico. Todo en español. |
| Personalizable | Estilo Mac (barra + dock) o clásico (barra abajo), tema claro/oscuro, efectos sí/no, y todos los ajustes de XFCE. |
| Mini servidor / NAS | Un interruptor: no se suspende ni con la tapa cerrada, apaga la pantalla, optimiza la energía y activa NAS, Docker, SSH y panel web. |

## Cómo obtener la ISO

La ISO se compila en Linux. Desde Windows, lo más fácil es dejar que GitHub lo haga gratis:

1. Crea un repositorio en GitHub y sube esta carpeta.
2. En la pestaña **Actions**, elige **«Construir ISO de Renace OS»** → **Run workflow**.
3. Tras 30–60 minutos, descarga `renace-os-iso` desde la página de la ejecución.

Si tienes Docker (o un PC con Debian 13):

```bash
./build.sh
```

El resultado queda en `out/renace-os-amd64.iso`, junto con `out/build.log` y
`out/opcionales.txt` (qué paquetes opcionales entraron y cuáles no).

## Cómo usarla en el Mac

1. Graba la ISO en un USB de 4 GB o más con [balenaEtcher](https://etcher.balena.io/) o Rufus (modo DD).
2. Conecta el USB, enciende el Mac manteniendo pulsada la tecla **Option (⌥)** y elige **EFI Boot**.
3. Renace OS arranca **sin tocar el disco**. Comprueba que el Wi-Fi funciona.
4. Si todo va bien, pulsa **«Instalar Renace OS en este Mac»** en la ventana de bienvenida.

**¿Sin Wi-Fi en el primer arranque?** Conecta un iPhone o Android por cable USB y activa
«Compartir Internet»; funciona sin configurar nada. Luego abre *Centro Renace → Wi-Fi → Reparar*.

## Wi-Fi: chips cubiertos

| Chip | Macs típicos | Controlador por defecto | Alternativa |
|---|---|---|---|
| BCM4311 / 4312 / 4321 / 4322 | MacBook, iMac y Mac mini 2006–2010 | `wl` | `b43` |
| BCM4331 | MacBook Pro 2011–2012, iMac 2011, Mac mini 2011–2012 | `wl` | `b43` |
| BCM43224 / 43225 / 4313 | MacBook Air 2010–2012 | `wl` | `brcmsmac` |
| BCM4360 / 4352 / 43142 / 43227 / 43228 | MacBook Air/Pro 2013–2015, iMac 2013–2015 | `wl` | — |
| BCM4350 / 43602 | MacBook 12", MacBook Pro 2015–2017 | `brcmfmac` | — |
| Atheros AR5xxx / AR9xxx | Algunos Mac 2006–2008 | del kernel | — |

Desde la terminal (opcional):

```bash
renace-wifi estado
```

```bash
sudo renace-wifi reparar
```

```bash
sudo renace-wifi usar b43
```

## Modo servidor

*Centro Renace → Modo servidor*, o:

```bash
sudo renace-mode servidor --nas --docker --cockpit
```

Qué hace siempre:

- **Nunca se suspende**: ni por inactividad, ni al cerrar la tapa, ni con el botón de reposo.
- **Pantalla y teclado apagados** con la tapa cerrada.
- **Energía**: CPU en bajo consumo, ahorro en SATA/USB, y el ahorro de Wi-Fi desactivado
  (es lo que provoca cortes en un servidor).
- **Se recupera solo**: reinicio automático si el kernel se cuelga y parches de seguridad automáticos.
- **Acceso remoto por SSH** y cortafuegos activado.

Opciones:

| Opción | Para qué |
|---|---|
| `--nas` | Carpeta compartida `/srv/nas` visible desde Mac, Windows y Linux, y destino de **Time Machine**. |
| `--docker` | Contenedores para bots de trading, automatizaciones (n8n, Home Assistant…), etc. |
| `--cockpit` | Panel web en `https://IP:9090` para administrar desde otro equipo. |
| `--sin-escritorio` | Arranca sin interfaz gráfica (ahorra ~300 MB de RAM). |
| `--autoencendido` | Se enciende solo cuando vuelve la luz tras un corte. *Experimental.* |

Para volver al uso normal:

```bash
sudo renace-mode escritorio
```

Los archivos de `/srv/nas` no se borran nunca al cambiar de modo.

**Para trading y automatizaciones:** usa cable de red si puedes, activa `--autoencendido` y
recuerda que un Mac en casa depende de tu luz y tu Internet; no ofrece la disponibilidad de un VPS
de centro de datos.

## Límites conocidos

- **Solo Mac Intel de 64 bits** (Core 2 Duo en adelante, 2006–2019 aprox.). No sirve para los
  Core Duo de 32 bits de 2006, los PowerPC ni los Apple Silicon.
- **Mac con chip T2 (2018–2020)**: el Wi-Fi y el teclado necesitan un kernel especial que no se incluye.
- **RAM**: 2 GB es el mínimo razonable para navegar por Internet; la cifra de ~700 MB es el sistema
  en reposo. Un navegador moderno con varias pestañas usa más en cualquier sistema.
- La cámara FaceTime HD de algunos modelos no funciona sin un firmware adicional.

## Pendiente de verificar en la primera compilación

1. Que `broadcom-sta-dkms` compile contra el kernel de Debian 13 dentro del chroot
   (si no, la compilación se detiene a propósito con un error claro).
2. Que `firmware-b43-installer` descargue el firmware durante la compilación
   (si no, queda un aviso y esos chips usan solo `wl`).
3. El arranque EFI de 32 bits (Mac 2006–2008) y que la instalación con Calamares
   deje GRUB arrancable en un Mac real sin red.
4. Las disposiciones de panel de `renace-apariencia` en una sesión XFCE real.
5. El consumo real de RAM en reposo.

## Estructura

```
auto/config                       Opciones de live-build
config/package-lists/             Paquetes de la imagen
config/hooks/normal/              Pasos de compilación (Wi-Fi, opcionales, ajustes)
config/includes.chroot/           Archivos propios de Renace OS
  usr/local/sbin/renace-wifi      Detector y reparador de Wi-Fi
  usr/local/sbin/renace-mode      Modo escritorio / servidor
  usr/local/bin/renace-centro     Panel de control gráfico
  usr/local/bin/renace-apariencia Disposiciones y temas
build.sh                          Compila la ISO
```

Renace OS es Debian con una capa de configuración encima: recibe las mismas actualizaciones
de seguridad y admite los mismos programas.
