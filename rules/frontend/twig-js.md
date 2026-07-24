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
- Un controller aumenta HTML ya existente, no lo genera — si te encuentras construyendo DOM a mano dentro de un controller, esa responsabilidad pertenece a un TwigComponent o LiveComponent, no a Stimulus.
- Si `connect()` añade listeners, timers o instancias de librerías externas, `disconnect()` debe removerlos — sin esto, cada navegación Turbo (que no recarga la página) acumula listeners fantasma de la instancia anterior.
- Con Turbo Drive, `connect()` puede ejecutarse **más de una vez** para el mismo controller (no asumas ciclo de vida de SPA de un solo montaje).
- Values y action params siempre llegan como string desde el DOM: `""` no se castea a `false` en un value `Boolean`, un `data-*-value` con JSON malformado falla en silencio, y un action param `"123"` nunca es `123` — castea explícitamente en el controller.
- Un controller anidado (hijo) bloquea el acceso del controller padre a los targets declarados dentro del scope del hijo — si el padre necesita ese elemento, decláralo como target propio, no dependas del scope del hijo.

## Turbo
- Turbo Frames para actualizar una sección sin recargar toda la página; Turbo Streams para respuestas que actualizan múltiples fragmentos tras una acción (crear/borrar).
- Un endpoint que responde a Turbo Stream declara explícitamente el `Content-Type: text/vnd.turbo-stream.html` — no asumas que Turbo lo infiere solo.
- Redirect tras un POST debe responder **303** (`See Other`), no 302 — con 302 Turbo puede reenviar el método original y duplicar la acción.
- Errores de validación de formulario responden **422**, nunca 200 — un 200 con el form re-renderizado hace que Turbo lo trate como éxito y no actualice el DOM correctamente.
- Turbo **no re-ejecuta** `<script>` dentro del `<body>` tras una navegación — inicializa librerías de terceros en el evento `turbo:load`, no en un script inline que solo corre en el load inicial.
- `data-turbo-temporary` excluye un elemento del caché de Turbo — sin esto, modales o UI dinámica quedan "pegados" al volver atrás con el botón del navegador.

## Twig Component vs Live Component — criterio de decisión
- **TwigComponent**: renderiza una sola vez en el servidor, sin re-render tras interacción del usuario. Úsalo para presentación estática (botones, cards, alerts, badges).
- **LiveComponent**: re-renderiza vía AJAX cuando el usuario interactúa. Úsalo solo cuando el componente necesita reaccionar a cambios de datos o acciones — el costo de un roundtrip AJAX no se justifica para algo puramente visual.
- Props de TwigComponent son atributos públicos PHP (componentes de clase) o se declaran con `{% props %}` (componentes anónimos); el prefijo `:` en el atributo (`:items="items"`) pasa una expresión Twig en vez de un string literal.
- Bloques (`<twig:block name="header">`) inyectan contenido desde la plantilla padre; el bloque `content` por defecto captura todo lo que va entre las etiquetas del componente.
- Métodos `get*()` en la clase PHP se acceden como propiedades computadas (`this.xxx`) en el template — se recalculan en cada acceso, sin caché entre renders.

## Live Components
- `#[LiveProp]` es estado persistente entre re-renders AJAX; solo `#[LiveProp(writable: true)]` puede modificarse desde el cliente vía `data-model` — un prop de solo lectura que el cliente intenta mutar se ignora en silencio.
- `#[LiveProp(writable: true, url: true)]` sincroniza el prop con query params (bookmarkable) — úsalo para filtros/búsquedas que el usuario espera compartir por URL.
- Entidades Doctrine en un `LiveProp` se rehidratan automáticamente por ID entre requests; para tipos que no son entidades usa `hydrateWith`/`dehydrateWith` explícitos.
- Modificadores de `data-model` según el caso: `debounce(300)|prop` para inputs de texto, `on(blur)|prop` cuando no quieres re-render en cada tecla, `minlength(3)|prop` para evitar queries vacías, `norender|prop` cuando solo necesitas actualizar estado sin ida y vuelta al servidor.
- Formularios embebidos van con `ComponentWithFormTrait` (`instantiateForm()` + `submitForm()`/`getForm()`) — la plantilla raíz del componente debe renderizar `{{ attributes }}` o el controller Stimulus que Live Components necesita para funcionar no se inyecta.
- No uses LiveComponent para interactividad puramente client-side (toggle de un menú, animación) — ahí Stimulus solo es más simple y no paga el costo de un roundtrip AJAX.
- `DefaultActionTrait` es obligatorio en todo componente Live, no opcional — sin él, las acciones (`#[LiveAction]`) no se resuelven.
- `data-live-ignore` en un elemento evita que Live Components lo destruya en cada re-render — indispensable para widgets de terceros (date pickers, editores WYSIWYG) inicializados por JS externo. `data-live-id` en items de una lista mejora el morphing (evita que se recree el DOM completo cuando solo cambió un item).
- `emit()` hace broadcast del evento a cualquier listener; `emitUp()` lo entrega solo al componente padre — confundirlos causa que un listener no reciba el evento o que se disparen handlers de más.
- `url: true` por sí solo no actualiza el botón atrás/adelante del navegador — para eso necesita además `#[LiveProp(writable: true, url: new UrlMapping(history: 'push'))]`.

## Formularios
- Usa `form_start()/form_end()` y los helpers de tema de formulario de Symfony — no reconstruyas manualmente el HTML de un `FormType` ya generado por el framework.
- Todo formulario que muta estado lleva protección CSRF activa (por defecto en el componente Form; no la desactives salvo justificación explícita revisada por `adversarial`).

## CSS
- Sigue la convención ya presente en el proyecto (BEM, utility-first, o CSS Modules vía Encore) — no mezcles convenciones dentro del mismo componente.
