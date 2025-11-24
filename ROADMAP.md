# 🗺️ Roadmap del Proyecto Game Tierlist

## Visión General

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GAME TIERLIST                                      │
│                                                                              │
│  Sprint 1        Sprint 2        Sprint 3        Sprint 4        Sprint 5   │
│  ┌────────┐      ┌────────┐      ┌────────┐      ┌────────┐      ┌────────┐ │
│  │ Setup  │  →   │Usuarios│  →   │Catálogo│  →   │Tierlist│  →   │Explorar│ │
│  │Fundamen│      │  CRUD  │      │ Juegos │      │Personal│      │Comparar│ │
│  └────────┘      └────────┘      └────────┘      └────────┘      └────────┘ │
│   13 pts          12 pts          19 pts          24 pts          21 pts    │
│   8 tickets       6 tickets       5 tickets       7 tickets       5 tickets │
└─────────────────────────────────────────────────────────────────────────────┘
                                                            Total: 89 pts
                                                                   31 tickets
```

---

## 📅 Sprint 1: Setup y Fundamentos (13 puntos)

**Épica:** Configuración inicial y entidades base

| ID | Ticket | Puntos | Conceptos |
|----|--------|--------|-----------|
| SETUP-01 | Crear proyecto Spring Boot 3 | 3 | Estructura, dependencias |
| SETUP-02 | Configurar perfil desarrollo (H2) | 2 | H2, logging SQL |
| SETUP-03 | Configurar CORS | 1 | WebMvcConfigurer |
| SETUP-04 | Configurar Swagger/OpenAPI | 2 | springdoc v2 |
| SETUP-05 | Manejador global de excepciones | 3 | @ControllerAdvice, Records |
| SETUP-06 | BaseEntity con auditoría | 2 | @MappedSuperclass, JPA Auditing |
| CAT-01 | Entidad Category + datos iniciales | 2 | @Entity, data.sql |
| CAT-02 | GET /api/categories | 3 | Controller, Service, Repository |

**Objetivo:** Tener la base del proyecto funcionando con un CRUD de solo lectura.

**Al finalizar:**
- ✅ Proyecto arranca sin errores
- ✅ H2 Console accesible
- ✅ Swagger UI muestra endpoints
- ✅ GET /api/categories funciona

---

## 📅 Sprint 2: Gestión de Usuarios (12 puntos)

**Épica:** CRUD completo de usuarios con validaciones y testing

| ID | Ticket | Puntos | Conceptos |
|----|--------|--------|-----------|
| USER-01 | Entidad User + Repository | 2 | Constraints, métodos derivados |
| USER-02 | GET /api/users - Listar | 2 | Stream.toList(), ordenación |
| USER-03 | POST /api/users - Crear | 3 | @Valid, Records con validaciones |
| USER-04 | GET /api/users/{id} | 1 | Optional.orElseThrow() |
| USER-05 | PUT /api/users/{id} - Actualizar | 2 | Verificar duplicados |
| USER-06 | DELETE /api/users/{id} - Eliminar | 2 | Verificar existencia |

**Objetivo:** CRUD completo con validaciones, excepciones personalizadas y tests.

**Al finalizar:**
- ✅ CRUD completo de usuarios
- ✅ Validaciones funcionan (400 en errores)
- ✅ Excepciones devuelven JSON consistente
- ✅ Tests unitarios pasan

---

## 📅 Sprint 3: Catálogo de Juegos (19 puntos)

**Épica:** CRUD de juegos con relaciones, paginación y búsqueda avanzada

| ID | Ticket | Puntos | Conceptos |
|----|--------|--------|-----------|
| GAME-01 | Entidad Game + Repository | 3 | @ManyToOne LAZY, unique compuesto |
| GAME-02 | GET /api/games con paginación | 3 | Pageable, Page<T> |
| GAME-03 | POST /api/games | 5 | Validar FK existe |
| GAME-04 | GET/PUT/DELETE por ID | 3 | CRUD completo |
| GAME-05 | GET /api/games/search | 5 | **JPA Specifications** ⭐ |

**Objetivo:** Catálogo de juegos con relación a categorías y búsqueda dinámica.

**Al finalizar:**
- ✅ Juegos relacionados con categorías
- ✅ Paginación funciona
- ✅ Búsqueda con múltiples filtros
- ✅ Specifications reutilizables

---

## 📅 Sprint 4: Tierlists Personales (24 puntos)

**Épica:** Funcionalidad principal - tierlists por usuario y año

| ID | Ticket | Puntos | Conceptos |
|----|--------|--------|-----------|
| TIER-01 | Entidades Tierlist y TierlistEntry | 5 | @OneToMany, cascade, **denormalización** |
| TIER-02 | POST crear tierlist | 3 | Validar usuario y año único |
| TIER-03 | GET listar tierlists | 3 | Ordenación, conteos |
| TIER-04 | GET detalle con entries | 3 | **@EntityGraph**, evitar N+1 |
| TIER-05 | POST añadir juego | 5 | Crear tierlist si no existe |
| TIER-06 | PUT/DELETE entries | 3 | Actualizar rating, eliminar |
| TIER-07 | Verificar juego en uso | 2 | EntityInUseException |

**Objetivo:** Sistema completo de tierlists con campos denormalizados para rendimiento.

**Al finalizar:**
- ✅ Usuarios pueden crear tierlists por año
- ✅ Añadir/modificar/eliminar juegos de tierlists
- ✅ Datos del juego copiados a entries (denormalización)
- ✅ No hay problemas N+1

---

## 📅 Sprint 5: Explorar y Comparar (21 puntos)

**Épica:** Funcionalidades avanzadas de exploración y estadísticas

| ID | Ticket | Puntos | Conceptos |
|----|--------|--------|-----------|
| EXPL-01 | GET /api/tierlists (todas) | 3 | Listar todas las tierlists |
| EXPL-02 | GET /api/tierlists/entries | 5 | Búsqueda con Specifications |
| EXPL-03 | GET /api/tierlists/compare | 8 | **Comparación entre usuarios** ⭐ |
| EXPL-04 | GET /api/tierlists/stats | 5 | Agregaciones, Stream API |
| EXPL-05 | Verificación final | 0 | Checklist completo |

**Objetivo:** Explorar tierlists de todos, comparar valoraciones, ver estadísticas.

**Al finalizar:**
- ✅ Ver todas las tierlists públicamente
- ✅ Buscar entries con filtros avanzados
- ✅ Comparar tierlists de 2+ usuarios
- ✅ Ver estadísticas globales
- ✅ **Proyecto completado** 🎉

---

## 📊 Progresión de Conceptos

```
Sprint 1: Básico
├── Estructura proyecto
├── Entidades simples
└── Endpoints GET

Sprint 2: Intermedio
├── CRUD completo
├── Validaciones
├── Excepciones
└── Testing unitario

Sprint 3: Avanzado
├── Relaciones @ManyToOne
├── Paginación
├── Specifications
└── Filtros dinámicos

Sprint 4: Experto
├── Relaciones @OneToMany
├── Cascade y orphanRemoval
├── Denormalización
├── @EntityGraph
└── Prevención N+1

Sprint 5: Maestría
├── Queries complejos
├── Agregaciones
├── Stream API avanzado
└── DTOs anidados
```

---

## 🎯 Conceptos Java 17 por Sprint

| Sprint | Conceptos Java 17 |
|--------|-------------------|
| 1 | Records básicos |
| 2 | Records con validaciones, var |
| 3 | Stream.toList(), var |
| 4 | Switch expressions para tier |
| 5 | Stream API avanzado, Collectors |

---

## 🎯 Conceptos Spring Boot 3 por Sprint

| Sprint | Conceptos Spring Boot 3 |
|--------|------------------------|
| 1 | Estructura, jakarta.* |
| 2 | jakarta.validation, @ControllerAdvice |
| 3 | Pageable, Page<T>, JpaSpecificationExecutor |
| 4 | Cascade, @EntityGraph, orphanRemoval |
| 5 | Queries complejos, agregaciones |

---

## ⏱️ Estimación de Tiempo

| Sprint | Story Points | Tiempo estimado |
|--------|--------------|-----------------|
| 1 | 13 | 6-8 horas |
| 2 | 12 | 6-8 horas |
| 3 | 19 | 8-10 horas |
| 4 | 24 | 10-12 horas |
| 5 | 21 | 8-10 horas |
| **Total** | **89** | **38-48 horas** |

*Estimación para desarrollador con experiencia en Java 8 / Spring Boot 2*

---

## 📝 Notas

- Cada sprint tiene su archivo de tickets CSV para importar a Jira
- Cada sprint tiene su archivo de soluciones MD como referencia
- Los sprints son secuenciales (cada uno depende del anterior)
- El frontend (`frontend/index.html`) es funcional y se puede usar para probar
