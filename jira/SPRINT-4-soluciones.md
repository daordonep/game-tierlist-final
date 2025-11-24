# 📖 Sprint 4: Soluciones de Referencia

> ⚠️ **Usa este documento solo si te atascas.** Intenta implementar primero por tu cuenta siguiendo las especificaciones del ticket.

---

## TIER-01: Crear entidades Tierlist y TierlistEntry

### Tierlist.java

```java
package com.gametierlist.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "tierlist",
    uniqueConstraints = @UniqueConstraint(
        name = "uk_tierlist_user_anio",
        columnNames = {"user_id", "anio"}
    )
)
@Getter
@Setter
@NoArgsConstructor
public class Tierlist extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private Integer anio;

    @OneToMany(mappedBy = "tierlist", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("rating DESC")
    private List<TierlistEntry> entries = new ArrayList<>();

    public Tierlist(User user, Integer anio) {
        this.user = user;
        this.anio = anio;
    }

    // Métodos helper para mantener sincronización bidireccional
    public void addEntry(TierlistEntry entry) {
        entries.add(entry);
        entry.setTierlist(this);
    }

    public void removeEntry(TierlistEntry entry) {
        entries.remove(entry);
        entry.setTierlist(null);
    }

    public int getTotalJuegos() {
        return entries.size();
    }
}
```

### TierlistEntry.java

```java
package com.gametierlist.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "tierlist_entry",
    uniqueConstraints = @UniqueConstraint(
        name = "uk_entry_tierlist_game",
        columnNames = {"tierlist_id", "game_id"}
    )
)
@Getter
@Setter
@NoArgsConstructor
public class TierlistEntry extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tierlist_id", nullable = false)
    private Tierlist tierlist;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "game_id", nullable = false)
    private Game game;

    @Column(nullable = false)
    private Integer rating;

    @Column(name = "anio_jugado", nullable = false)
    private Integer anioJugado;

    // ========== CAMPOS DENORMALIZADOS ==========
    // Copiados del Game para consultas rápidas sin JOINs

    @Column(name = "game_nombre", nullable = false, length = 100)
    private String gameNombre;

    @Column(name = "game_plataforma", nullable = false, length = 50)
    private String gamePlataforma;

    @Column(name = "game_categoria", nullable = false, length = 50)
    private String gameCategoria;

    @Column(name = "game_descripcion", length = 500)
    private String gameDescripcion;

    @Column(name = "game_anio_lanzamiento", nullable = false)
    private Integer gameAnioLanzamiento;

    // Constructor que copia datos del juego
    public TierlistEntry(Tierlist tierlist, Game game, Integer rating, Integer anioJugado) {
        this.tierlist = tierlist;
        this.game = game;
        this.rating = rating;
        this.anioJugado = anioJugado;

        // Copiar datos denormalizados
        this.gameNombre = game.getNombre();
        this.gamePlataforma = game.getPlataforma();
        this.gameCategoria = game.getCategory().getNombre();
        this.gameDescripcion = game.getDescripcion();
        this.gameAnioLanzamiento = game.getAnioLanzamiento();
    }
}
```

### TierlistRepository.java

```java
package com.gametierlist.repository;

import com.gametierlist.entity.Tierlist;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TierlistRepository extends JpaRepository<Tierlist, Long> {

    List<Tierlist> findByUserIdOrderByAnioDesc(Long userId);

    Optional<Tierlist> findByUserIdAndAnio(Long userId, Integer anio);

    boolean existsByUserIdAndAnio(Long userId, Integer anio);

    @EntityGraph(attributePaths = {"entries"})
    Optional<Tierlist> findWithEntriesByUserIdAndAnio(Long userId, Integer anio);
}
```

### TierlistEntryRepository.java

```java
package com.gametierlist.repository;

import com.gametierlist.entity.TierlistEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface TierlistEntryRepository extends JpaRepository<TierlistEntry, Long>,
                                                  JpaSpecificationExecutor<TierlistEntry> {

    boolean existsByTierlistIdAndGameId(Long tierlistId, Long gameId);

    boolean existsByGameId(Long gameId);
}
```

### Test de cascade delete

```java
@DataJpaTest
class TierlistRepositoryTest {

    @Autowired
    private TierlistRepository tierlistRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    @DisplayName("Debe eliminar entries en cascada al eliminar tierlist")
    void shouldCascadeDeleteEntries() {
        // Arrange
        var user = entityManager.persistAndFlush(new User("Carlos"));
        var category = entityManager.persistAndFlush(new Category("RPG", "Rol"));
        var game = entityManager.persistAndFlush(
            new Game("Elden Ring", "PC", "RPG", 2022, category));

        var tierlist = new Tierlist(user, 2024);
        var entry = new TierlistEntry(tierlist, game, 10, 2024);
        tierlist.addEntry(entry);
        entityManager.persistAndFlush(tierlist);

        Long tierlistId = tierlist.getId();

        // Act
        tierlistRepository.deleteById(tierlistId);
        entityManager.flush();

        // Assert
        assertThat(tierlistRepository.findById(tierlistId)).isEmpty();
        // La entry también debe haberse eliminado (cascade)
    }
}
```

---

## TIER-02: POST /api/users/{userId}/tierlists - Crear tierlist

### CreateTierlistRequest.java

```java
package com.gametierlist.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record CreateTierlistRequest(
    @NotNull(message = "El año es obligatorio")
    @Min(value = 2000, message = "El año debe ser mayor o igual a 2000")
    @Max(value = 2030, message = "El año debe ser menor o igual a 2030")
    Integer anio
) {}
```

### TierlistSummary.java

```java
package com.gametierlist.dto.response;

import java.time.LocalDateTime;

public record TierlistSummary(
    Long id,
    Integer anio,
    Integer totalJuegos,
    LocalDateTime fechaCreacion
) {}
```

### TierlistMapper.java

```java
package com.gametierlist.mapper;

import com.gametierlist.dto.response.TierlistDetail;
import com.gametierlist.dto.response.TierlistEntryResponse;
import com.gametierlist.dto.response.TierlistSummary;
import com.gametierlist.entity.Tierlist;
import com.gametierlist.entity.TierlistEntry;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class TierlistMapper {

    public TierlistSummary toSummary(Tierlist tierlist) {
        return new TierlistSummary(
            tierlist.getId(),
            tierlist.getAnio(),
            tierlist.getTotalJuegos(),
            tierlist.getCreatedAt()
        );
    }

    public TierlistDetail toDetail(Tierlist tierlist) {
        List<TierlistEntryResponse> entries = tierlist.getEntries().stream()
            .map(this::toEntryResponse)
            .toList();

        return new TierlistDetail(
            tierlist.getId(),
            tierlist.getAnio(),
            tierlist.getUser().getId(),
            tierlist.getUser().getNombre(),
            entries,
            tierlist.getCreatedAt()
        );
    }

    public TierlistEntryResponse toEntryResponse(TierlistEntry entry) {
        return new TierlistEntryResponse(
            entry.getId(),
            entry.getGame().getId(),
            entry.getGameNombre(),
            entry.getGamePlataforma(),
            entry.getGameCategoria(),
            entry.getRating(),
            entry.getAnioJugado(),
            calculateTier(entry.getRating())
        );
    }

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
}
```

### TierlistService.java (crear tierlist)

```java
package com.gametierlist.service;

import com.gametierlist.dto.request.CreateTierlistRequest;
import com.gametierlist.dto.response.TierlistSummary;
import com.gametierlist.entity.Tierlist;
import com.gametierlist.exception.DuplicateEntityException;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.mapper.TierlistMapper;
import com.gametierlist.repository.TierlistRepository;
import com.gametierlist.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TierlistService {

    private final TierlistRepository tierlistRepository;
    private final UserRepository userRepository;
    private final TierlistMapper tierlistMapper;

    @Transactional
    public TierlistSummary create(Long userId, CreateTierlistRequest request) {
        var user = userRepository.findById(userId)
            .orElseThrow(() -> new EntityNotFoundException("Usuario", userId));

        if (tierlistRepository.existsByUserIdAndAnio(userId, request.anio())) {
            throw new DuplicateEntityException(
                "Ya existe una tierlist para el año " + request.anio());
        }

        var tierlist = new Tierlist(user, request.anio());
        var saved = tierlistRepository.save(tierlist);
        return tierlistMapper.toSummary(saved);
    }
}
```

### TierlistController.java (crear)

```java
package com.gametierlist.controller;

import com.gametierlist.dto.request.CreateTierlistRequest;
import com.gametierlist.dto.response.TierlistSummary;
import com.gametierlist.service.TierlistService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users/{userId}/tierlists")
@RequiredArgsConstructor
@Tag(name = "Tierlists", description = "Gestión de tierlists personales")
public class TierlistController {

    private final TierlistService tierlistService;

    @PostMapping
    @Operation(summary = "Crear tierlist para un año")
    public ResponseEntity<TierlistSummary> create(
            @PathVariable Long userId,
            @Valid @RequestBody CreateTierlistRequest request) {
        var created = tierlistService.create(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
}
```

---

## TIER-03: GET /api/users/{userId}/tierlists - Listar tierlists

### TierlistService.java (añadir findByUserId)

```java
public List<TierlistSummary> findByUserId(Long userId) {
    if (!userRepository.existsById(userId)) {
        throw new EntityNotFoundException("Usuario", userId);
    }

    return tierlistRepository.findByUserIdOrderByAnioDesc(userId).stream()
        .map(tierlistMapper::toSummary)
        .toList();
}
```

### TierlistController.java (añadir getAll)

```java
@GetMapping
@Operation(summary = "Listar tierlists del usuario")
public ResponseEntity<List<TierlistSummary>> getAll(@PathVariable Long userId) {
    return ResponseEntity.ok(tierlistService.findByUserId(userId));
}
```

---

## TIER-04: GET /api/users/{userId}/tierlists/{anio} - Detalle con entries

### TierlistDetail.java

```java
package com.gametierlist.dto.response;

import java.time.LocalDateTime;
import java.util.List;

public record TierlistDetail(
    Long id,
    Integer anio,
    Long userId,
    String userName,
    List<TierlistEntryResponse> entries,
    LocalDateTime fechaCreacion
) {}
```

### TierlistEntryResponse.java

```java
package com.gametierlist.dto.response;

public record TierlistEntryResponse(
    Long id,
    Long gameId,
    String gameNombre,
    String gamePlataforma,
    String gameCategoria,
    Integer rating,
    Integer anioJugado,
    String tier
) {}
```

### TierlistService.java (añadir findByUserIdAndAnio)

```java
public TierlistDetail findByUserIdAndAnio(Long userId, Integer anio) {
    if (!userRepository.existsById(userId)) {
        throw new EntityNotFoundException("Usuario", userId);
    }

    var tierlist = tierlistRepository.findWithEntriesByUserIdAndAnio(userId, anio)
        .orElseThrow(() -> new EntityNotFoundException(
            "Tierlist del año " + anio + " no encontrada"));

    return tierlistMapper.toDetail(tierlist);
}
```

### TierlistController.java (añadir getByAnio)

```java
@GetMapping("/{anio}")
@Operation(summary = "Obtener tierlist con sus juegos")
public ResponseEntity<TierlistDetail> getByAnio(
        @PathVariable Long userId,
        @PathVariable Integer anio) {
    return ResponseEntity.ok(tierlistService.findByUserIdAndAnio(userId, anio));
}
```

---

## TIER-05: POST entries - Añadir juego a tierlist

### CreateEntryRequest.java

```java
package com.gametierlist.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record CreateEntryRequest(
    @NotNull(message = "El ID del juego es obligatorio")
    Long gameId,

    @NotNull(message = "El rating es obligatorio")
    @Min(value = 1, message = "El rating mínimo es 1")
    @Max(value = 10, message = "El rating máximo es 10")
    Integer rating,

    @NotNull(message = "El año jugado es obligatorio")
    @Min(value = 1970, message = "El año debe ser mayor o igual a 1970")
    Integer anioJugado
) {}
```

### TierlistService.java (añadir addEntry)

```java
private final GameRepository gameRepository;
private final TierlistEntryRepository entryRepository;

@Transactional
public TierlistEntryResponse addEntry(Long userId, Integer anio, CreateEntryRequest request) {
    var user = userRepository.findById(userId)
        .orElseThrow(() -> new EntityNotFoundException("Usuario", userId));

    var game = gameRepository.findById(request.gameId())
        .orElseThrow(() -> new EntityNotFoundException("Juego", request.gameId()));

    // Buscar o crear la tierlist
    var tierlist = tierlistRepository.findByUserIdAndAnio(userId, anio)
        .orElseGet(() -> {
            var newTierlist = new Tierlist(user, anio);
            return tierlistRepository.save(newTierlist);
        });

    // Verificar que el juego no esté ya en la tierlist
    if (entryRepository.existsByTierlistIdAndGameId(tierlist.getId(), game.getId())) {
        throw new DuplicateEntityException(
            "El juego '" + game.getNombre() + "' ya está en esta tierlist");
    }

    // Crear entry con datos denormalizados
    var entry = new TierlistEntry(tierlist, game, request.rating(), request.anioJugado());
    tierlist.addEntry(entry);

    var saved = entryRepository.save(entry);
    return tierlistMapper.toEntryResponse(saved);
}
```

### TierlistController.java (añadir createEntry)

```java
@PostMapping("/{anio}/entries")
@Operation(summary = "Añadir juego a la tierlist")
public ResponseEntity<TierlistEntryResponse> addEntry(
        @PathVariable Long userId,
        @PathVariable Integer anio,
        @Valid @RequestBody CreateEntryRequest request) {
    var entry = tierlistService.addEntry(userId, anio, request);
    return ResponseEntity.status(HttpStatus.CREATED).body(entry);
}
```

---

## TIER-06: PUT/DELETE entries

### UpdateEntryRequest.java

```java
package com.gametierlist.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record UpdateEntryRequest(
    @NotNull(message = "El rating es obligatorio")
    @Min(value = 1, message = "El rating mínimo es 1")
    @Max(value = 10, message = "El rating máximo es 10")
    Integer rating,

    @NotNull(message = "El año jugado es obligatorio")
    @Min(value = 1970, message = "El año debe ser mayor o igual a 1970")
    Integer anioJugado
) {}
```

### TierlistService.java (añadir update y delete)

```java
@Transactional
public TierlistEntryResponse updateEntry(Long userId, Integer anio, Long entryId, 
                                          UpdateEntryRequest request) {
    var entry = findEntryOrThrow(userId, anio, entryId);

    entry.setRating(request.rating());
    entry.setAnioJugado(request.anioJugado());

    var saved = entryRepository.save(entry);
    return tierlistMapper.toEntryResponse(saved);
}

@Transactional
public void deleteEntry(Long userId, Integer anio, Long entryId) {
    var entry = findEntryOrThrow(userId, anio, entryId);
    entryRepository.delete(entry);
}

private TierlistEntry findEntryOrThrow(Long userId, Integer anio, Long entryId) {
    // Verificar que existe el usuario
    if (!userRepository.existsById(userId)) {
        throw new EntityNotFoundException("Usuario", userId);
    }

    // Buscar la entry
    var entry = entryRepository.findById(entryId)
        .orElseThrow(() -> new EntityNotFoundException("Entry", entryId));

    // Verificar que pertenece a la tierlist correcta
    var tierlist = entry.getTierlist();
    if (!tierlist.getUser().getId().equals(userId) || !tierlist.getAnio().equals(anio)) {
        throw new EntityNotFoundException("Entry", entryId);
    }

    return entry;
}
```

### TierlistController.java (añadir update y delete)

```java
@PutMapping("/{anio}/entries/{entryId}")
@Operation(summary = "Actualizar entry")
public ResponseEntity<TierlistEntryResponse> updateEntry(
        @PathVariable Long userId,
        @PathVariable Integer anio,
        @PathVariable Long entryId,
        @Valid @RequestBody UpdateEntryRequest request) {
    return ResponseEntity.ok(tierlistService.updateEntry(userId, anio, entryId, request));
}

@DeleteMapping("/{anio}/entries/{entryId}")
@Operation(summary = "Eliminar entry")
public ResponseEntity<Void> deleteEntry(
        @PathVariable Long userId,
        @PathVariable Integer anio,
        @PathVariable Long entryId) {
    tierlistService.deleteEntry(userId, anio, entryId);
    return ResponseEntity.noContent().build();
}
```

---

## TIER-07: Verificar juego en uso antes de eliminar

### EntityInUseException.java

```java
package com.gametierlist.exception;

public class EntityInUseException extends RuntimeException {

    public EntityInUseException(String message) {
        super(message);
    }
}
```

### GlobalExceptionHandler.java (añadir handler)

```java
@ExceptionHandler(EntityInUseException.class)
public ResponseEntity<ErrorResponse> handleEntityInUse(
        EntityInUseException ex,
        HttpServletRequest request) {
    
    var error = new ErrorResponse(
        "ENTITY_IN_USE",
        ex.getMessage(),
        request.getRequestURI()
    );
    return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
}
```

### GameService.java (modificar delete)

```java
private final TierlistEntryRepository entryRepository;

@Transactional
public void delete(Long id) {
    if (!gameRepository.existsById(id)) {
        throw new EntityNotFoundException("Juego", id);
    }

    // Verificar que no está en uso
    if (entryRepository.existsByGameId(id)) {
        throw new EntityInUseException(
            "No se puede eliminar el juego porque está en uso en una o más tierlists");
    }

    gameRepository.deleteById(id);
}
```

---

## 📂 Estructura final del Sprint 4

```
src/main/java/com/gametierlist/
├── controller/
│   ├── CategoryController.java
│   ├── GameController.java
│   ├── TierlistController.java      // NUEVO
│   └── UserController.java
├── dto/
│   ├── request/
│   │   ├── CreateEntryRequest.java  // NUEVO
│   │   ├── CreateGameRequest.java
│   │   ├── CreateTierlistRequest.java // NUEVO
│   │   ├── CreateUserRequest.java
│   │   ├── UpdateEntryRequest.java  // NUEVO
│   │   ├── UpdateGameRequest.java
│   │   └── UpdateUserRequest.java
│   └── response/
│       ├── CategoryResponse.java
│       ├── ErrorResponse.java
│       ├── GameResponse.java
│       ├── TierlistDetail.java      // NUEVO
│       ├── TierlistEntryResponse.java // NUEVO
│       ├── TierlistSummary.java     // NUEVO
│       └── UserResponse.java
├── entity/
│   ├── BaseEntity.java
│   ├── Category.java
│   ├── Game.java
│   ├── Tierlist.java                // NUEVO
│   ├── TierlistEntry.java           // NUEVO
│   └── User.java
├── exception/
│   ├── DuplicateEntityException.java
│   ├── EntityInUseException.java    // NUEVO
│   ├── EntityNotFoundException.java
│   ├── GlobalExceptionHandler.java  // MODIFICADO
│   └── RelatedEntityNotFoundException.java
├── mapper/
│   ├── CategoryMapper.java
│   ├── GameMapper.java
│   ├── TierlistMapper.java          // NUEVO
│   └── UserMapper.java
├── repository/
│   ├── CategoryRepository.java
│   ├── GameRepository.java
│   ├── TierlistEntryRepository.java // NUEVO
│   ├── TierlistRepository.java      // NUEVO
│   └── UserRepository.java
├── service/
│   ├── CategoryService.java
│   ├── GameService.java             // MODIFICADO
│   ├── TierlistService.java         // NUEVO
│   └── UserService.java
└── specification/
    └── GameSpecification.java
```

---

## 📋 TierlistService.java (versión completa)

```java
package com.gametierlist.service;

import com.gametierlist.dto.request.CreateEntryRequest;
import com.gametierlist.dto.request.CreateTierlistRequest;
import com.gametierlist.dto.request.UpdateEntryRequest;
import com.gametierlist.dto.response.TierlistDetail;
import com.gametierlist.dto.response.TierlistEntryResponse;
import com.gametierlist.dto.response.TierlistSummary;
import com.gametierlist.entity.Tierlist;
import com.gametierlist.entity.TierlistEntry;
import com.gametierlist.exception.DuplicateEntityException;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.mapper.TierlistMapper;
import com.gametierlist.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TierlistService {

    private final TierlistRepository tierlistRepository;
    private final TierlistEntryRepository entryRepository;
    private final UserRepository userRepository;
    private final GameRepository gameRepository;
    private final TierlistMapper tierlistMapper;

    @Transactional
    public TierlistSummary create(Long userId, CreateTierlistRequest request) {
        var user = userRepository.findById(userId)
            .orElseThrow(() -> new EntityNotFoundException("Usuario", userId));

        if (tierlistRepository.existsByUserIdAndAnio(userId, request.anio())) {
            throw new DuplicateEntityException(
                "Ya existe una tierlist para el año " + request.anio());
        }

        var tierlist = new Tierlist(user, request.anio());
        var saved = tierlistRepository.save(tierlist);
        return tierlistMapper.toSummary(saved);
    }

    public List<TierlistSummary> findByUserId(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new EntityNotFoundException("Usuario", userId);
        }

        return tierlistRepository.findByUserIdOrderByAnioDesc(userId).stream()
            .map(tierlistMapper::toSummary)
            .toList();
    }

    public TierlistDetail findByUserIdAndAnio(Long userId, Integer anio) {
        if (!userRepository.existsById(userId)) {
            throw new EntityNotFoundException("Usuario", userId);
        }

        var tierlist = tierlistRepository.findWithEntriesByUserIdAndAnio(userId, anio)
            .orElseThrow(() -> new EntityNotFoundException(
                "Tierlist del año " + anio + " no encontrada"));

        return tierlistMapper.toDetail(tierlist);
    }

    @Transactional
    public TierlistEntryResponse addEntry(Long userId, Integer anio, CreateEntryRequest request) {
        var user = userRepository.findById(userId)
            .orElseThrow(() -> new EntityNotFoundException("Usuario", userId));

        var game = gameRepository.findById(request.gameId())
            .orElseThrow(() -> new EntityNotFoundException("Juego", request.gameId()));

        var tierlist = tierlistRepository.findByUserIdAndAnio(userId, anio)
            .orElseGet(() -> {
                var newTierlist = new Tierlist(user, anio);
                return tierlistRepository.save(newTierlist);
            });

        if (entryRepository.existsByTierlistIdAndGameId(tierlist.getId(), game.getId())) {
            throw new DuplicateEntityException(
                "El juego '" + game.getNombre() + "' ya está en esta tierlist");
        }

        var entry = new TierlistEntry(tierlist, game, request.rating(), request.anioJugado());
        tierlist.addEntry(entry);

        var saved = entryRepository.save(entry);
        return tierlistMapper.toEntryResponse(saved);
    }

    @Transactional
    public TierlistEntryResponse updateEntry(Long userId, Integer anio, Long entryId,
                                              UpdateEntryRequest request) {
        var entry = findEntryOrThrow(userId, anio, entryId);

        entry.setRating(request.rating());
        entry.setAnioJugado(request.anioJugado());

        var saved = entryRepository.save(entry);
        return tierlistMapper.toEntryResponse(saved);
    }

    @Transactional
    public void deleteEntry(Long userId, Integer anio, Long entryId) {
        var entry = findEntryOrThrow(userId, anio, entryId);
        entryRepository.delete(entry);
    }

    private TierlistEntry findEntryOrThrow(Long userId, Integer anio, Long entryId) {
        if (!userRepository.existsById(userId)) {
            throw new EntityNotFoundException("Usuario", userId);
        }

        var entry = entryRepository.findById(entryId)
            .orElseThrow(() -> new EntityNotFoundException("Entry", entryId));

        var tierlist = entry.getTierlist();
        if (!tierlist.getUser().getId().equals(userId) || !tierlist.getAnio().equals(anio)) {
            throw new EntityNotFoundException("Entry", entryId);
        }

        return entry;
    }
}
```

---

## 📋 TierlistController.java (versión completa)

```java
package com.gametierlist.controller;

import com.gametierlist.dto.request.CreateEntryRequest;
import com.gametierlist.dto.request.CreateTierlistRequest;
import com.gametierlist.dto.request.UpdateEntryRequest;
import com.gametierlist.dto.response.TierlistDetail;
import com.gametierlist.dto.response.TierlistEntryResponse;
import com.gametierlist.dto.response.TierlistSummary;
import com.gametierlist.service.TierlistService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users/{userId}/tierlists")
@RequiredArgsConstructor
@Tag(name = "Tierlists", description = "Gestión de tierlists personales")
public class TierlistController {

    private final TierlistService tierlistService;

    @PostMapping
    @Operation(summary = "Crear tierlist para un año")
    public ResponseEntity<TierlistSummary> create(
            @PathVariable Long userId,
            @Valid @RequestBody CreateTierlistRequest request) {
        var created = tierlistService.create(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping
    @Operation(summary = "Listar tierlists del usuario")
    public ResponseEntity<List<TierlistSummary>> getAll(@PathVariable Long userId) {
        return ResponseEntity.ok(tierlistService.findByUserId(userId));
    }

    @GetMapping("/{anio}")
    @Operation(summary = "Obtener tierlist con sus juegos")
    public ResponseEntity<TierlistDetail> getByAnio(
            @PathVariable Long userId,
            @PathVariable Integer anio) {
        return ResponseEntity.ok(tierlistService.findByUserIdAndAnio(userId, anio));
    }

    @PostMapping("/{anio}/entries")
    @Operation(summary = "Añadir juego a la tierlist")
    public ResponseEntity<TierlistEntryResponse> addEntry(
            @PathVariable Long userId,
            @PathVariable Integer anio,
            @Valid @RequestBody CreateEntryRequest request) {
        var entry = tierlistService.addEntry(userId, anio, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(entry);
    }

    @PutMapping("/{anio}/entries/{entryId}")
    @Operation(summary = "Actualizar entry")
    public ResponseEntity<TierlistEntryResponse> updateEntry(
            @PathVariable Long userId,
            @PathVariable Integer anio,
            @PathVariable Long entryId,
            @Valid @RequestBody UpdateEntryRequest request) {
        return ResponseEntity.ok(tierlistService.updateEntry(userId, anio, entryId, request));
    }

    @DeleteMapping("/{anio}/entries/{entryId}")
    @Operation(summary = "Eliminar entry")
    public ResponseEntity<Void> deleteEntry(
            @PathVariable Long userId,
            @PathVariable Integer anio,
            @PathVariable Long entryId) {
        tierlistService.deleteEntry(userId, anio, entryId);
        return ResponseEntity.noContent().build();
    }
}
```
