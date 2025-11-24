# 📁 Estructura del Proyecto Spring Boot

## Estructura Recomendada

```
game-tierlist/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── gametierlist/
│   │   │           ├── GameTierlistApplication.java
│   │   │           ├── config/
│   │   │           │   └── OpenApiConfig.java
│   │   │           ├── controller/
│   │   │           │   ├── CategoryController.java
│   │   │           │   ├── ExploreController.java
│   │   │           │   ├── GameController.java
│   │   │           │   ├── TierlistController.java
│   │   │           │   └── UserController.java
│   │   │           ├── dto/
│   │   │           │   ├── request/
│   │   │           │   │   ├── CreateEntryRequest.java
│   │   │           │   │   ├── CreateGameRequest.java
│   │   │           │   │   ├── CreateTierlistRequest.java
│   │   │           │   │   ├── CreateUserRequest.java
│   │   │           │   │   ├── UpdateEntryRequest.java
│   │   │           │   │   ├── UpdateGameRequest.java
│   │   │           │   │   └── UpdateUserRequest.java
│   │   │           │   └── response/
│   │   │           │       ├── ActiveUser.java
│   │   │           │       ├── CategoryResponse.java
│   │   │           │       ├── CategoryStats.java
│   │   │           │       ├── CommonGame.java
│   │   │           │       ├── ComparisonUser.java
│   │   │           │       ├── ErrorResponse.java
│   │   │           │       ├── GameResponse.java
│   │   │           │       ├── TierlistComparison.java
│   │   │           │       ├── TierlistDetail.java
│   │   │           │       ├── TierlistEntryResponse.java
│   │   │           │       ├── TierlistEntryWithUser.java
│   │   │           │       ├── TierlistOverview.java
│   │   │           │       ├── TierlistStats.java
│   │   │           │       ├── TierlistSummary.java
│   │   │           │       ├── TopGame.java
│   │   │           │       ├── UniqueGame.java
│   │   │           │       └── UserResponse.java
│   │   │           ├── entity/
│   │   │           │   ├── BaseEntity.java
│   │   │           │   ├── Category.java
│   │   │           │   ├── Game.java
│   │   │           │   ├── Tierlist.java
│   │   │           │   ├── TierlistEntry.java
│   │   │           │   └── User.java
│   │   │           ├── exception/
│   │   │           │   ├── DuplicateEntityException.java
│   │   │           │   ├── EntityInUseException.java
│   │   │           │   ├── EntityNotFoundException.java
│   │   │           │   ├── GlobalExceptionHandler.java
│   │   │           │   ├── InvalidParameterException.java
│   │   │           │   └── RelatedEntityNotFoundException.java
│   │   │           ├── mapper/
│   │   │           │   ├── CategoryMapper.java
│   │   │           │   ├── GameMapper.java
│   │   │           │   ├── TierlistMapper.java
│   │   │           │   └── UserMapper.java
│   │   │           ├── repository/
│   │   │           │   ├── CategoryRepository.java
│   │   │           │   ├── GameRepository.java
│   │   │           │   ├── TierlistEntryRepository.java
│   │   │           │   ├── TierlistRepository.java
│   │   │           │   └── UserRepository.java
│   │   │           ├── service/
│   │   │           │   ├── CategoryService.java
│   │   │           │   ├── ExploreService.java
│   │   │           │   ├── GameService.java
│   │   │           │   ├── TierlistService.java
│   │   │           │   └── UserService.java
│   │   │           └── specification/
│   │   │               ├── GameSpecification.java
│   │   │               └── TierlistEntrySpecification.java
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── data.sql
│   │       └── schema.sql (opcional, JPA puede generar)
│   └── test/
│       └── java/
│           └── com/
│               └── gametierlist/
│                   ├── controller/
│                   │   ├── CategoryControllerTest.java
│                   │   ├── GameControllerTest.java
│                   │   ├── TierlistControllerTest.java
│                   │   └── UserControllerTest.java
│                   ├── integration/
│                   │   ├── GameSearchIT.java
│                   │   ├── ExploreSearchIT.java
│                   │   └── TierlistIT.java
│                   ├── repository/
│                   │   ├── CategoryRepositoryTest.java
│                   │   ├── GameRepositoryTest.java
│                   │   ├── TierlistRepositoryTest.java
│                   │   └── UserRepositoryTest.java
│                   └── service/
│                       ├── CategoryServiceTest.java
│                       ├── ExploreServiceTest.java
│                       ├── GameServiceTest.java
│                       ├── TierlistServiceTest.java
│                       └── UserServiceTest.java
├── pom.xml
└── README.md
```

---

## Descripción de Capas

### Controller (`controller/`)

Maneja las peticiones HTTP y delega al Service.

```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Tag(name = "Users", description = "Gestión de usuarios")
public class UserController {

    private final UserService userService;

    @GetMapping
    @Operation(summary = "Listar todos los usuarios")
    public ResponseEntity<List<UserResponse>> getAll() {
        return ResponseEntity.ok(userService.findAll());
    }
}
```

**Responsabilidades:**
- Mapear URLs a métodos
- Validar entrada (`@Valid`)
- Devolver códigos HTTP correctos
- Documentar con OpenAPI

---

### Service (`service/`)

Contiene la lógica de negocio.

```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public List<UserResponse> findAll() {
        return userRepository.findAll().stream()
            .map(userMapper::toResponse)
            .toList();
    }

    @Transactional
    public UserResponse create(CreateUserRequest request) {
        // Validaciones de negocio
        if (userRepository.existsByNombre(request.nombre())) {
            throw new DuplicateEntityException("Usuario ya existe");
        }
        
        var user = userMapper.toEntity(request);
        var saved = userRepository.save(user);
        return userMapper.toResponse(saved);
    }
}
```

**Responsabilidades:**
- Lógica de negocio
- Validaciones complejas
- Transacciones
- Orquestar repositorios

---

### Repository (`repository/`)

Acceso a datos con Spring Data JPA.

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    boolean existsByNombre(String nombre);

    boolean existsByNombreAndIdNot(String nombre, Long id);

    Optional<User> findByNombre(String nombre);
}
```

**Responsabilidades:**
- CRUD básico (heredado)
- Métodos de consulta derivados
- Queries personalizados (`@Query`)

---

### Entity (`entity/`)

Entidades JPA que mapean a tablas.

```java
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
public class User extends BaseEntity {

    @Column(nullable = false, unique = true, length = 100)
    private String nombre;

    @Column(unique = true, length = 150)
    private String email;

    public User(String nombre) {
        this.nombre = nombre;
    }
}
```

**Responsabilidades:**
- Mapeo a base de datos
- Validaciones a nivel de BD (constraints)
- Relaciones entre entidades

---

### DTO (`dto/`)

Data Transfer Objects para entrada y salida.

```java
// Request - entrada con validaciones
public record CreateUserRequest(
    @NotBlank(message = "El nombre es obligatorio")
    @Size(max = 100)
    String nombre,

    @Email(message = "Email inválido")
    String email
) {}

// Response - salida inmutable
public record UserResponse(
    Long id,
    String nombre,
    String email,
    LocalDateTime fechaCreacion
) {}
```

**Responsabilidades:**
- Definir contrato de API
- Validaciones de entrada
- Evitar exponer entidades directamente

---

### Mapper (`mapper/`)

Convierte entre Entity y DTO.

```java
@Component
public class UserMapper {

    public UserResponse toResponse(User user) {
        return new UserResponse(
            user.getId(),
            user.getNombre(),
            user.getEmail(),
            user.getCreatedAt()
        );
    }

    public User toEntity(CreateUserRequest request) {
        var user = new User(request.nombre().trim());
        user.setEmail(request.email());
        return user;
    }
}
```

**Responsabilidades:**
- Transformar Entity → DTO
- Transformar DTO → Entity
- Aplicar lógica de transformación (trim, etc.)

---

### Exception (`exception/`)

Excepciones personalizadas y handler global.

```java
// Excepción
public class EntityNotFoundException extends RuntimeException {
    public EntityNotFoundException(String entity, Long id) {
        super(entity + " con id " + id + " no encontrado");
    }
}

// Handler global
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(
            EntityNotFoundException ex, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("NOT_FOUND", ex.getMessage(), 
                request.getRequestURI()));
    }
}
```

**Responsabilidades:**
- Definir excepciones de dominio
- Centralizar manejo de errores
- Devolver respuestas consistentes

---

### Specification (`specification/`)

Filtros dinámicos con JPA Criteria API.

```java
public class GameSpecification {

    public static Specification<Game> withFilters(
            String nombre, String plataforma, Long categoriaId) {

        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (nombre != null && !nombre.isBlank()) {
                predicates.add(cb.like(
                    cb.lower(root.get("nombre")),
                    "%" + nombre.toLowerCase() + "%"));
            }

            // ... más predicados

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
```

**Responsabilidades:**
- Construir queries dinámicos
- Combinar filtros con AND/OR
- Reutilizar lógica de búsqueda

---

### Config (`config/`)

Configuraciones de Spring.

```java
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Game Tierlist API")
                .version("1.0")
                .description("API para gestionar tierlists de juegos"));
    }
}
```

---

## Flujo de una Petición

```
┌─────────┐     ┌────────────┐     ┌─────────┐     ┌────────────┐     ┌────┐
│ Cliente │ ──► │ Controller │ ──► │ Service │ ──► │ Repository │ ──► │ BD │
└─────────┘     └────────────┘     └─────────┘     └────────────┘     └────┘
                      │                 │
                      ▼                 ▼
                  Validar           Mapper
                  @Valid            Entity↔DTO
```

### Ejemplo: POST /api/users

1. **Controller** recibe la petición y valida con `@Valid`
2. **Service** verifica reglas de negocio (no duplicado)
3. **Mapper** convierte Request → Entity
4. **Repository** guarda en BD
5. **Mapper** convierte Entity → Response
6. **Controller** devuelve 201 + Response

---

## Convenciones de Nombres

| Tipo | Convención | Ejemplo |
|------|------------|---------|
| Controller | `{Entity}Controller` | `UserController` |
| Service | `{Entity}Service` | `UserService` |
| Repository | `{Entity}Repository` | `UserRepository` |
| Entity | `{Nombre}` | `User` |
| Request DTO | `Create{Entity}Request` | `CreateUserRequest` |
| Response DTO | `{Entity}Response` | `UserResponse` |
| Mapper | `{Entity}Mapper` | `UserMapper` |
| Specification | `{Entity}Specification` | `GameSpecification` |
| Excepción | `{Descripción}Exception` | `EntityNotFoundException` |

---

## Conteo Final de Archivos

| Carpeta | Cantidad | Descripción |
|---------|----------|-------------|
| controller | 5 | Category, User, Game, Tierlist, Explore |
| service | 5 | Uno por controller |
| repository | 5 | Category, User, Game, Tierlist, TierlistEntry |
| entity | 6 | BaseEntity + 5 entidades |
| dto/request | 7 | Create/Update para cada entidad |
| dto/response | 17 | Responses y DTOs auxiliares |
| mapper | 4 | Category, User, Game, Tierlist |
| exception | 6 | 5 excepciones + handler |
| specification | 2 | Game, TierlistEntry |
| config | 1 | OpenAPI |
| **Total** | **~58** | Archivos Java |
