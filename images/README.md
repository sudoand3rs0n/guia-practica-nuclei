# 📸 Carpeta de imágenes

Capturas reales del laboratorio, tomadas ejecutando cada paso contra el entorno descrito en
[`labs/lab-setup.md`](../labs/lab-setup.md) (Kali + bWAPP en Docker sobre VMware). Están
referenciadas e insertadas directamente en `labs/lab-setup.md`, `labs/ejecucion.md`,
`labs/hallazgos.md` y `docs/plantillas-personalizadas.md`.

## Índice de capturas

### Desde `labs/lab-setup.md`
- `lab-docker-ps.png` — contenedor bWAPP activo (`docker ps`).
- `lab-bwapp-login.png` — portal de bWAPP tras iniciar sesión con `bee`/`bug`.

> La topología de red (Kali/Ubuntu en VMware, modo NAT) se describe en texto directamente en
> `labs/lab-setup.md`, sección "Diagrama de red" — no lleva captura.

### Desde `labs/ejecucion.md`
- `lab-httpx-output.png` — fingerprint del objetivo con `httpx`.
- `lab-nuclei-scan-inicial-inicio.png` / `lab-nuclei-scan-inicial-fin.png` — escaneo amplio inicial
  (inicio y fin, en dos capturas por la longitud del output).
- `lab-nuclei-scan-dirigido.png` — escaneo dirigido detectando `CVE-2024-47176` (CUPS RCE).
- `lab-nuclei-hallazgo-detalle-1.png` / `-2.png` — detalle `-debug` de la plantilla de SQLi (login
  y petición/respuesta con el error, en dos capturas).
- `lab-nuclei-recoleccion-o.png` — recolección de resultados con `-o` antes del resumen final.
- `lab-resultados-resumen.png` — resumen de hallazgos por severidad con `jq`.

### Desde `docs/plantillas-personalizadas.md`
- `custom-templates-listado.png` — las 4 plantillas propias en `custom-templates/`.

### Desde `labs/hallazgos.md`
- `hallazgo-bwapp-nuclei.png` — las 4 plantillas de bWAPP disparando a la vez
  (`nuclei -u <target> -t custom-templates/`), con los 4 hallazgos confirmados en una sola
  captura.
- `hallazgo-sqli-manual.png` — bypass booleano (`or '1'='1'`) reproducido en el navegador,
  devolviendo todos los registros de la base de datos.

> El CVE de CUPS ya queda documentado con `lab-nuclei-scan-dirigido.png`, no lleva captura propia.
