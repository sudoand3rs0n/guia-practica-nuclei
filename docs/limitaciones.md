# 🚧 Limitaciones de Nuclei

Entender las limitaciones de una herramienta es tan importante como saber usarla. Esta sección
recoge, de forma honesta, dónde Nuclei aporta más valor y dónde no debería ser la única pieza del
proceso de análisis de vulnerabilidades.

---

## 1. Dependencia total de los templates

Nuclei **solo detecta lo que un template sabe buscar**. Si una vulnerabilidad no tiene un
template escrito (porque es demasiado reciente, demasiado específica del negocio, o simplemente
nadie la ha documentado todavía), Nuclei no la va a encontrar, por muy real y crítica que sea.

Implicaciones prácticas:

- La calidad del escaneo depende directamente de mantener `nuclei-templates` actualizado.
- Vulnerabilidades de lógica de negocio (por ejemplo, un IDOR específico de la aplicación, un
  bypass de autorización particular) **no** son detectables por templates genéricos: requieren
  análisis manual o templates a medida.
- Un resultado "limpio" (sin hallazgos) **no significa que el sistema esté libre de
  vulnerabilidades**, solo que no coincide con ningún template ejecutado.

---

## 2. Falsos positivos

Como cualquier escáner automatizado basado en matchers (comparación de respuestas, códigos de
estado, patrones de texto, etc.), Nuclei puede generar falsos positivos, especialmente en:

- Templates que dependen de mensajes de error genéricos que otras aplicaciones también producen
  por razones distintas.
- Entornos con WAF, balanceadores o páginas de error personalizadas que alteran la respuesta
  esperada por el template.
- Templates mal escritos o con matchers demasiado laxos (más frecuente en templates comunitarios
  no oficiales).

**Mitigación**: nunca reportar un hallazgo de Nuclei sin confirmarlo antes con `-debug` (o una
plantilla propia si la pública no basta) contra la respuesta real del objetivo.

---

## 3. Falsos negativos

Igual de importante que los falsos positivos, y a menudo más peligroso:

- Templates desactualizados no detectan variantes nuevas de una vulnerabilidad conocida.
- Configuraciones no estándar (rutas custom, autenticación previa requerida, aplicaciones tras
  proxies complejos) pueden hacer que un template "falle en silencio" sin lanzar ningún error
  visible.
- Rate-limiting agresivo por parte del objetivo puede hacer que ciertas peticiones no lleguen a
  completarse correctamente.

---

## 4. Alcance limitado frente a un escáner de infraestructura

Nuclei está diseñado principalmente para **aplicaciones web, APIs y servicios expuestos por
HTTP/HTTPS** (con soporte adicional para otros protocolos vía templates específicos). No es un
escáner de vulnerabilidades de sistema operativo, red o cumplimiento normativo comparable a
soluciones enterprise.

---

## 5. ¿Para qué usar Nuclei? ¿Para qué NO?

### ✅ Úsalo para:

- Reconocimiento rápido y a gran escala de activos expuestos.
- Detección de CVEs conocidos y ampliamente documentados.
- Identificación de exposiciones de configuración (paneles por defecto, ficheros sensibles,
  credenciales por defecto).
- Validación continua dentro de pipelines CI/CD (shift-left security).
- Triage inicial en la fase temprana de un pentest, para priorizar dónde profundizar
  manualmente.

### ❌ No lo uses como única herramienta en:

- Auditorías formales de cumplimiento normativo (PCI-DSS, ISO 27001, ENS, etc.), que exigen
  escáneres certificados y trazabilidad específica.
- Análisis de lógica de negocio o flujos de autorización complejos.
- Evaluaciones de seguridad de infraestructura completa (sistema operativo, servicios de red no
  HTTP, hardening de configuración a nivel de SO).
- Cualquier contexto donde se requiera un informe con validez ante un tercero regulador, sin
  acompañarlo de un proceso de verificación manual y una herramienta comercial certificada.

---

## 6. Comparativa detallada con Nessus y OpenVAS

| Aspecto                    | Nuclei                                  | Nessus                                   | OpenVAS                                  |
|------------------------------|-------------------------------------------|---------------------------------------------|---------------------------------------------|
| Tipo de licencia             | Open source (MIT)                          | Comercial (Essentials gratis y limitado)     | Open source (GPL, vía Greenbone)             |
| Modelo de detección          | Templates YAML declarativos, comunitarios  | Plugins propietarios, motor cerrado          | NASL scripts + feed NVT (Greenbone Community)|
| Foco principal               | Aplicaciones web / APIs / recon a escala   | Infraestructura, SO, red, aplicaciones        | Infraestructura, SO, red                     |
| Velocidad de escaneo         | Muy alta (alta concurrencia nativa)         | Media                                         | Media-baja                                    |
| Facilidad de automatización  | Muy alta (CLI-first, ideal para CI/CD)      | Media (API disponible, más pesada)            | Media (API disponible)                        |
| Calidad de reporting         | Básico (JSON/JSONL/SARIF, requiere post-proc)| Avanzado, informes ejecutivos listos          | Avanzado, informes detallados                 |
| Actualización de detección   | Comunidad + ProjectDiscovery, muy ágil      | Equipo de Tenable, ágil pero cerrado           | Feed de Greenbone, algo más lento             |
| Curva de aprendizaje         | Baja-media                                  | Media                                         | Media-alta                                    |
| Coste                        | Gratuito                                    | Licencia de pago (Professional)               | Gratuito (versión Community)                  |
| Uso recomendado               | Recon continuo, CVEs, CI/CD, pentest inicial| Auditorías formales, compliance, infraestructura| Auditorías formales, compliance, infraestructura|

**Conclusión**: Nuclei y los escáneres tradicionales (Nessus, OpenVAS) **no son competidores
directos, sino complementarios**. Un flujo de trabajo maduro combina reconocimiento ágil con
Nuclei para la superficie web/API, con auditorías periódicas más profundas mediante un escáner de
infraestructura certificado cuando el contexto (cumplimiento, alcance, criticidad) lo requiere.
