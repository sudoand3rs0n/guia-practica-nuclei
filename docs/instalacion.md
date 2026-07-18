# 🔧 Instalación de Nuclei

Este documento cubre las tres formas más comunes de instalar Nuclei (Go, binario precompilado y
Docker), además de la gestión y actualización de templates, que es tan importante como la
instalación de la herramienta en sí.

---

## 1. Requisitos previos

- Sistema operativo Linux (recomendado, ej. Kali Linux) o macOS/Windows con WSL.
- Conexión a internet para descargar la herramienta y los templates.
- Go >= 1.21 (solo si se instala vía `go install`).

Comprobar si Go está instalado:

```bash
go version
```

Si no lo está, en Debian/Kali:

```bash
sudo apt update
sudo apt install golang-go -y
```

---

## 2. Instalación vía Go (recomendada)

Es la forma más directa de tener siempre la última versión estable:

```bash
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
```

Asegúrate de que el directorio de binarios de Go esté en tu `PATH`:

```bash
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc
```

Verifica la instalación:

```bash
nuclei -version
```

---

## 3. Instalación vía binario precompilado

Alternativa si no quieres depender de Go. Descarga el release correspondiente a tu sistema desde
la [página oficial de releases](https://github.com/projectdiscovery/nuclei/releases) y descomprime:

```bash
wget https://github.com/projectdiscovery/nuclei/releases/download/vX.Y.Z/nuclei_X.Y.Z_linux_amd64.zip
unzip nuclei_X.Y.Z_linux_amd64.zip
sudo mv nuclei /usr/local/bin/
nuclei -version
```

> Sustituye `X.Y.Z` por la versión estable más reciente publicada en el repositorio oficial.

---

## 4. Instalación vía Docker

Útil si prefieres no instalar dependencias en tu sistema o quieres integrarlo en un pipeline
CI/CD:

```bash
docker pull projectdiscovery/nuclei:latest

docker run -it projectdiscovery/nuclei:latest -u https://target.local
```

Para persistir los templates entre ejecuciones, monta un volumen:

```bash
docker run -it -v $(pwd)/nuclei-templates:/root/nuclei-templates \
  projectdiscovery/nuclei:latest -u https://target.local
```

---

## 5. Descarga y actualización de templates

Nuclei separa el **motor** de los **templates**. Tras instalar el binario, es imprescindible
descargar (y mantener actualizado) el repositorio de templates:

```bash
# Descarga/actualiza los templates a la última versión
nuclei -update-templates

# Actualiza el propio binario de Nuclei
nuclei -update
```

Por defecto, los templates se guardan en `~/nuclei-templates`. Puedes apuntar a una ruta
personalizada con `-templates-directory` o usar un set de templates propio/custom con `-t`.

> 💡 Buena práctica: automatiza `nuclei -update-templates` como tarea programada (cron) antes de
> cada sesión de reconocimiento, ya que se publican templates nuevos con mucha frecuencia
> (especialmente para CVEs recientes).

---

## 6. Herramientas complementarias del pipeline

Para completar el pipeline de reconocimiento (`subfinder` → `httpx` → `nuclei`), instala también:

```bash
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
```

Con esto tendrás el trío base `subfinder` + `httpx` + `nuclei` operativo.

---

## 7. Verificación final

```bash
subfinder -version
httpx -version
nuclei -version
```

Si los tres comandos devuelven versión sin errores, el entorno está listo para pasar al
[laboratorio práctico](../labs/lab-setup.md).
