# ☕ Guía de Migración: Java 8 → Java 17

Esta guía cubre las características de Java 17 que usarás en el proyecto Game Tierlist.

---

## 1. Records (Java 14+)

### Antes (Java 8): Clases POJO verbosas

```java
public class UserResponse {
    private final Long id;
    private final String nombre;
    private final String email;
    private final LocalDateTime fechaCreacion;

    public UserResponse(Long id, String nombre, String email, LocalDateTime fechaCreacion) {
        this.id = id;
        this.nombre = nombre;
        this.email = email;
        this.fechaCreacion = fechaCreacion;
    }

    public Long getId() { return id; }
    public String getNombre() { return nombre; }
    public String getEmail() { return email; }
    public LocalDateTime getFechaCreacion() { return fechaCreacion; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UserResponse that = (UserResponse) o;
        return Objects.equals(id, that.id) &&
               Objects.equals(nombre, that.nombre) &&
               Objects.equals(email, that.email) &&
               Objects.equals(fechaCreacion, that.fechaCreacion);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, nombre, email, fechaCreacion);
    }

    @Override
    public String toString() {
        return "UserResponse{id=" + id + ", nombre='" + nombre + "', ...}";
    }
}
```

### Después (Java 17): Records concisos

```java
public record UserResponse(
    Long id,
    String nombre,
    String email,
    LocalDateTime fechaCreacion
) {}
```

### Records con validaciones (Spring Boot 3)

```java
public record CreateUserRequest(
    @NotBlank(message = "El nombre es obligatorio")
    @Size(max = 100, message = "Máximo 100 caracteres")
    String nombre,

    @NotBlank(message = "El email es obligatorio")
    @Email(message = "Formato de email inválido")
    String email
) {}
```

### Uso en el proyecto

| Tipo | Uso |
|------|-----|
| `*Response` | DTOs de salida (inmutables) |
| `*Request` | DTOs de entrada con validaciones |

---

## 2. Sealed Classes (Java 17)

Restringen qué clases pueden extender una clase base.

### Ejemplo en el proyecto

```java
public sealed class BaseException extends RuntimeException
    permits EntityNotFoundException, DuplicateEntityException, EntityInUseException {
    
    public BaseException(String message) {
        super(message);
    }
}

public final class EntityNotFoundException extends BaseException {
    public EntityNotFoundException(String entity, Long id) {
        super(entity + " con id " + id + " no encontrado");
    }
}

public final class DuplicateEntityException extends BaseException {
    public DuplicateEntityException(String message) {
        super(message);
    }
}
```

### Beneficios

- El compilador conoce todas las subclases posibles
- Mejor para pattern matching exhaustivo
- Documenta la intención del diseño

---

## 3. Pattern Matching para instanceof (Java 16+)

### Antes (Java 8)

```java
if (obj instanceof String) {
    String str = (String) obj;
    System.out.println(str.length());
}
```

### Después (Java 17)

```java
if (obj instanceof String str) {
    System.out.println(str.length());
}

// También con negación
if (!(obj instanceof String str)) {
    return;
}
// str disponible aquí
```

### Uso práctico en excepciones

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<ErrorResponse> handleException(Exception ex) {
    if (ex instanceof EntityNotFoundException notFound) {
        return ResponseEntity.notFound().build();
    }
    if (ex instanceof DuplicateEntityException duplicate) {
        return ResponseEntity.status(CONFLICT).body(createError(duplicate));
    }
    return ResponseEntity.internalServerError().build();
}
```

---

## 4. Switch Expressions (Java 14+)

### Antes (Java 8): Switch statement

```java
String tier;
switch (rating) {
    case 10:
    case 9:
        tier = "S";
        break;
    case 8:
    case 7:
        tier = "A";
        break;
    case 6:
    case 5:
        tier = "B";
        break;
    case 4:
    case 3:
        tier = "C";
        break;
    default:
        tier = "D";
        break;
}
```

### Después (Java 17): Switch expression

```java
String tier = switch (rating) {
    case 10, 9 -> "S";
    case 8, 7 -> "A";
    case 6, 5 -> "B";
    case 4, 3 -> "C";
    case 2, 1 -> "D";
    default -> "?";
};
```

### Con bloques y yield

```java
String descripcion = switch (tier) {
    case "S" -> "Obra maestra";
    case "A" -> "Excelente";
    case "B" -> {
        logger.info("Juego promedio");
        yield "Bueno";
    }
    default -> "Regular";
};
```

### Uso en el proyecto (TierlistMapper)

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

## 5. Text Blocks (Java 15+)

### Antes (Java 8)

```java
String json = "{\n" +
    "  \"nombre\": \"" + nombre + "\",\n" +
    "  \"email\": \"" + email + "\"\n" +
    "}";

String sql = "SELECT u.id, u.nombre " +
    "FROM users u " +
    "WHERE u.activo = true " +
    "ORDER BY u.nombre";
```

### Después (Java 17)

```java
String json = """
    {
      "nombre": "%s",
      "email": "%s"
    }
    """.formatted(nombre, email);

String sql = """
    SELECT u.id, u.nombre
    FROM users u
    WHERE u.activo = true
    ORDER BY u.nombre
    """;
```

### Uso práctico: JPQL queries

```java
@Query("""
    SELECT new com.gametierlist.dto.CategoryStats(
        e.gameCategoria,
        COUNT(e),
        AVG(e.rating)
    )
    FROM TierlistEntry e
    GROUP BY e.gameCategoria
    ORDER BY AVG(e.rating) DESC
    """)
List<CategoryStats> getCategoryStats();
```

---

## 6. var - Inferencia de tipos locales (Java 10+)

### Cuándo usar

```java
// ✅ Tipo obvio por el lado derecho
var user = new User("Carlos");
var games = gameRepository.findAll();
var response = new GameResponse(1L, "Zelda", "Nintendo");

// ✅ En lambdas para añadir anotaciones
list.stream()
    .filter((@NonNull var item) -> item.isActive())
    .toList();

// ✅ En loops
for (var entry : tierlist.getEntries()) {
    process(entry);
}
```

### Cuándo NO usar

```java
// ❌ Tipo no obvio
var result = service.process();  // ¿Qué tipo es result?

// ❌ Literales numéricos ambiguos
var count = 0;  // ¿int? ¿long? ¿Integer?

// ❌ null
var something = null;  // Error de compilación
```

### Regla de oro

> Usa `var` cuando el tipo es **obvio** por el contexto. Si tienes que pensar qué tipo es, usa el tipo explícito.

---

## 7. Stream.toList() (Java 16+)

### Antes (Java 8)

```java
List<String> nombres = users.stream()
    .map(User::getNombre)
    .collect(Collectors.toList());
```

### Después (Java 16+)

```java
List<String> nombres = users.stream()
    .map(User::getNombre)
    .toList();  // Más conciso
```

### ⚠️ Diferencia importante

| Método | Lista resultante |
|--------|------------------|
| `collect(Collectors.toList())` | Mutable |
| `toList()` | **Inmutable** |

```java
var lista = stream.toList();
lista.add("nuevo");  // ❌ UnsupportedOperationException

var listaMutable = stream.collect(Collectors.toList());
listaMutable.add("nuevo");  // ✅ Funciona
```

---

## 8. Nuevos métodos en String (Java 11+)

```java
// isBlank() - mejor que isEmpty() para validaciones
"   ".isBlank();  // true
"".isEmpty();     // true
"   ".isEmpty();  // false

// strip() - mejor que trim() (maneja Unicode)
"  texto  ".strip();       // "texto"
"  texto  ".stripLeading(); // "texto  "
"  texto  ".stripTrailing();// "  texto"

// lines() - divide en stream de líneas
String multiline = """
    línea 1
    línea 2
    línea 3
    """;
multiline.lines().forEach(System.out::println);

// repeat()
"=".repeat(50);  // "=================================================="

// indent()
"texto".indent(4);  // "    texto\n"
```

---

## 9. Mejoras en Optional (Java 9+)

### ifPresentOrElse (Java 9)

```java
// Antes
Optional<User> user = repo.findById(id);
if (user.isPresent()) {
    process(user.get());
} else {
    handleNotFound();
}

// Después
repo.findById(id).ifPresentOrElse(
    this::process,
    this::handleNotFound
);
```

### or() (Java 9)

```java
// Encadenar Optionals
Optional<User> user = repo.findByEmail(email)
    .or(() -> repo.findByNombre(nombre))
    .or(() -> Optional.of(defaultUser));
```

### stream() (Java 9)

```java
// Convertir Optional a Stream (útil en flatMap)
List<String> emails = users.stream()
    .map(User::getEmail)
    .flatMap(Optional::stream)  // Filtra los vacíos
    .toList();
```

### orElseThrow() sin argumentos (Java 10)

```java
// Antes
User user = repo.findById(id)
    .orElseThrow(() -> new NoSuchElementException());

// Después
User user = repo.findById(id).orElseThrow();  // Lanza NoSuchElementException
```

---

## 10. Collectors adicionales (Java 9+)

### Collectors.teeing (Java 12)

Aplica dos collectors y combina resultados:

```java
record MinMax(Integer min, Integer max) {}

MinMax result = ratings.stream().collect(
    Collectors.teeing(
        Collectors.minBy(Integer::compareTo),
        Collectors.maxBy(Integer::compareTo),
        (min, max) -> new MinMax(
            min.orElse(0), 
            max.orElse(0)
        )
    )
);
```

### Uso en estadísticas del proyecto

```java
// Calcular min, max y promedio en una pasada
record RatingStats(int min, int max, double avg) {}

var stats = entries.stream()
    .map(TierlistEntry::getRating)
    .collect(Collectors.teeing(
        Collectors.teeing(
            Collectors.minBy(Integer::compareTo),
            Collectors.maxBy(Integer::compareTo),
            (min, max) -> new int[]{min.orElse(0), max.orElse(0)}
        ),
        Collectors.averagingInt(Integer::intValue),
        (minMax, avg) -> new RatingStats(minMax[0], minMax[1], avg)
    ));
```

---

## 📋 Resumen: Qué usar en cada Sprint

| Sprint | Características Java 17 |
|--------|------------------------|
| 1 | Records para Response |
| 2 | Records con validaciones, var, isBlank() |
| 3 | Stream.toList(), var en loops |
| 4 | Switch expressions para tiers |
| 5 | Stream API avanzado, Collectors, Optional.or() |

---

## 🔗 Referencias

- [JEP 395: Records](https://openjdk.org/jeps/395)
- [JEP 409: Sealed Classes](https://openjdk.org/jeps/409)
- [JEP 394: Pattern Matching for instanceof](https://openjdk.org/jeps/394)
- [JEP 361: Switch Expressions](https://openjdk.org/jeps/361)
- [JEP 378: Text Blocks](https://openjdk.org/jeps/378)
