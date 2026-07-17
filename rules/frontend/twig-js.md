# Convenciones Twig / Symfony UX / JavaScript

**Alcance de la regla:** se carga bajo demanda al tocar `templates/**`, `assets/**`.

## Twig — cero lógica de negocio
- Las plantillas renderizan datos ya preparados por el controlador/servicio. Si una plantilla necesita un `if` con más de una condición de negocio, esa lógica debería vivir en el controlador o en una extensión Twig (`AbstractExtension`), no en la plantilla.
- `|raw` solo tras sanitización explícita y documentada — es el vector de XSS más común en proyectos Symfony.

## Pipeline de assets — uno solo por proyecto
Symfony 6.4 soporta tanto Webpack Encore como AssetMapper. **Confirma cuál usa el proyecto antes de escribir una sola línea de asset** (`importmap.php` existe → AssetMapper; `webpack.config.js` existe → Encore). Nunca introduzcas el otro sin que el usuario lo pida explícitamente — mezclar ambos duplica el build y rompe el caché de producción.

## Stimulus
- Un controller por responsabilidad — si un controller Stimulus supera ~100 líneas o mezcla dos comportamientos no relacionados, divídelo.
- `static targets`/`static values` para leer del DOM, nunca `querySelector` disperso dentro del controller.
- Sin dependencia de jQuery ni manipulación directa del DOM fuera de los targets declarados.

## Turbo
- Turbo Frames para actualizar una sección sin recargar toda la página; Turbo Streams para respuestas que actualizan múltiples fragmentos tras una acción (crear/borrar).
- Un endpoint que responde a Turbo Stream declara explícitamente el `Content-Type: text/vnd.turbo-stream.html` — no asumas que Turbo lo infiere solo.

## Formularios
- Usa `form_start()/form_end()` y los helpers de tema de formulario de Symfony — no reconstruyas manualmente el HTML de un `FormType` ya generado por el framework.
- Todo formulario que muta estado lleva protección CSRF activa (por defecto en el componente Form; no la desactives salvo justificación explícita revisada por `adversarial`).

## CSS
- Sigue la convención ya presente en el proyecto (BEM, utility-first, o CSS Modules vía Encore) — no mezcles convenciones dentro del mismo componente.
