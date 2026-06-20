# SemSearch — Especificación del Proyecto

**Semantic Knowledge Retrieval for Neovim**  
Versión 1.0 · Scope MVP

---

## 0. Propósito y Problema

SemSearch resuelve un fallo cognitivo específico: **sabes que algo existe, pero no recuerdas su nombre**.

Sabes que C++ tiene varios mecanismos de casting, pero no si necesitas `static_cast`, `dynamic_cast`, `reinterpret_cast`, o algo de `<type_traits>`. Sabes que Python tiene una forma de encadenar iteradores perezosamente, pero no si está en `itertools` o `functools` ni cómo se llama. Sabes que Go tiene algo para esperar goroutines concurrentes, pero no recuerdas si es `sync.WaitGroup`, un canal, o `errgroup`.

El LSP estándar (autocomplete, hover, go-to-definition) resuelve un problema distinto: te ayuda cuando ya conoces el nombre del símbolo. La búsqueda web puede resolver consultas conceptuales, pero al coste de salir del editor y romper el flujo.

**SemSearch no es un buscador. Es un índice semántico personal que mapea intención conceptual difusa → sintaxis concreta por lenguaje**, enriquecido con tus propias anotaciones y ejemplos, con LSP como backend de documentación oficial.

```
f : S_semántico  →  S_sintáctico(lenguaje)

S_semántico  =  conceptos, categorías, descripciones de comportamiento
S_sintáctico =  funciones, tipos, patrones, idioms en un lenguaje específico
```

---

## 1. Goals y Non-Goals

### Goals

- **Recuperación conceptual:** encontrar un símbolo o patrón describiendo lo que hace, sin conocer su nombre.
- **Enriquecimiento LSP:** una vez identificado el símbolo, obtener su documentación completa del servidor LSP activo.
- **Anotaciones personales:** adjuntar notas `when/not_when` y ejemplos propios a cualquier entrada.
- **Activación sin fricción:** consultar desde dentro de Neovim sin salir del buffer.
- **Resultados deterministas:** la misma consulta siempre devuelve los mismos resultados rankeados.

### Non-Goals (MVP)

- Índice compartido o colaborativo entre usuarios.
- Generación automática de documentación o entradas por IA.
- Composición de patrones tipo pipeline (aplazado a v2).
- Embeddings o búsqueda semántica neural — excluidos explícitamente del MVP para preservar determinismo.
- Integración con servicios externos más allá del servidor LSP local.

---

## 2. Scope del MVP

### 2.1 Lenguajes

| Lenguaje | Servidor LSP     | Prioridad   |
|----------|-----------------|-------------|
| Go       | gopls            | Primario    |
| Python   | pyright / pylsp  | Primario    |
| C++      | clangd           | Secundario  |

Los lenguajes son aditivos: añadir uno nuevo es crear nuevos archivos YAML. No requiere cambios arquitecturales.

### 2.2 Nivel de integración

El MVP implementa integración completa:

- **Búsqueda + preview:** picker de Telescope con preview en vivo de anotaciones y ejemplos.
- **LSP hover al seleccionar:** seleccionar una entrada dispara una request LSP hover para el símbolo resuelto.
- **Inserción de snippet:** el usuario puede insertar la sintaxis de la entrada directamente en el buffer.

### 2.3 Autoría de entradas

Las entradas se crean editando archivos YAML directamente fuera de Neovim. El comando `:SemNew` genera un template vacío para el lenguaje del buffer activo, pero el flujo principal es edición manual.

---

## 3. Modelo de Datos

### 3.1 Estructura del índice

El índice semántico es una colección plana de registros Entry almacenados en archivos YAML, organizados por lenguaje. Se elige estructura plana sobre grafo deliberadamente: minimiza el coste de mantenimiento y evita abstracción prematura. El sistema de tags provee la estructura asociativa.

### 3.2 Schema de Entry

```yaml
id:          string        # requerido – único, snake_case, e.g. go_goroutine_wait
language:    string        # requerido – 'go' | 'python' | 'cpp'
symbol:      string        # requerido – nombre exacto tal como lo conoce el LSP
import:      string        # opcional  – módulo/paquete a importar para resolver el símbolo
                           #             e.g. 'sync' (Go), 'itertools' (Python), '<vector>' (C++)
                           #             el LSP bridge lo usa para construir el buffer temporal sin ambigüedad
category:    string        # requerido – agrupación top-level (ver §3.3)
tags:                      # requerido – tags tipados por dimensión (ver §3.4)
  op:         [string]     #   qué operación hace: map, filter, fold, cast, esperar, sincronizar…
  domain:     [string]     #   sobre qué opera: listas, iteradores, tipos, goroutines…
  properties: [string]     #   características: lazy, eager, blocking, compiletime, runtime, seguro…
  intent:     [string]     #   para qué se usa: transformar, reducir, convertir, coordinar…

when:        string        # requerido – una frase: cuándo usar esto
not_when:    string        # opcional  – una frase: cuándo NO usar esto

syntax:      string        # requerido – patrón de uso canónico
alt:         [string]      # opcional  – formas sintácticas alternativas

my_example:  |             # opcional  – tu propio ejemplo mínimo funcional
  ...

related:     [string]      # opcional  – lista de otros entry IDs relacionados
notes:       string        # opcional  – notas personales libres
```

### 3.3 Categorías

Fijas en el MVP. Nuevas categorías pueden añadirse en YAML pero deben registrarse en la configuración del plugin para aparecer en búsquedas por categoría.

| Categoría      | Cubre                                                         |
|----------------|---------------------------------------------------------------|
| `tipos`        | Casting, conversiones, type traits, coerciones                |
| `listas`       | Arrays, slices, vectores, listas, iteración básica            |
| `iteradores`   | Secuencias lazy, generators, ranges, cursores                 |
| `memoria`      | Ownership, punteros, smart pointers, allocación               |
| `concurrencia` | Goroutines, threads, async, futures, canales, locks           |
| `io`           | Archivos, stdin/stdout, serialización, streams                |
| `errores`      | Error handling, excepciones, result types, panic/recover      |
| `strings`      | Tipos string, manipulación, encoding, formatting              |
| `funciones`    | Higher-order functions, closures, lambdas, dispatch           |
| `patrones`     | Design patterns, idioms, templates estructurales              |

### 3.4 Sistema de Tags Tipados

Los tags se organizan en cuatro dimensiones fijas. Esto evita el drift semántico que ocurre con listas planas cuando el índice crece: sin estructura, `esperar`, `wait` y `blocking` terminan siendo sinónimos inconsistentes distribuidos entre entradas.

**`op` — qué operación realiza el símbolo**

| Valor | Significado |
|---|---|
| `map` | transformar elemento a elemento |
| `filter` | seleccionar elementos por predicado |
| `fold` / `reduce` | acumular en un valor |
| `cast` | convertir tipo |
| `esperar` | bloquear hasta condición |
| `sincronizar` | coordinar acceso concurrente |
| `cancelar` | interrumpir operación en curso |
| `iterar` | recorrer secuencia |
| `agrupar` | particionar por clave |
| `componer` | combinar funciones o valores |

**`domain` — sobre qué tipo de dato o abstracción opera**

| Valor | Ejemplos |
|---|---|
| `listas` | slice, vector, list |
| `iteradores` | generator, range, cursor |
| `tipos` | type traits, conversiones |
| `goroutines` | Go concurrency primitives |
| `threads` | OS threads, Python threading |
| `canales` | Go channels |
| `errores` | error types, exceptions |
| `strings` | str, string, []byte |
| `funciones` | closures, lambdas |
| `contexto` | context.Context, cancellation |

**`properties` — características de comportamiento**

| Valor | Significado |
|---|---|
| `lazy` | evaluación diferida |
| `eager` | evaluación inmediata |
| `blocking` | bloquea el hilo/goroutine |
| `nonblocking` | no bloquea |
| `compiletime` | resuelto en compilación |
| `runtime` | resuelto en ejecución |
| `seguro` | memory/type safe por diseño |
| `unsafe` | requiere cuidado explícito |
| `inmutable` | no modifica el input |
| `inplace` | modifica el input |

**`intent` — para qué problema se usa**

| Valor | Cuándo aplicar |
|---|---|
| `transformar` | cambiar forma manteniendo cardinalidad |
| `reducir` | colapsar colección a escalar |
| `convertir` | cambiar representación de tipo |
| `coordinar` | sincronizar múltiples actores |
| `propagar` | pasar errores o contexto hacia arriba |
| `memoizar` | cachear resultado de función |
| `decorar` | envolver comportamiento existente |
| `particionar` | dividir en subgrupos |

**Reglas de uso:**
- Toda entrada debe tener al menos un tag en `op` y uno en `domain`.
- `properties` e `intent` son opcionales pero recomendados.
- Máximo 3 valores por dimensión. Si necesitas más, el borde de la entrada está mal definido.
- Los valores son language-neutral: `blocking` significa lo mismo en Go, Python y C++.

### 3.5 Ejemplo concreto de Entry

```yaml
- id: cpp_static_cast
  language: cpp
  symbol: static_cast
  category: tipos
  tags:
    op:         [cast]
    domain:     [tipos]
    properties: [compiletime, seguro]
    intent:     [convertir]

  when: >
    Conversión entre tipos relacionados verificable en tiempo de compilación.
    Subir o bajar en jerarquía de clases cuando el tipo destino es conocido.
  not_when: >
    No uses cuando necesites verificación en runtime (usa dynamic_cast).
    No uses para reinterpretar bits sin relación semántica (usa reinterpret_cast).

  syntax: "static_cast<TargetType>(expression)"
  alt:
    - "(TargetType) expression  // C-style cast, evitar en C++ moderno"

  my_example: |
    double x = 3.14;
    int n = static_cast<int>(x);  // 3, trunca hacia cero

    // En jerarquía de clases:
    Base* b = new Derived();
    Derived* d = static_cast<Derived*>(b);  // seguro si sabemos el tipo real

  related: [cpp_dynamic_cast, cpp_reinterpret_cast, cpp_bit_cast]
  notes: >
    static_cast es la opción default para cualquier conversión no-bit.
    Si static_cast no compila, es señal de que el cast es semánticamente incorrecto.
```

```yaml
- id: go_goroutine_wait
  language: go
  symbol: sync.WaitGroup
  import: sync                  # resuelve ambigüedad: gopls sabe exactamente qué WaitGroup
  category: concurrencia
  tags:
    op:         [esperar, sincronizar]
    domain:     [goroutines]
    properties: [blocking]
    intent:     [coordinar]

  when: >
    Esperar a que un número conocido de goroutines termine antes de continuar.
  not_when: >
    No uses si no sabes de antemano cuántas goroutines hay (usa canales).
    No uses si necesitas propagar errores de las goroutines (usa errgroup).

  syntax: |
    var wg sync.WaitGroup
    wg.Add(n)
    go func() { defer wg.Done(); /* trabajo */ }()
    wg.Wait()

  my_example: |
    var wg sync.WaitGroup
    for _, url := range urls {
        wg.Add(1)
        go func(u string) {
            defer wg.Done()
            fetch(u)
        }(url)
    }
    wg.Wait()  // bloquea hasta que todos terminen

  related: [go_errgroup, go_channel_done, go_context_cancel]
```

---

## 4. Layout de Archivos

```
~/.config/nvim/
│
├── lua/
│   └── semsearch/
│       ├── init.lua          # API pública + setup()
│       ├── loader.lua        # parser YAML, constructor del índice
│       ├── search.lua        # motor de query, scoring
│       ├── lsp_bridge.lua    # integración LSP hover
│       ├── telescope.lua     # picker Telescope + preview
│       └── config.lua        # configuración por defecto
│
└── semsearch/                # índice semántico (mantenido por el usuario)
    ├── go/
    │   ├── concurrencia.yaml
    │   ├── errores.yaml
    │   ├── listas.yaml
    │   └── ...
    ├── python/
    │   ├── iteradores.yaml
    │   ├── funciones.yaml
    │   └── ...
    └── cpp/
        ├── tipos.yaml
        ├── memoria.yaml
        └── ...
```

La ruta del directorio de índice es configurable. El loader lee recursivamente todos los `*.yaml` bajo el root.

---

## 5. Motor de Búsqueda

### 5.1 Principios de diseño

- **Determinista:** queries idénticas producen resultados idénticos.
- **Sin embeddings en MVP:** fuzzy string matching sobre campos estructurados únicamente.
- **En memoria:** el índice completo vive en una tabla Lua después del startup. Sin I/O en disco en tiempo de query.
- **Transparente:** el usuario puede entender por qué un resultado rankeó donde rankeó.

### 5.2 Procesamiento de query

```
Input: "esperar goroutines terminen"

Paso 1 — Tokenizar
  tokens = ["esperar", "goroutines", "terminen"]
  stop_words eliminadas: ninguna en este caso
  effective_tokens = ["esperar", "goroutines", "terminen"]

Paso 2 — Filtro de lenguaje implícito
  ningún token reconocido como lenguaje → búsqueda global

Paso 3 — Puntuar cada entrada
  (ver §5.3)

Paso 4 — Devolver top-N ordenados por score desc
```

Tokens de lenguaje reconocidos: `go`, `golang`, `python`, `py`, `cpp`, `c++`.  
Si se detecta uno, se aplica como filtro hard antes del scoring y se elimina de los tokens de búsqueda.

### 5.3 Función de scoring

Score = suma ponderada de matches por campo. Los matches se calculan como fuzzy substring (compatible con `vim.fn.matchfuzzy`).

| Campo               | Peso | Notas                                                        |
|---------------------|------|--------------------------------------------------------------|
| `tags.op`           | 25   | Match en operación — la dimensión más selectiva              |
| `tags.domain`       | 20   | Match en dominio de datos                                    |
| `tags.properties`   | 15   | Match en propiedades de comportamiento                       |
| `tags.intent`       | 10   | Match en intención de uso                                    |
| `symbol`            | 20   | Match exacto o prefijo puntúa más alto                       |
| `category`          | 10   | Match de dominio amplio — fallback de alta granularidad      |
| `when` / `not_when` |  5   | Fallback textual para queries muy descriptivos               |

El peso total de tags (70) supera al del símbolo porque los tags son el vocabulario semántico curado. El símbolo solo matchea cuando el usuario ya tiene cierta idea del nombre.

Score final = Σ(field_score × weight) sobre todos los effective_tokens.  
Empates resueltos por orden alfabético de `id`.

### 5.4 Filtro de lenguaje implícito

Si la query contiene un token de lenguaje reconocido, se extrae y aplica como filtro hard. Sin token de lenguaje, la búsqueda es global sobre todas las entradas cargadas.

---

## 6. LSP Bridge

### 6.1 Responsabilidad

El LSP bridge resuelve el campo `symbol` de una entrada a una respuesta hover completa del servidor LSP activo. Provee documentación oficial, actualizada, sin que el usuario la mantenga manualmente.

### 6.2 Mecanismo

El hover LSP estándar (`textDocument/hover`) requiere una posición en un documento. El bridge resuelve esto así:

**Primario:** crear un buffer temporal invisible, escribir el import declarado en el campo `import` de la entrada seguido de un uso mínimo del símbolo, posicionar el cursor sobre él, llamar `vim.lsp.buf_request` con `textDocument/hover`, capturar la respuesta, cerrar el buffer. El campo `import` es crítico para resolver ambigüedad: sin él, `map` en Go puede resolverse al tipo builtin, al paquete `sync.Map`, o a otro símbolo en scope.

**Fallback:** si el primario falla (LSP no adjunto, símbolo ambiguo, servidor no disponible), mostrar solo las anotaciones propias de la entrada sin enriquecimiento LSP. Esto no es un estado de error — la entrada sigue siendo útil.

### 6.3 Layout del panel de detalle

```
┌──────────────────────────────────────────────────────┐
│  [SemSearch]  go_goroutine_wait                      │
│  sync.WaitGroup  ·  concurrencia  ·  go              │
├──────────────────────────────────────────────────────┤
│  WHEN      Esperar a que un número conocido de...    │
│  NOT WHEN  No uses si no sabes cuántas goroutines... │
├──────────────────────────────────────────────────────┤
│  SYNTAX                                              │
│  var wg sync.WaitGroup                               │
│  wg.Add(n)                                           │
│  go func() { defer wg.Done(); ... }()                │
│  wg.Wait()                                           │
├──────────────────────────────────────────────────────┤
│  MY EXAMPLE                                          │
│  for _, url := range urls { ... }                    │
│  wg.Wait()                                           │
├──────────────────────────────────────────────────────┤
│  LSP DOCUMENTATION                                   │
│  (respuesta hover de gopls renderizada aquí)         │
└──────────────────────────────────────────────────────┘
```

---

## 7. Interfaz en Neovim

### 7.1 Comandos

| Comando           | Comportamiento                                                                 |
|-------------------|--------------------------------------------------------------------------------|
| `:SemSearch [q]`  | Abre Telescope. Si se provee query, pre-rellena el prompt.                    |
| `:SemNew`         | Scaffoldea un template de entrada para el lenguaje del buffer activo.          |
| `:SemReload`      | Recarga el índice completo desde disco sin reiniciar Neovim.                   |
| `:SemEdit [id]`   | Abre el archivo YAML que contiene la entrada con ese id, posicionado en ella.  |

### 7.2 Keymaps (defaults)

```
<leader>fs   →   :SemSearch          (búsqueda global)
<leader>fn   →   :SemNew
<leader>fe   →   :SemSearch          (con la palabra bajo el cursor como query inicial)
```

Todos los keymaps son configurables. Pueden desactivarse con `keymap_prefix = false`.

### 7.3 Comportamiento del picker Telescope

- Resultados mostrados como: `symbol · category · language`
- Panel de preview: `when`, `not_when`, `syntax`, `my_example`
- `<CR>`: seleccionar entrada → disparar LSP hover → abrir split de detalle completo
- `<C-y>`: insertar el campo `syntax` en la posición del cursor en el buffer previo
- `<C-e>`: abrir el YAML fuente de la entrada para edición

---

## 8. Configuración

```lua
require('semsearch').setup({
  -- Ruta al directorio del índice YAML
  index_dir = vim.fn.stdpath('config') .. '/semsearch',

  -- Máximo de resultados en Telescope
  max_results = 20,

  -- Lenguajes a cargar (nil = cargar todos los encontrados)
  languages = nil,

  -- Intentar LSP hover al seleccionar
  lsp_hover = true,

  -- Prefijo de keymaps (false = desactivar keymaps por defecto)
  keymap_prefix = '<leader>f',

  -- Stop words eliminadas de queries antes del scoring
  stop_words = {
    'en', 'el', 'la', 'a', 'de', 'para', 'que', 'con', 'los', 'las',
    'in', 'the', 'a', 'an', 'of', 'for', 'to', 'with',
  },
})
```

---

## 9. Arquitectura de Módulos

### 9.1 Mapa de módulos

```
setup() llamado por el usuario
  │
  ▼
config.lua          ← merge configuración del usuario con defaults
  │
  ▼
loader.lua          ← parsear todos los YAML → construir tabla Lua en memoria
  │                    index = { [id] = Entry, ... }
  │
  ├──► search.lua   ← query(tokens, lang?) → lista rankeada de Entry
  │
  └──► telescope.lua ← construir picker desde resultados de search
           │
           └──► lsp_bridge.lua  ← al seleccionar: resolver symbol → hover LSP
```

### 9.2 Flujo de datos

- **Startup:** loader lee todos los YAML → tabla Lua plana en memoria. Reload con `:SemReload`.
- **Query:** usuario escribe en el prompt de Telescope → search.lua puntúa entradas → Telescope muestra top resultados con preview.
- **Selección:** usuario presiona Enter → lsp_bridge pide hover para el símbolo resuelto → ventana de detalle completa.
- **Inserción:** usuario presiona Ctrl-Y → campo `syntax` insertado en la posición del cursor anterior.

### 9.3 Dependencias externas

| Dependencia      | Requerida | Propósito                                          |
|------------------|-----------|----------------------------------------------------|
| telescope.nvim   | Sí        | UI layer para resultados y preview                 |
| nvim-lspconfig   | Sí        | Adjuntar servidores LSP (config existente del user)|
| lyaml / tinyyaml | Sí        | Parser YAML en Lua para cargar el índice           |
| plenary.nvim     | Sí        | Dependencia de Telescope; async file I/O           |

---

## 10. Índice de Inicio

El plugin incluye ~30 entradas de arranque cubriendo los gaps conceptuales más frecuentes en Go, Python y C++. Criterio de inclusión: conceptos frecuentemente necesitados con nombres no obvios o múltiples variantes.

### Go (concurrencia)
- `sync.WaitGroup` — esperar N goroutines
- `golang.org/x/sync/errgroup` — esperar N goroutines con propagación de errores
- `context.WithCancel` — cancelación cooperativa de goroutines
- `context.WithTimeout` — timeout en operaciones bloqueantes
- `select` — multiplexar sobre múltiples canales

### Go (errores)
- `fmt.Errorf` con `%w` — wrapping de errores
- `errors.Is` / `errors.As` — unwrapping e inspección de errores
- `defer` + `recover` — capturar panics

### Python (iteradores)
- `itertools.chain` — concatenar iterables lazily
- `itertools.islice` — slice de iterador
- `itertools.groupby` — agrupar elementos consecutivos por clave
- `functools.reduce` — fold/acumular sobre secuencia
- `functools.partial` — aplicación parcial de función

### Python (funciones)
- `functools.lru_cache` — memoización con cache LRU
- `functools.wraps` — preservar metadata en decoradores

### C++ (tipos)
- `static_cast` — conversión segura en compiletime
- `dynamic_cast` — downcast con verificación en runtime
- `reinterpret_cast` — reinterpretación de bits
- `std::bit_cast` — reinterpretación segura (C++20)
- `std::is_same_v` — igualdad de tipos en compiletime
- `std::decay_t` — strip de referencias, qualifiers, decay

### C++ (memoria)
- `std::unique_ptr` — ownership exclusivo
- `std::shared_ptr` — ownership compartido, reference counted
- `std::weak_ptr` — observer no-owning de shared_ptr
- `std::move` — transferir ownership
- `std::forward` — perfect forwarding en templates

---

## 11. Política de Crecimiento del Índice

El índice vale exactamente lo que vale su disciplina de curación.

- **Regla de tres:** solo añadir una entrada si has buscado el concepto al menos tres veces sin recordar el nombre exacto.
- **Ejemplo mínimo obligatorio:** toda entrada debe tener `my_example` antes de considerarse completa.
- **when/not_when requerido:** el campo más valioso. Si no puedes escribir un `not_when` claro, el borde de la entrada probablemente está mal definido.
- **Revisión trimestral:** entradas no accedidas en 90 días deben podarse o fusionarse.
- **Sin tagging prematuro:** empieza con 3–4 tags por entrada. Añade tags solo cuando una búsqueda falle en encontrar una entrada que esperabas encontrar.

---

## 12. Extensiones Futuras (Post-MVP)

**Composición de patrones:** queries como `map + filter + reduce` que devuelvan sugerencias de pipelines idiomáticos por lenguaje. Requiere modelar entradas como unidades componibles.

**Fallback de embeddings:** si la búsqueda fuzzy devuelve resultados por debajo de un umbral de score, invocar opcionalmente un modelo local (ollama) para búsqueda por vecinos semánticos. Aditivo, no cambia el camino principal.

**Telemetría local:** logging local de qué entradas se acceden y qué queries no devolvieron resultados. Para guiar las revisiones trimestrales.

**Patrones estructurales:** extender entradas más allá de símbolos para cubrir templates estructurales: patrón RAII, Builder, protocolo Iterator, context manager. Mismo schema, categoría `patrones`.

**Rust:** lenguaje natural siguiente. Solo requiere nuevos YAML y referencia a `rust-analyzer`.

---

## Apéndice A — Glosario

| Término      | Definición                                                                   |
|--------------|------------------------------------------------------------------------------|
| Entry        | Un registro en el índice semántico. Corresponde a un símbolo o patrón.      |
| Índice       | La colección completa en memoria de todas las entradas cargadas.             |
| Symbol       | El identificador exacto tal como lo conoce el servidor LSP.                  |
| Category     | Dominio semántico top-level (tipos, listas, concurrencia, …).               |
| Tag          | Descriptor semántico aplicado a una entrada para la búsqueda.               |
| LSP hover    | La respuesta de documentación de un servidor LSP para un símbolo dado.      |
| when         | Guía de decisión: cuándo usar esto.                                          |
| not_when     | Guía de decisión: cuándo NO usar esto. El campo más valioso.                |

---

## Apéndice B — Lo que esto no es

- No es un reemplazo del autocomplete LSP. Ambos coexisten y sirven momentos cognitivos distintos.
- No es un generador de documentación. Todas las anotaciones las escribe el usuario.
- No es un knowledge graph ni una ontología. La estructura plana + tags es una simplificación deliberada.
- No es asistido por IA. Ningún modelo se invoca durante la búsqueda o recuperación en el MVP.
- No es una herramienta de equipo. El índice refleja el modelo mental de un solo desarrollador.
