# 🎓 Funcionalidades avanzadas (y lo que aprendí usándolas)

La documentación oficial de Nuclei cubre bien los flags básicos, pero hay un puñado de
funcionalidades que solo se aprecian de verdad cuando te encuentras con el problema que resuelven.
Esta sección recoge esas funcionalidades a partir de casos reales de este mismo laboratorio, no
como un resumen de la documentación.

---

## 1. Detección fuera de banda (OOB) con Interactsh

La mayoría de guías de Nuclei se centran en matchers sobre la respuesta HTTP directa (código de
estado, palabra en el body...). Pero hay vulnerabilidades que **no producen ninguna respuesta
observable en la misma conexión** — solo se confirman si el servidor vulnerable, como efecto
secundario, hace una petición saliente hacia un servidor que tú controlas.

Eso es exactamente lo que pasó en este laboratorio con `CVE-2024-47176` (CUPS RCE): la plantilla
pública no comprueba nada en la respuesta HTTP normal, sino que envía un paquete que hace que el
servicio vulnerable contacte a una URL de callback. Nuclei gestiona esto automáticamente con
**Interactsh** (su propio servidor de interacciones OOB, por defecto `oast.pro`/`oast.live`, o uno
propio autoalojado con `-interactsh-url`):

```bash
nuclei -u http://192.168.184.128 -t javascript/cves/2024/CVE-2024-47176.yaml -debug
```

En el log verás `[INF] Using Interactsh Server: oast.pro`, y si el callback llega, el hallazgo se
marca como confirmado sin que tú hayas tenido que interceptar nada manualmente. Esto es
especialmente valioso para SSRF, RCE ciegas, XXE y exfiltración de datos — categorías donde un
matcher sobre la respuesta directa simplemente no existe.

**Criterio propio**: si vas a escanear un objetivo en una red restringida o air-gapped, esta
técnica no funcionará contra `oast.pro` público (no hay salida a internet) — en ese caso hace
falta un servidor Interactsh propio dentro de la misma red, algo que la documentación oficial
menciona de pasada pero que en la práctica es la diferencia entre "funciona" y "no detecta nada y
no sabes por qué".

---

## 2. Encadenar peticiones autenticadas con `cookie-reuse`

Un problema muy real y muy poco documentado: **la mayoría de aplicaciones vulnerables de
entrenamiento (bWAPP incluida) están detrás de login**. Un template de una sola petición nunca va
a alcanzar el endpoint vulnerable si antes no hay una sesión autenticada.

La solución con la que me encontré escribiendo `custom-templates/bwapp-sqli-post-search.yaml`:
declarar varias peticiones dentro del mismo bloque `http:`, con `cookie-reuse: true` en cada una,
para que las cookies devueltas por la primera petición (login) se reutilicen automáticamente en la
segunda:

```yaml
http:
  - cookie-reuse: true
    method: POST
    path:
      - "{{BaseURL}}/login.php"
    body: "login=bee&password=bug&security_level=0&form=submit"

  - cookie-reuse: true
    method: POST
    path:
      - "{{BaseURL}}/sqli_6.php"
    body: "title=nuclei'&action=search"
    matchers:
      - type: word
        part: body
        words:
          - "SQL syntax"
```

Sin `cookie-reuse: true` en ambas peticiones, la segunda petición se ejecuta sin sesión y el
servidor simplemente redirige a `login.php` — el template nunca dispara, y el fallo es silencioso
(no hay ningún error, solo "no results found"), lo cual puede llevar a un falso negativo si no
sabes que debes sospechar de un login previo.

---

## 3. `flow:` — lógica condicional en JavaScript (alternativa más avanzada)

Para casos más complejos que un simple "login y luego ataca" (por ejemplo, extraer un token CSRF
de la respuesta de login y usarlo condicionalmente, o repetir una petición solo si la anterior
cumplió cierta condición), Nuclei v3 permite añadir un bloque `flow:` con lógica en JavaScript que
controla qué peticiones se ejecutan y en qué orden:

```yaml
flow: http(1) && http(2)
```

Esto no era necesario para los templates de este repositorio (el `cookie-reuse` simple bastaba),
pero es la herramienta correcta cuando la lógica de autenticación o encadenado es más compleja que
"reutilizar la cookie de la petición anterior" — por ejemplo, aplicaciones con tokens
anti-CSRF de un solo uso que hay que extraer con un `extractor` antes de la segunda petición.

---

## 4. Firma de templates y confianza en la cadena de suministro

Al ejecutar cualquier template propio (no descargado del repositorio oficial firmado de
ProjectDiscovery), Nuclei avisa:

```
[WRN] Loading 1 unsigned templates for scan. Use with caution.
```

Esto no es un simple mensaje decorativo: Nuclei firma criptográficamente los templates oficiales
para que un atacante no pueda colar un template malicioso (que, recuerda, puede ejecutar
peticiones arbitrarias, y con el protocolo `code:`/`javascript:` incluso código) en tu pipeline de
escaneo a través de un repositorio de templates de terceros comprometido. La recomendación
práctica:

- Revisa siempre el contenido de un template de terceros antes de ejecutarlo (igual que revisarías
  una dependencia de npm/pip nueva).
- Firma tus propios templates con `nuclei -sign` si los vas a distribuir o reutilizar en un
  pipeline compartido con el equipo (`-tsc`/`-templates-signature-check` para validar la firma).
- No desactives esta advertencia por comodidad en un entorno que no sea tu propio laboratorio.

---

## 5. Workflows: orquestar plantillas condicionalmente

Cuando el objetivo es amplio (varios hosts con tecnologías distintas), lanzar todo el catálogo de
templates a ciegas es ineficiente y ruidoso. Un `workflow` permite condicionar qué templates se
ejecutan según lo que detecte un template anterior — por ejemplo, ejecutar los templates de
WordPress **solo** si el fingerprint inicial detectó WordPress:

```yaml
workflows:
  - template: http/technologies/wordpress-detect.yaml
    matchers:
      - name: wordpress
        subtemplates:
          - template: http/cves/wordpress/
```

Es el equivalente en una sola herramienta a la lógica "escaneo amplio → dirigido" que ya seguimos
manualmente en [`labs/ejecucion.md`](../labs/ejecucion.md) — pero automatizada dentro del propio
motor de Nuclei, útil cuando ese pipeline se convierte en algo recurrente (cron, CI/CD).

---

## 6. Buenas prácticas para el día a día como analista

- Usa `-project` para cachear respuestas HTTP entre ejecuciones repetidas contra el mismo objetivo
  — evita repetir peticiones idénticas si relanzas el escaneo varias veces mientras ajustas tags.
- Integra `notify` (o un script propio sobre la salida `-jsonl`) para enviar hallazgos críticos a
  Slack/Discord/Jira automáticamente en escaneos programados — pasar de "tengo un fichero JSON" a
  "el equipo se entera en tiempo real" es lo que separa un script de un proceso operativo real.
- Ante un "no results found" inesperado, antes de asumir que el objetivo no es vulnerable,
  verifica con `-debug` si la petición está llegando autenticada, sin redirecciones inesperadas y
  con el payload bien formado — la mayoría de falsos negativos en este laboratorio vinieron de ahí,
  no de que el template estuviera mal escrito.
