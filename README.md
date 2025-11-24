# 🎮 Game Tierlist - Proyecto Didáctico

Proyecto de aprendizaje para actualizar conocimientos de **Java 8 → Java 17** y **Spring Boot 2 → Spring Boot 3**.

## 🎯 Objetivo

Construir una aplicación para que grupos de amigos puedan:
- Registrar los juegos que han jugado cada año
- Asignar puntuaciones (1-10) y tiers (S/A/B/C/D)
- Comparar valoraciones entre usuarios
- Explorar estadísticas agregadas

## 📚 Estructura del Proyecto

```
game-tierlist-final/
├── README.md                    # Este archivo
├── ROADMAP.md                   # Visión general de sprints
├── schema.sql                   # Script de base de datos
├── swagger.yaml                 # Especificación OpenAPI
├── docs/
│   ├── JAVA8-A-JAVA17.md        # Guía de migración Java
│   ├── SPRINGBOOT2-A-SPRINGBOOT3.md  # Guía de migración Spring Boot
│   ├── NOVEDADES-SPRING-BOOT-3.4.md  # Novedades de Spring Boot 3.4
│   ├── MODELO-DATOS.md          # Modelo de datos detallado
│   └── ESTRUCTURA-PROYECTO.md   # Estructura de carpetas
├── jira/
│   ├── SPRINT-1-tickets.csv     # Tickets Sprint 1
│   ├── SPRINT-1-soluciones.md   # Soluciones Sprint 1
│   ├── SPRINT-2-tickets.csv     # Tickets Sprint 2
│   ├── SPRINT-2-soluciones.md   # Soluciones Sprint 2
│   ├── SPRINT-3-tickets.csv     # Tickets Sprint 3
│   ├── SPRINT-3-soluciones.md   # Soluciones Sprint 3
│   ├── SPRINT-4-tickets.csv     # Tickets Sprint 4
│   ├── SPRINT-4-soluciones.md   # Soluciones Sprint 4
│   ├── SPRINT-5-tickets.csv     # Tickets Sprint 5
│   └── SPRINT-5-soluciones.md   # Soluciones Sprint 5
└── frontend/
    ├── GUIA-FRONTEND.md         # Guía del frontend
    └── index.html               # Frontend funcional
```

## 🚀 Cómo empezar

### 1. Crear el proyecto Spring Boot

Usa [Spring Initializr](https://start.spring.io/) con:
- **Java 17**
- **Spring Boot 3.4.12**
- Dependencias: Spring Web, Spring Data JPA, H2 Database, Lombok, Validation

### 2. Importar tickets a Jira

Los archivos CSV en `/jira/` están listos para importar:
1. Ve a tu proyecto Jira
2. Importa cada `SPRINT-X-tickets.csv`
3. Crea el sprint correspondiente

### 3. Seguir el roadmap

Consulta `ROADMAP.md` para el orden recomendado.

## 📊 Resumen de Sprints

| Sprint | Épica | Tickets | Puntos | Conceptos clave |
|--------|-------|---------|--------|-----------------|
| 1 | Setup y Fundamentos | 8 | 13 | Records, BaseEntity, CORS, Swagger |
| 2 | Usuarios CRUD | 6 | 12 | Validaciones, excepciones, testing |
| 3 | Catálogo Juegos | 5 | 19 | @ManyToOne, paginación, Specifications |
| 4 | Tierlists | 7 | 24 | @OneToMany, cascade, denormalización |
| 5 | Explorar | 5 | 21 | Comparaciones, estadísticas, JPQL |
| **Total** | | **31** | **89** | |

## 🔧 Tecnologías

| Tecnología | Versión |
|------------|---------|
| Java | 17 |
| Spring Boot | 3.4.12 |
| Spring Data JPA | 3.x |
| H2 Database | 2.x |
| Lombok | 1.18+ |
| OpenAPI/Swagger | 3.0 |

## 📖 Conceptos Java 17 cubiertos

- ✅ Records (DTOs inmutables)
- ✅ Sealed Classes
- ✅ Pattern Matching para instanceof
- ✅ Switch Expressions
- ✅ Text Blocks
- ✅ var (inferencia de tipos)
- ✅ Stream.toList()

## 📖 Conceptos Spring Boot 3 cubiertos

- ✅ jakarta.* (migración desde javax.*)
- ✅ Validaciones con jakarta.validation
- ✅ JPA Specifications para filtros dinámicos
- ✅ @EntityGraph para evitar N+1
- ✅ Paginación con Pageable
- ✅ Manejo global de excepciones
- ✅ OpenAPI/Swagger UI

## 🎓 Metodología de aprendizaje

1. **Lee el ticket** con la especificación funcional
2. **Implementa** siguiendo las pistas
3. **Escribe tests** según los criterios de aceptación
4. **Consulta la solución** solo si te atascas
5. **Compara** tu implementación con la referencia

## 📝 Licencia

Proyecto educativo de uso libre.
