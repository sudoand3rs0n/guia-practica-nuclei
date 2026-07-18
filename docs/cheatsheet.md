# 📋 Cheatsheet — Comandos esenciales de Nuclei

Referencia rápida de los flags y comandos de Nuclei más usados en el día a día de reconocimiento
y análisis de vulnerabilidades.

---

## 1. Escaneo básico

```bash
# Contra un único objetivo
nuclei -u https://target.local

# Contra una lista de objetivos (uno por línea)
nuclei -l targets.txt

# Combinando con httpx (pipe directo)
cat targets.txt | httpx -silent | nuclei
```

---

## 2. Filtrado por severidad

```bash
# Solo críticas y altas
nuclei -l targets.txt -s critical,high

# Excluir informativas y bajas
nuclei -l targets.txt -es info,low
```

Valores válidos de severidad: `info`, `low`, `medium`, `high`, `critical`.

---

## 3. Filtrado por tags / categorías

```bash
# Solo templates de CVEs y exposiciones
nuclei -l targets.txt -tags cve,exposure

# Excluir una categoría concreta
nuclei -l targets.txt -etags dos,fuzz

# Buscar templates disponibles por tag
nuclei -tl -tags wordpress
```

Tags habituales: `cve`, `exposure`, `misconfig`, `default-login`, `panel`, `takeover`,
`tech`, `wordpress`, `sqli`, `xss`, `lfi`, `ssrf`.

---

## 4. Selección y exclusión de templates

```bash
# Ejecutar solo una carpeta/template concreto
nuclei -u https://target.local -t cves/2023/

# Ejecutar un template específico
nuclei -u https://target.local -t cves/2023/CVE-2023-XXXXX.yaml

# Excluir un template o carpeta
nuclei -l targets.txt -et exposures/logs/

# Listar templates disponibles sin ejecutar
nuclei -tl
```

---

## 5. Detección de tecnologías previa (fingerprint)

```bash
# Ejecutar solo templates de detección de tecnología
nuclei -l targets.txt -tags tech

# Combinarlo con httpx para enriquecer el fingerprint
httpx -l targets.txt -tech-detect -json -o httpx_out.json
```

---

## 6. Formatos de salida

```bash
# Salida en JSON Lines (una línea JSON por hallazgo)
nuclei -l targets.txt -jsonl -o resultados.jsonl

# Salida en formato SARIF (integrable en pipelines CI/CD)
nuclei -l targets.txt -sarif-export resultados.sarif

# Guardar salida en texto plano
nuclei -l targets.txt -o resultados.txt

# Silenciar el banner/logo inicial
nuclei -l targets.txt -silent
```

---

## 7. Rendimiento y control de carga

```bash
# Limitar peticiones por segundo (rate-limit)
nuclei -l targets.txt -rl 50

# Controlar la concurrencia de templates en paralelo
nuclei -l targets.txt -c 25

# Controlar el bulk-size (hosts en paralelo por template)
nuclei -l targets.txt -bs 25

# Timeout por petición
nuclei -l targets.txt -timeout 10
```

> ⚠️ En laboratorios propios se puede ser agresivo con la concurrencia, pero en entornos
> productivos ajusta siempre `-rl` para no generar una denegación de servicio involuntaria.

---

## 8. Estadísticas y monitorización de la ejecución

```bash
# Mostrar estadísticas en tiempo real durante el escaneo
nuclei -l targets.txt -stats

# Exponer métricas en un puerto para monitorización externa
nuclei -l targets.txt -stats -stats-json -metrics-port 9092
```

---

## 9. Modo debug / verbose (para depurar templates)

```bash
# Ver la petición y respuesta completa de cada template
nuclei -u https://target.local -t misconfig/ -debug

# Modo verbose para más detalle de ejecución
nuclei -u https://target.local -v
```

---

## 10. Autenticación y headers personalizados

```bash
# Añadir una cookie de sesión
nuclei -u https://target.local -H "Cookie: PHPSESSID=xxxxx"

# Añadir varios headers desde un fichero
nuclei -u https://target.local -H headers.txt
```

---

## 11. Combinaciones útiles del día a día

```bash
# Recon rápido: solo CVEs críticos/altos, salida JSON, con stats
nuclei -l targets.txt -tags cve -s critical,high -jsonl -o cve_high.jsonl -stats

# Escaneo silencioso apto para cron/automatización
nuclei -l targets.txt -silent -jsonl -o "scan_$(date +%F).jsonl"

# Actualizar todo antes de escanear
nuclei -update && nuclei -update-templates && nuclei -l targets.txt
```

---

## 12. Referencia rápida de flags clave

| Flag                  | Descripción                                      |
|------------------------|---------------------------------------------------|
| `-u`                   | Objetivo único                                     |
| `-l`                   | Lista de objetivos desde fichero                   |
| `-t`                   | Template(s) o carpeta de templates a ejecutar      |
| `-et` / `-etags`       | Excluir template(s) / tags                         |
| `-s`                   | Filtrar por severidad                              |
| `-tags`                | Filtrar por tags                                   |
| `-o`                   | Fichero de salida                                  |
| `-jsonl`               | Salida en JSON Lines                               |
| `-silent`              | Oculta banner, solo resultados                     |
| `-stats`               | Muestra estadísticas de ejecución                  |
| `-rl`                  | Rate limit (peticiones/segundo)                    |
| `-c`                   | Concurrencia (templates en paralelo)               |
| `-timeout`             | Timeout por petición (segundos)                    |
| `-update-templates`    | Actualiza el repositorio de templates              |
| `-tl`                  | Lista templates disponibles                        |

Consulta el laboratorio práctico completo en [`labs/ejecucion.md`](../labs/ejecucion.md).
