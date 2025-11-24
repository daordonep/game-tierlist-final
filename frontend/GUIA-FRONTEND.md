# Guía del Frontend - Game Tierlist

Esta guía te ayudará a entender y modificar el frontend sin necesidad de conocimientos profundos de desarrollo web.

## 📁 Estructura del Proyecto

```
frontend/
└── index.html    # Todo el frontend está en un único archivo
```

El frontend es un **Single Page Application (SPA)** simple que usa:
- **HTML5** para la estructura
- **Tailwind CSS** (via CDN) para los estilos
- **JavaScript vanilla** para la lógica

## 🔧 Configuración Inicial

### Cambiar la URL del Backend

La única configuración que **DEBES** cambiar está al principio del archivo:

```javascript
const API_BASE_URL = 'http://localhost:8080/api';
```

Cambia esta URL según donde esté tu backend:
- Desarrollo local: `http://localhost:8080/api`
- Producción: `https://tu-dominio.com/api`

## 🎨 Personalización de Estilos

### Cambiar Colores de los Tiers

Los colores de las tiers están definidos en la configuración de Tailwind al principio del archivo:

```javascript
tailwind.config = {
    theme: {
        extend: {
            colors: {
                tier: {
                    s: '#ff7f7f',  // Rojo claro - Tier S
                    a: '#ffbf7f',  // Naranja - Tier A
                    b: '#ffdf7f',  // Amarillo - Tier B
                    c: '#ffff7f',  // Amarillo claro - Tier C
                    d: '#bfff7f',  // Verde claro - Tier D
                }
            }
        }
    }
}
```

Simplemente cambia los códigos hexadecimales por los colores que prefieras.

### Cambiar Colores del Header

Busca esta línea para cambiar el gradiente del header:

```html
<header class="bg-gradient-to-r from-purple-600 to-indigo-600 text-white shadow-lg">
```

Puedes cambiar `purple-600` y `indigo-600` por otros colores de Tailwind:
- `blue-600`, `green-600`, `red-600`, `yellow-600`, etc.
- Consulta la paleta completa en: https://tailwindcss.com/docs/customizing-colors

### Cambiar el Título/Nombre de la App

Busca y modifica:

```html
<title>Game Tierlist - Registro de Juegos</title>
```

Y también:

```html
<h1 class="text-2xl font-bold">🎮 Game Tierlist</h1>
```

## 📝 Modificar Campos y Formularios

### Añadir una Nueva Plataforma

Busca todos los `<select>` que contienen las plataformas y añade una nueva opción:

```html
<select name="plataforma" ...>
    <option value="PC">PC</option>
    <option value="PlayStation">PlayStation</option>
    <option value="Xbox">Xbox</option>
    <option value="Nintendo Switch">Nintendo Switch</option>
    <option value="Móvil">Móvil</option>
    <!-- Añade aquí -->
    <option value="Steam Deck">Steam Deck</option>
</select>
```

**Nota:** Hay varios selects de plataforma en el archivo. Usa Ctrl+F para buscar `value="PC"` y modifica todos.

### Cambiar el Rango de Rating

Por defecto es 1-10. Para cambiarlo, busca y modifica estos atributos:

```html
<input type="number" name="rating" required min="1" max="10" ...>
```

Cambia `min` y `max` por los valores que quieras.

**Importante:** También deberás modificar la función `getTierFromRating()` en JavaScript:

```javascript
function getTierFromRating(rating) {
    if (rating === 10) return 's';    // Ajusta estos valores
    if (rating >= 8) return 'a';       // según tu nuevo rango
    if (rating >= 6) return 'b';
    if (rating >= 4) return 'c';
    return 'd';
}
```

### Añadir un Nuevo Campo a los Juegos

Si añades un campo en el backend (por ejemplo, `genero`), sigue estos pasos:

1. **Añade el campo al formulario de añadir juego** (busca `id="addGameForm"`):

```html
<div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Género</label>
    <input type="text" name="genero" class="w-full border rounded px-3 py-2">
</div>
```

2. **Añade el campo al objeto de datos** en la función `submitAddGame`:

```javascript
const data = {
    nombre: form.nombre.value,
    plataforma: form.plataforma.value,
    categoriaId: parseInt(form.categoriaId.value),
    anioLanzamiento: parseInt(form.anioLanzamiento.value),
    descripcion: form.descripcion.value || null,
    genero: form.genero.value  // ← Añade esta línea
};
```

3. **Muestra el campo en la tarjeta del juego** en la función `renderGames`:

```javascript
<span class="text-xs bg-green-100 text-green-700 px-2 py-1 rounded">${game.genero}</span>
```

## 🔄 Modificar la Lógica de Tiers

### Cambiar los Rangos de los Tiers

La lógica que determina en qué tier va cada juego está en:

```javascript
function getTierFromRating(rating) {
    if (rating === 10) return 's';
    if (rating >= 8) return 'a';
    if (rating >= 6) return 'b';
    if (rating >= 4) return 'c';
    return 'd';
}
```

### Añadir Más Tiers (por ejemplo, F)

1. **Añade el color en la configuración de Tailwind:**

```javascript
tier: {
    s: '#ff7f7f',
    a: '#ffbf7f',
    b: '#ffdf7f',
    c: '#ffff7f',
    d: '#bfff7f',
    f: '#ff4444',  // ← Nuevo tier F
}
```

2. **Añade el HTML del tier** (busca `<!-- Tier D -->` y añade después):

```html
<!-- Tier F -->
<div class="bg-tier-f rounded-lg p-4">
    <div class="flex items-center gap-2 mb-3">
        <span class="text-2xl font-bold">F</span>
        <span class="text-sm text-gray-700">(Rating 1)</span>
    </div>
    <div id="tier-f-games" class="flex flex-wrap gap-2"></div>
</div>
```

3. **Modifica la función de renderizado** `renderMyTierlist`:

```javascript
// Añade 'f' al array de tiers a limpiar
['s', 'a', 'b', 'c', 'd', 'f'].forEach(t => {
```

4. **Modifica la función `getTierFromRating`:**

```javascript
function getTierFromRating(rating) {
    if (rating === 10) return 's';
    if (rating >= 8) return 'a';
    if (rating >= 6) return 'b';
    if (rating >= 4) return 'c';
    if (rating >= 2) return 'd';
    return 'f';  // ← Rating 1
}
```

## 🌐 Endpoints de la API

El frontend espera estos endpoints del backend:

### Usuarios
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/users` | Lista todos los usuarios |
| POST | `/api/users` | Crea un usuario |
| DELETE | `/api/users/{id}` | Elimina un usuario |

### Categorías
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/categories` | Lista todas las categorías |

### Juegos (Catálogo)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/games` | Lista todos los juegos |
| POST | `/api/games` | Crea un juego |
| DELETE | `/api/games/{id}` | Elimina un juego |

### Tierlists
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/users/{userId}/tierlists` | Lista tierlists de un usuario |
| POST | `/api/users/{userId}/tierlists` | Crea una tierlist |
| GET | `/api/users/{userId}/tierlists/{anio}` | Obtiene tierlist con entries |
| POST | `/api/users/{userId}/tierlists/{anio}/entries` | Añade juego a tierlist |
| PUT | `/api/users/{userId}/tierlists/{anio}/entries/{id}` | Actualiza entry |
| DELETE | `/api/users/{userId}/tierlists/{anio}/entries/{id}` | Elimina entry |

### Explorar y Comparar
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/tierlists/entries?filtros` | Busca entries con filtros |
| GET | `/api/tierlists/compare?userIds=1,2&anio=2024` | Compara tierlists |

## 🐛 Solución de Problemas Comunes

### No se cargan los datos

1. **Verifica que el backend está corriendo** en la URL configurada
2. **Abre la consola del navegador** (F12 → Console) para ver errores
3. **Revisa la pestaña Network** (F12 → Network) para ver las peticiones

### Error de CORS

Si ves errores de CORS en la consola, asegúrate de que tu backend tiene configurado CORS correctamente. En Spring Boot:

```java
@Configuration
public class CorsConfig {
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins("*")
                    .allowedMethods("GET", "POST", "PUT", "DELETE");
            }
        };
    }
}
```

### Los estilos no se ven bien

- Asegúrate de tener conexión a internet (Tailwind se carga desde CDN)
- Si necesitas funcionar offline, descarga Tailwind y referéncialo localmente

## 💡 Consejos

1. **Usa las DevTools del navegador** (F12) para depurar
2. **Haz cambios pequeños** y prueba frecuentemente
3. **Guarda copias de seguridad** antes de hacer cambios grandes
4. **Tailwind tiene excelente documentación**: https://tailwindcss.com/docs

## 📚 Recursos Útiles

- [Documentación de Tailwind CSS](https://tailwindcss.com/docs)
- [MDN Web Docs - JavaScript](https://developer.mozilla.org/es/docs/Web/JavaScript)
- [MDN Web Docs - Fetch API](https://developer.mozilla.org/es/docs/Web/API/Fetch_API)

---

¡Diviértete con tu proyecto! 🎮
