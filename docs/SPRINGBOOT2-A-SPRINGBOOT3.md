# 🍃 Guía de Migración: Spring Boot 2 → Spring Boot 3

Esta guía cubre los cambios de Spring Boot 3 que usarás en el proyecto Game Tierlist.

---

## 1. Migración de javax.* a jakarta.*

### El cambio más importante

Spring Boot 3 requiere **Jakarta EE 9+**, lo que significa cambiar todos los imports de `javax.*` a `jakarta.*`.

```java
// ❌ Spring Boot 2 (javax)
import javax.persistence.*;
import javax.validation.constraints.*;
import javax.servlet.*;

// ✅ Spring Boot 3 (jakarta)
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import jakarta.servlet.*;
```

### Paquetes afectados

| Antes (javax) | Después (jakarta) |
|---------------|-------------------|
| `javax.persistence` | `jakarta.persistence` |
| `javax.validation` | `jakarta.validation` |
| `javax.servlet` | `jakarta.servlet` |
| `javax.annotation` | `jakarta.annotation` |
| `javax.transaction` | `jakarta.transaction` |

### En el proyecto

```java
// Entidad con JPA
import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User extends BaseEntity {
    
    @Column(nullable = false, length = 100)
    private String nombre;
}

// DTO con validaciones
import jakarta.validation.constraints.*;

public record CreateUserRequest(
    @NotBlank(message = "El nombre es obligatorio")
    @Size(max = 100)
    String nombre,

    @Email(message = "Email inválido")
    String email
) {}
```

---

## 2. Dependencias actualizadas

### pom.xml para Spring Boot 3

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.4.12</version>
        <relativePath/>
    </parent>
    
    <groupId>com.gametierlist</groupId>
    <artifactId>game-tierlist</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>game-tierlist</name>
    <description>Proyecto didáctico Game Tierlist</description>
    
    <properties>
        <java.version>17</java.version>
    </properties>
    
    <dependencies>
        <!-- Spring Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <!-- Spring Data JPA -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <!-- Validación -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <!-- H2 Database -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- OpenAPI / Swagger -->
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>2.3.0</version>
        </dependency>
        
        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### Cambios en Swagger/OpenAPI

```xml
<!-- ❌ Spring Boot 2 -->
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-boot-starter</artifactId>
    <version>3.0.0</version>
</dependency>

<!-- ✅ Spring Boot 3 -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.3.0</version>
</dependency>
```

---

## 3. Relaciones JPA: LAZY por defecto

### @ManyToOne

```java
@Entity
public class Game extends BaseEntity {

    @Column(nullable = false, length = 100)
    private String nombre;

    // LAZY loading - la categoría NO se carga automáticamente
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;
}
```

### @OneToMany con cascade

```java
@Entity
public class Tierlist extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private Integer anio;

    // Cascade ALL: las operaciones se propagan a las entries
    // orphanRemoval: elimina entries huérfanas automáticamente
    @OneToMany(mappedBy = "tierlist", 
               cascade = CascadeType.ALL, 
               orphanRemoval = true)
    @OrderBy("rating DESC")
    private List<TierlistEntry> entries = new ArrayList<>();

    // Métodos helper para mantener sincronización bidireccional
    public void addEntry(TierlistEntry entry) {
        entries.add(entry);
        entry.setTierlist(this);
    }

    public void removeEntry(TierlistEntry entry) {
        entries.remove(entry);
        entry.setTierlist(null);
    }
}
```

### Evitar N+1 con @EntityGraph

```java
@Repository
public interface TierlistRepository extends JpaRepository<Tierlist, Long> {

    // Sin @EntityGraph: N+1 queries
    Optional<Tierlist> findByUserIdAndAnio(Long userId, Integer anio);

    // Con @EntityGraph: 1 query con JOIN
    @EntityGraph(attributePaths = {"entries"})
    Optional<Tierlist> findWithEntriesByUserIdAndAnio(Long userId, Integer anio);

    // Cargar múltiples relaciones
    @EntityGraph(attributePaths = {"entries", "user"})
    Optional<Tierlist> findWithEntriesAndUserById(Long id);
}
```

### Alternativa: JOIN FETCH en @Query

```java
@Query("""
    SELECT t FROM Tierlist t
    LEFT JOIN FETCH t.entries
    WHERE t.user.id = :userId AND t.anio = :anio
    """)
Optional<Tierlist> findWithEntriesByUserIdAndAnio(
    @Param("userId") Long userId, 
    @Param("anio") Integer anio);
```

---

## 4. Validaciones con jakarta.validation

### Anotaciones disponibles

```java
public record CreateGameRequest(
    // Texto
    @NotBlank(message = "Obligatorio")           // No null, no vacío, no solo espacios
    @NotEmpty(message = "No puede estar vacío")  // No null, no vacío (permite espacios)
    @NotNull(message = "No puede ser null")      // Solo no null
    @Size(min = 1, max = 100)                    // Longitud
    @Pattern(regexp = "^[A-Z].*")                // Regex
    String nombre,

    // Email
    @Email(message = "Formato inválido")
    String email,

    // Números
    @Min(value = 1, message = "Mínimo 1")
    @Max(value = 10, message = "Máximo 10")
    @Positive                                     // > 0
    @PositiveOrZero                              // >= 0
    @Negative                                     // < 0
    Integer rating,

    // Fechas
    @Past(message = "Debe ser en el pasado")
    @Future(message = "Debe ser en el futuro")
    @PastOrPresent
    @FutureOrPresent
    LocalDate fecha,

    // Colecciones
    @NotEmpty
    @Size(min = 1, max = 10)
    List<Long> ids
) {}
```

### Activar validación en Controller

```java
@PostMapping
public ResponseEntity<GameResponse> create(
        @Valid @RequestBody CreateGameRequest request) {  // @Valid activa validación
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(gameService.create(request));
}
```

### Manejar errores de validación

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        
        String message = ex.getBindingResult().getFieldErrors().stream()
            .map(error -> error.getField() + ": " + error.getDefaultMessage())
            .collect(Collectors.joining(", "));

        var error = new ErrorResponse(
            "VALIDATION_ERROR",
            message,
            request.getRequestURI()
        );
        
        return ResponseEntity.badRequest().body(error);
    }
}
```

---

## 5. Paginación con Pageable

### En el Controller

```java
@GetMapping
public ResponseEntity<Page<GameResponse>> getAll(
        @PageableDefault(size = 20, sort = "nombre") Pageable pageable) {
    return ResponseEntity.ok(gameService.findAll(pageable));
}
```

### Parámetros de URL

```
GET /api/games?page=0&size=10&sort=nombre,asc
GET /api/games?page=1&size=20&sort=anioLanzamiento,desc
GET /api/games?sort=nombre,asc&sort=plataforma,desc  (múltiples)
```

### En el Service

```java
public Page<GameResponse> findAll(Pageable pageable) {
    return gameRepository.findAll(pageable)
        .map(gameMapper::toResponse);
}
```

### Respuesta Page<T>

```json
{
  "content": [...],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 20,
    "sort": { "sorted": true, "orders": [...] }
  },
  "totalElements": 150,
  "totalPages": 8,
  "last": false,
  "first": true,
  "numberOfElements": 20
}
```

---

## 6. JPA Specifications (Filtros dinámicos)

### Configurar Repository

```java
@Repository
public interface GameRepository extends 
        JpaRepository<Game, Long>, 
        JpaSpecificationExecutor<Game> {  // Añadir esta interfaz
}
```

### Crear Specification

```java
public class GameSpecification {

    private GameSpecification() {}

    public static Specification<Game> withFilters(
            String nombre,
            String plataforma,
            Long categoriaId,
            Integer anioMin,
            Integer anioMax) {

        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filtro parcial case-insensitive
            if (nombre != null && !nombre.isBlank()) {
                predicates.add(cb.like(
                    cb.lower(root.get("nombre")),
                    "%" + nombre.toLowerCase() + "%"
                ));
            }

            // Filtro exacto
            if (plataforma != null && !plataforma.isBlank()) {
                predicates.add(cb.equal(root.get("plataforma"), plataforma));
            }

            // Filtro por FK
            if (categoriaId != null) {
                predicates.add(cb.equal(
                    root.get("category").get("id"), categoriaId));
            }

            // Filtros de rango
            if (anioMin != null) {
                predicates.add(cb.greaterThanOrEqualTo(
                    root.get("anioLanzamiento"), anioMin));
            }

            if (anioMax != null) {
                predicates.add(cb.lessThanOrEqualTo(
                    root.get("anioLanzamiento"), anioMax));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
```

### Usar en Service

```java
public Page<GameResponse> search(
        String nombre, String plataforma, Long categoriaId,
        Integer anioMin, Integer anioMax, Pageable pageable) {

    var spec = GameSpecification.withFilters(
        nombre, plataforma, categoriaId, anioMin, anioMax);

    return gameRepository.findAll(spec, pageable)
        .map(gameMapper::toResponse);
}
```

### Usar en Controller

```java
@GetMapping("/search")
public ResponseEntity<Page<GameResponse>> search(
        @RequestParam(required = false) String nombre,
        @RequestParam(required = false) String plataforma,
        @RequestParam(required = false) Long categoriaId,
        @RequestParam(required = false) Integer anioMin,
        @RequestParam(required = false) Integer anioMax,
        Pageable pageable) {

    return ResponseEntity.ok(gameService.search(
        nombre, plataforma, categoriaId, anioMin, anioMax, pageable));
}
```

---

## 7. Manejo de Excepciones

### Estructura recomendada

```java
// Excepción base (opcional, para sealed classes)
public sealed class BaseException extends RuntimeException
    permits EntityNotFoundException, DuplicateEntityException {
    public BaseException(String message) {
        super(message);
    }
}

// No encontrado → 404
public final class EntityNotFoundException extends BaseException {
    public EntityNotFoundException(String entity, Long id) {
        super(entity + " con id " + id + " no encontrado");
    }
}

// Duplicado → 409
public final class DuplicateEntityException extends BaseException {
    public DuplicateEntityException(String message) {
        super(message);
    }
}

// En uso → 409
public class EntityInUseException extends RuntimeException {
    public EntityInUseException(String message) {
        super(message);
    }
}

// FK no existe → 404
public class RelatedEntityNotFoundException extends RuntimeException {
    public RelatedEntityNotFoundException(String entity, Long id) {
        super(entity + " con id " + id + " no encontrada");
    }
}
```

### DTO de Error

```java
public record ErrorResponse(
    String code,
    String message,
    String path,
    LocalDateTime timestamp
) {
    public ErrorResponse(String code, String message, String path) {
        this(code, message, path, LocalDateTime.now());
    }
}
```

### Handler Global

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(
            EntityNotFoundException ex, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("NOT_FOUND", ex.getMessage(), 
                request.getRequestURI()));
    }

    @ExceptionHandler(DuplicateEntityException.class)
    public ResponseEntity<ErrorResponse> handleDuplicate(
            DuplicateEntityException ex, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(new ErrorResponse("DUPLICATE_ENTITY", ex.getMessage(),
                request.getRequestURI()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex, HttpServletRequest request) {
        String message = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .collect(Collectors.joining(", "));
        return ResponseEntity.badRequest()
            .body(new ErrorResponse("VALIDATION_ERROR", message,
                request.getRequestURI()));
    }
}
```

---

## 8. Configuración application.properties

```properties
# Servidor
server.port=8080

# Base de datos H2
spring.datasource.url=jdbc:h2:mem:gametierlist
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# H2 Console
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console

# JPA
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# Inicialización
spring.sql.init.mode=always
spring.jpa.defer-datasource-initialization=true

# OpenAPI
springdoc.api-docs.path=/api-docs
springdoc.swagger-ui.path=/swagger-ui.html

# Logging
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
```

---

## 9. Testing en Spring Boot 3

### Test de Repository

```java
@DataJpaTest
class GameRepositoryTest {

    @Autowired
    private GameRepository gameRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    @DisplayName("Debe encontrar juego por ID")
    void shouldFindGameById() {
        // Arrange
        var category = entityManager.persistAndFlush(new Category("RPG", "Rol"));
        var game = entityManager.persistAndFlush(
            new Game("Elden Ring", "PC", "Desc", 2022, category));

        // Act
        var result = gameRepository.findById(game.getId());

        // Assert
        assertThat(result).isPresent();
        assertThat(result.get().getNombre()).isEqualTo("Elden Ring");
    }
}
```

### Test de Service

```java
@ExtendWith(MockitoExtension.class)
class GameServiceTest {

    @Mock
    private GameRepository gameRepository;

    @Mock
    private GameMapper gameMapper;

    @InjectMocks
    private GameService gameService;

    @Test
    @DisplayName("Debe crear juego cuando es válido")
    void shouldCreateGame_WhenValid() {
        // Arrange
        var request = new CreateGameRequest("Zelda", "Switch", null, 2023, 1L);
        var game = new Game(...);
        var response = new GameResponse(...);

        when(gameRepository.save(any())).thenReturn(game);
        when(gameMapper.toResponse(game)).thenReturn(response);

        // Act
        var result = gameService.create(request);

        // Assert
        assertThat(result.nombre()).isEqualTo("Zelda");
        verify(gameRepository).save(any());
    }
}
```

### Test de Controller

```java
@WebMvcTest(GameController.class)
class GameControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GameService gameService;

    @Test
    @DisplayName("Debe devolver 201 al crear juego")
    void shouldReturn201_WhenGameCreated() throws Exception {
        // Arrange
        var response = new GameResponse(1L, "Zelda", ...);
        when(gameService.create(any())).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/api/games")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "nombre": "Zelda",
                        "plataforma": "Switch",
                        "anioLanzamiento": 2023,
                        "categoriaId": 1
                    }
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.nombre").value("Zelda"));
    }
}
```

### Test de Integración

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class GameControllerIT {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private GameRepository gameRepository;

    @Test
    @DisplayName("Debe crear y recuperar juego")
    void shouldCreateAndRetrieveGame() {
        // Crear
        var request = Map.of(
            "nombre", "Test Game",
            "plataforma", "PC",
            "anioLanzamiento", 2024,
            "categoriaId", 1
        );

        var createResponse = restTemplate.postForEntity(
            "/api/games", request, GameResponse.class);
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);

        // Recuperar
        Long id = createResponse.getBody().id();
        var getResponse = restTemplate.getForEntity(
            "/api/games/" + id, GameResponse.class);
        assertThat(getResponse.getBody().nombre()).isEqualTo("Test Game");
    }
}
```

---

## 📋 Checklist de Migración

- [ ] Cambiar todos los `javax.*` por `jakarta.*`
- [ ] Actualizar `pom.xml` a Spring Boot 3.4.12
- [ ] Cambiar `springfox` por `springdoc-openapi`
- [ ] Verificar que Java 17 está configurado
- [ ] Actualizar propiedades de H2 si es necesario
- [ ] Verificar tests con nuevas anotaciones

---

## 🔗 Referencias

- [Spring Boot 3.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide)
- [Jakarta EE](https://jakarta.ee/)
- [SpringDoc OpenAPI](https://springdoc.org/)
