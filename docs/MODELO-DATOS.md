# 📊 Modelo de Datos - Game Tierlist

## Diagrama Entidad-Relación

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│    CATEGORY     │       │      GAME       │       │      USER       │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │       │ id (PK)         │
│ nombre          │◄──────│ category_id(FK) │       │ nombre          │
│ descripcion     │   1:N │ nombre          │       │ email           │
│ created_at      │       │ plataforma      │       │ created_at      │
│ updated_at      │       │ descripcion     │       │ updated_at      │
└─────────────────┘       │ anio_lanzamiento│       └────────┬────────┘
                          │ created_at      │                │
                          │ updated_at      │                │ 1:N
                          └────────┬────────┘                │
                                   │                         │
                                   │ 1:N                     │
                                   │                         ▼
                                   │              ┌─────────────────┐
                                   │              │    TIERLIST     │
                                   │              ├─────────────────┤
                                   │              │ id (PK)         │
                                   │              │ user_id (FK)    │
                                   │              │ anio            │
                                   │              │ created_at      │
                                   │              │ updated_at      │
                                   │              └────────┬────────┘
                                   │                       │
                                   │                       │ 1:N
                                   │                       │
                                   │                       ▼
                                   │           ┌──────────────────────┐
                                   │           │   TIERLIST_ENTRY     │
                                   │           ├──────────────────────┤
                                   │           │ id (PK)              │
                                   └──────────►│ tierlist_id (FK)     │
                                       1:N     │ game_id (FK)         │
                                               │ rating               │
                                               │ anio_jugado          │
                                               │ ─────────────────────│
                                               │ game_nombre      (D) │
                                               │ game_plataforma  (D) │
                                               │ game_categoria   (D) │
                                               │ game_descripcion (D) │
                                               │ game_anio_lanz.  (D) │
                                               │ created_at           │
                                               │ updated_at           │
                                               └──────────────────────┘
                                               
                                               (D) = Campo denormalizado
```

---

## Tablas

### CATEGORY

Catálogo de categorías de juegos (solo lectura).

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | BIGINT | PK, AUTO | Identificador único |
| nombre | VARCHAR(50) | NOT NULL, UNIQUE | Nombre de la categoría |
| descripcion | VARCHAR(200) | | Descripción opcional |
| created_at | TIMESTAMP | NOT NULL | Fecha de creación |
| updated_at | TIMESTAMP | NOT NULL | Fecha de actualización |

**Datos iniciales:** Acción, Aventura, RPG, Shooter, Deportes, Carreras, Puzzle, Plataformas, Estrategia, Simulación, Terror, Indie

---

### USER

Usuarios de la aplicación.

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | BIGINT | PK, AUTO | Identificador único |
| nombre | VARCHAR(100) | NOT NULL, UNIQUE | Nombre de usuario |
| email | VARCHAR(150) | UNIQUE | Email (opcional) |
| created_at | TIMESTAMP | NOT NULL | Fecha de creación |
| updated_at | TIMESTAMP | NOT NULL | Fecha de actualización |

---

### GAME

Catálogo de juegos compartido entre usuarios.

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | BIGINT | PK, AUTO | Identificador único |
| nombre | VARCHAR(100) | NOT NULL | Nombre del juego |
| plataforma | VARCHAR(50) | NOT NULL | Plataforma (PC, PS5, etc.) |
| descripcion | VARCHAR(500) | | Descripción opcional |
| anio_lanzamiento | INT | NOT NULL | Año de lanzamiento |
| category_id | BIGINT | FK, NOT NULL | Referencia a CATEGORY |
| created_at | TIMESTAMP | NOT NULL | Fecha de creación |
| updated_at | TIMESTAMP | NOT NULL | Fecha de actualización |

**Constraints:**
- `UNIQUE(nombre, plataforma)` - El mismo juego puede existir en diferentes plataformas
- `FK(category_id)` → CATEGORY(id)

---

### TIERLIST

Tierlists de cada usuario por año.

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | BIGINT | PK, AUTO | Identificador único |
| user_id | BIGINT | FK, NOT NULL | Referencia a USER |
| anio | INT | NOT NULL | Año de la tierlist |
| created_at | TIMESTAMP | NOT NULL | Fecha de creación |
| updated_at | TIMESTAMP | NOT NULL | Fecha de actualización |

**Constraints:**
- `UNIQUE(user_id, anio)` - Un usuario solo puede tener una tierlist por año
- `FK(user_id)` → USER(id)

---

### TIERLIST_ENTRY

Juegos dentro de una tierlist con su valoración.

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | BIGINT | PK, AUTO | Identificador único |
| tierlist_id | BIGINT | FK, NOT NULL | Referencia a TIERLIST |
| game_id | BIGINT | FK, NOT NULL | Referencia a GAME |
| rating | INT | NOT NULL | Puntuación 1-10 |
| anio_jugado | INT | NOT NULL | Año en que se jugó |
| game_nombre | VARCHAR(100) | NOT NULL | (Denormalizado) |
| game_plataforma | VARCHAR(50) | NOT NULL | (Denormalizado) |
| game_categoria | VARCHAR(50) | NOT NULL | (Denormalizado) |
| game_descripcion | VARCHAR(500) | | (Denormalizado) |
| game_anio_lanzamiento | INT | NOT NULL | (Denormalizado) |
| created_at | TIMESTAMP | NOT NULL | Fecha de creación |
| updated_at | TIMESTAMP | NOT NULL | Fecha de actualización |

**Constraints:**
- `UNIQUE(tierlist_id, game_id)` - Un juego solo puede estar una vez por tierlist
- `FK(tierlist_id)` → TIERLIST(id) ON DELETE CASCADE
- `FK(game_id)` → GAME(id)

---

## Campos Denormalizados

### ¿Por qué denormalizar?

En `TIERLIST_ENTRY` copiamos datos del juego para:

1. **Evitar JOINs en listados** - Podemos mostrar entries sin cargar GAME
2. **Filtros más rápidos** - Podemos buscar por categoría, plataforma, etc. directamente
3. **Rendimiento en agregaciones** - Estadísticas sin JOINs costosos

### Trade-offs

| Ventaja | Desventaja |
|---------|------------|
| Queries más simples | Datos duplicados |
| Mejor rendimiento lectura | Más espacio en disco |
| Filtros directos | Si cambia el juego, no se actualiza |

### ¿Cuándo actualizar los datos denormalizados?

En este proyecto, **no actualizamos** los datos denormalizados si el juego cambia. Esto es intencional:

- La entry representa "cómo era el juego cuando lo añadí"
- Si el juego cambia de categoría, mis entries anteriores mantienen la categoría original

En un sistema real, podrías tener un job que sincronice o un trigger.

---

## Relaciones

### Category → Game (1:N)

```java
// En Game
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "category_id", nullable = false)
private Category category;
```

### User → Tierlist (1:N)

```java
// En Tierlist
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "user_id", nullable = false)
private User user;
```

### Tierlist → TierlistEntry (1:N con cascade)

```java
// En Tierlist
@OneToMany(mappedBy = "tierlist", 
           cascade = CascadeType.ALL, 
           orphanRemoval = true)
@OrderBy("rating DESC")
private List<TierlistEntry> entries = new ArrayList<>();
```

### TierlistEntry → Game (N:1)

```java
// En TierlistEntry
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "game_id", nullable = false)
private Game game;
```

---

## Cálculo de Tier

El tier se calcula dinámicamente basándose en el rating:

| Rating | Tier | Color sugerido |
|--------|------|----------------|
| 10-9 | S | Dorado |
| 8-7 | A | Verde |
| 6-5 | B | Azul |
| 4-3 | C | Naranja |
| 2-1 | D | Rojo |

```java
private String calculateTier(Integer rating) {
    return switch (rating) {
        case 10, 9 -> "S";
        case 8, 7 -> "A";
        case 6, 5 -> "B";
        case 4, 3 -> "C";
        case 2, 1 -> "D";
        default -> "?";
    };
}
```

---

## Índices Recomendados

```sql
-- Para búsquedas de tierlists por usuario
CREATE INDEX idx_tierlist_user ON tierlist(user_id);

-- Para búsquedas de entries por tierlist
CREATE INDEX idx_entry_tierlist ON tierlist_entry(tierlist_id);

-- Para búsquedas de games por categoría
CREATE INDEX idx_game_category ON game(category_id);

-- Para búsquedas en campos denormalizados
CREATE INDEX idx_entry_game_nombre ON tierlist_entry(game_nombre);
CREATE INDEX idx_entry_game_categoria ON tierlist_entry(game_categoria);
```

---

## Queries de Ejemplo

### Listar juegos de una tierlist

```sql
SELECT te.game_nombre, te.game_plataforma, te.rating
FROM tierlist_entry te
WHERE te.tierlist_id = ?
ORDER BY te.rating DESC;
```

### Buscar entries por categoría

```sql
SELECT te.*
FROM tierlist_entry te
WHERE te.game_categoria = 'RPG'
ORDER BY te.rating DESC;
```

### Estadísticas por categoría

```sql
SELECT te.game_categoria, 
       COUNT(*) as total,
       AVG(te.rating) as promedio
FROM tierlist_entry te
GROUP BY te.game_categoria
ORDER BY promedio DESC;
```

### Top juegos más valorados

```sql
SELECT te.game_nombre, 
       te.game_plataforma,
       AVG(te.rating) as promedio,
       COUNT(*) as veces_valorado
FROM tierlist_entry te
GROUP BY te.game_nombre, te.game_plataforma
HAVING COUNT(*) >= 2
ORDER BY promedio DESC
LIMIT 10;
```

### Juegos comunes entre usuarios

```sql
SELECT te.game_nombre, te.game_plataforma
FROM tierlist_entry te
JOIN tierlist t ON te.tierlist_id = t.id
WHERE t.user_id IN (1, 2, 3) AND t.anio = 2024
GROUP BY te.game_nombre, te.game_plataforma
HAVING COUNT(DISTINCT t.user_id) = 3;
```
