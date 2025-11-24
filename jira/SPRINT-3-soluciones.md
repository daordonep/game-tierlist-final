# 📖 Sprint 3: Soluciones de Referencia

> ⚠️ **Usa este documento solo si te atascas.** Intenta implementar primero por tu cuenta siguiendo las especificaciones del ticket.

---

## GAME-01: Crear entidad Game

### Game.java

```java
package com.gametierlist.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "game",
    uniqueConstraints = @UniqueConstraint(
        name = "uk_game_nombre_plataforma",
        columnNames = {"nombre", "plataforma"}
    )
)
@Getter
@Setter
@NoArgsConstructor
public class Game extends BaseEntity {

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(nullable = false, length = 50)
    private String plataforma;

    @Column(length = 500)
    private String descripcion;

    @Column(name = "anio_lanzamiento", nullable = false)
    private Integer anioLanzamiento;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    public Game(String nombre, String plataforma, String descripcion, 
                Integer anioLanzamiento, Category category) {
        this.nombre = nombre;
        this.plataforma = plataforma;
        this.descripcion = descripcion;
        this.anioLanzamiento = anioLanzamiento;
        this.category = category;
    }
}
```

### GameRepository.java

```java
package com.gametierlist.repository;

import com.gametierlist.entity.Game;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface GameRepository extends JpaRepository<Game, Long>, 
                                        JpaSpecificationExecutor<Game> {

    boolean existsByNombreAndPlataforma(String nombre, String plataforma);

    boolean existsByNombreAndPlataformaAndIdNot(String nombre, String plataforma, Long id);
}
```

### data.sql (añadir juegos)

```sql
-- Juegos de ejemplo (añadir después de las categorías)
-- Asumiendo IDs de categorías: 1=Acción, 2=Aventura, 9=RPG, 10=Shooter, etc.

INSERT INTO game (nombre, plataforma, descripcion, anio_lanzamiento, category_id, created_at, updated_at) VALUES
('The Legend of Zelda: Tears of the Kingdom', 'Nintendo Switch', 'Secuela de Breath of the Wild con nuevas mecánicas de construcción', 2023, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Elden Ring', 'PC', 'RPG de acción en mundo abierto creado por FromSoftware', 2022, 9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Elden Ring', 'PlayStation 5', 'RPG de acción en mundo abierto creado por FromSoftware', 2022, 9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('God of War Ragnarök', 'PlayStation 5', 'Continuación de la saga nórdica de Kratos', 2022, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Baldur''s Gate 3', 'PC', 'RPG basado en D&D con combate por turnos', 2023, 9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Hades', 'PC', 'Roguelike de acción con narrativa mitológica griega', 2020, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Hollow Knight', 'PC', 'Metroidvania con estética oscura y desafiante', 2017, 6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Celeste', 'Nintendo Switch', 'Plataformas de precisión con historia emotiva', 2018, 7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Portal 2', 'PC', 'Puzzle en primera persona con portales', 2011, 8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FIFA 24', 'PlayStation 5', 'Simulador de fútbol anual', 2023, 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Resident Evil 4 Remake', 'PC', 'Remake del clásico survival horror', 2023, 12, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Stardew Valley', 'PC', 'Simulador de granja con elementos de RPG', 2016, 11, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
```

### GameRepositoryTest.java

```java
package com.gametierlist.repository;

import com.gametierlist.entity.Category;
import com.gametierlist.entity.Game;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class GameRepositoryTest {

    @Autowired
    private GameRepository gameRepository;

    @Autowired
    private TestEntityManager entityManager;

    private Category category;

    @BeforeEach
    void setUp() {
        category = entityManager.persistAndFlush(new Category("RPG", "Juegos de rol"));
    }

    @Test
    @DisplayName("Debe encontrar juego por ID")
    void shouldFindGameById() {
        // Arrange
        var game = new Game("Elden Ring", "PC", "Un gran RPG", 2022, category);
        entityManager.persistAndFlush(game);

        // Act
        var result = gameRepository.findById(game.getId());

        // Assert
        assertThat(result).isPresent();
        assertThat(result.get().getNombre()).isEqualTo("Elden Ring");
    }

    @Test
    @DisplayName("Debe verificar existencia por nombre y plataforma")
    void shouldCheckExistsByNombreAndPlataforma() {
        // Arrange
        var game = new Game("Elden Ring", "PC", "Un gran RPG", 2022, category);
        entityManager.persistAndFlush(game);

        // Act & Assert
        assertThat(gameRepository.existsByNombreAndPlataforma("Elden Ring", "PC")).isTrue();
        assertThat(gameRepository.existsByNombreAndPlataforma("Elden Ring", "PS5")).isFalse();
        assertThat(gameRepository.existsByNombreAndPlataforma("Otro Juego", "PC")).isFalse();
    }

    @Test
    @DisplayName("Debe verificar existencia excluyendo un ID")
    void shouldCheckExistsByNombreAndPlataformaExcludingId() {
        // Arrange
        var game1 = entityManager.persistAndFlush(
            new Game("Elden Ring", "PC", "RPG", 2022, category));
        var game2 = entityManager.persistAndFlush(
            new Game("Dark Souls", "PC", "RPG", 2011, category));

        // Act & Assert
        // "Dark Souls" + "PC" existe y NO es game1
        assertThat(gameRepository.existsByNombreAndPlataformaAndIdNot(
            "Dark Souls", "PC", game1.getId())).isTrue();
        
        // "Elden Ring" + "PC" existe pero ES game1
        assertThat(gameRepository.existsByNombreAndPlataformaAndIdNot(
            "Elden Ring", "PC", game1.getId())).isFalse();
    }
}
```

---

## GAME-02: GET /api/games - Listar juegos con paginación

### GameResponse.java

```java
package com.gametierlist.dto.response;

import java.time.LocalDateTime;

public record GameResponse(
    Long id,
    String nombre,
    String plataforma,
    String descripcion,
    Integer anioLanzamiento,
    Long categoriaId,
    String categoriaNombre,
    LocalDateTime fechaCreacion
) {}
```

### GameMapper.java

```java
package com.gametierlist.mapper;

import com.gametierlist.dto.request.CreateGameRequest;
import com.gametierlist.dto.response.GameResponse;
import com.gametierlist.entity.Category;
import com.gametierlist.entity.Game;
import org.springframework.stereotype.Component;

@Component
public class GameMapper {

    public GameResponse toResponse(Game game) {
        return new GameResponse(
            game.getId(),
            game.getNombre(),
            game.getPlataforma(),
            game.getDescripcion(),
            game.getAnioLanzamiento(),
            game.getCategory().getId(),
            game.getCategory().getNombre(),
            game.getCreatedAt()
        );
    }

    public Game toEntity(CreateGameRequest request, Category category) {
        return new Game(
            request.nombre().trim(),
            request.plataforma().trim(),
            request.descripcion(),
            request.anioLanzamiento(),
            category
        );
    }
}
```

### GameService.java (versión inicial)

```java
package com.gametierlist.service;

import com.gametierlist.dto.response.GameResponse;
import com.gametierlist.mapper.GameMapper;
import com.gametierlist.repository.GameRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GameService {

    private final GameRepository gameRepository;
    private final GameMapper gameMapper;

    public Page<GameResponse> findAll(Pageable pageable) {
        return gameRepository.findAll(pageable)
            .map(gameMapper::toResponse);
    }
}
```

### GameController.java (versión inicial)

```java
package com.gametierlist.controller;

import com.gametierlist.dto.response.GameResponse;
import com.gametierlist.service.GameService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/games")
@RequiredArgsConstructor
@Tag(name = "Games", description = "Catálogo de juegos")
public class GameController {

    private final GameService gameService;

    @GetMapping
    @Operation(summary = "Listar todos los juegos con paginación")
    public ResponseEntity<Page<GameResponse>> getAll(
            @PageableDefault(size = 20, sort = "nombre") Pageable pageable) {
        return ResponseEntity.ok(gameService.findAll(pageable));
    }
}
```

### GameServiceTest.java (para GAME-02)

```java
package com.gametierlist.service;

import com.gametierlist.dto.response.GameResponse;
import com.gametierlist.entity.Category;
import com.gametierlist.entity.Game;
import com.gametierlist.mapper.GameMapper;
import com.gametierlist.repository.GameRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GameServiceTest {

    @Mock
    private GameRepository gameRepository;

    @Mock
    private GameMapper gameMapper;

    @InjectMocks
    private GameService gameService;

    @Test
    @DisplayName("Debe devolver página de juegos")
    void shouldReturnPageOfGames() {
        // Arrange
        var pageable = PageRequest.of(0, 10);
        var category = new Category("RPG", "Rol");
        var game = createGame(1L, "Elden Ring", category);
        var response = createGameResponse(1L, "Elden Ring", "RPG");
        var page = new PageImpl<>(List.of(game), pageable, 1);

        when(gameRepository.findAll(pageable)).thenReturn(page);
        when(gameMapper.toResponse(game)).thenReturn(response);

        // Act
        var result = gameService.findAll(pageable);

        // Assert
        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).nombre()).isEqualTo("Elden Ring");
        assertThat(result.getTotalElements()).isEqualTo(1);
    }

    @Test
    @DisplayName("Debe devolver página vacía cuando no hay juegos")
    void shouldReturnEmptyPageWhenNoGames() {
        // Arrange
        var pageable = PageRequest.of(0, 10);
        var emptyPage = new PageImpl<Game>(Collections.emptyList(), pageable, 0);

        when(gameRepository.findAll(pageable)).thenReturn(emptyPage);

        // Act
        var result = gameService.findAll(pageable);

        // Assert
        assertThat(result.getContent()).isEmpty();
        assertThat(result.getTotalElements()).isZero();
    }

    private Game createGame(Long id, String nombre, Category category) {
        var game = new Game(nombre, "PC", "Descripción", 2022, category);
        game.setId(id);
        game.setCreatedAt(LocalDateTime.now());
        return game;
    }

    private GameResponse createGameResponse(Long id, String nombre, String categoria) {
        return new GameResponse(id, nombre, "PC", "Descripción", 2022, 
            1L, categoria, LocalDateTime.now());
    }
}
```

---

## GAME-03: POST /api/games - Crear juego

### CreateGameRequest.java

```java
package com.gametierlist.dto.request;

import jakarta.validation.constraints.*;

public record CreateGameRequest(
    @NotBlank(message = "El nombre es obligatorio")
    @Size(max = 100, message = "El nombre no puede superar 100 caracteres")
    String nombre,

    @NotBlank(message = "La plataforma es obligatoria")
    @Size(max = 50, message = "La plataforma no puede superar 50 caracteres")
    String plataforma,

    @Size(max = 500, message = "La descripción no puede superar 500 caracteres")
    String descripcion,

    @NotNull(message = "El año de lanzamiento es obligatorio")
    @Min(value = 1970, message = "El año debe ser mayor o igual a 1970")
    @Max(value = 2030, message = "El año debe ser menor o igual a 2030")
    Integer anioLanzamiento,

    @NotNull(message = "La categoría es obligatoria")
    Long categoriaId
) {}
```

### RelatedEntityNotFoundException.java

```java
package com.gametierlist.exception;

public class RelatedEntityNotFoundException extends RuntimeException {

    public RelatedEntityNotFoundException(String message) {
        super(message);
    }

    public RelatedEntityNotFoundException(String entity, Long id) {
        super(entity + " con id " + id + " no encontrada");
    }
}
```

### GlobalExceptionHandler.java (añadir handler)

```java
@ExceptionHandler(RelatedEntityNotFoundException.class)
public ResponseEntity<ErrorResponse> handleRelatedNotFound(
        RelatedEntityNotFoundException ex,
        HttpServletRequest request) {
    
    var error = new ErrorResponse(
        "RELATED_NOT_FOUND",
        ex.getMessage(),
        request.getRequestURI()
    );
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
}
```

### GameService.java (añadir create)

```java
private final CategoryRepository categoryRepository;

@Transactional
public GameResponse create(CreateGameRequest request) {
    // Verificar que la categoría existe
    var category = categoryRepository.findById(request.categoriaId())
        .orElseThrow(() -> new RelatedEntityNotFoundException(
            "Categoría", request.categoriaId()));

    String nombre = request.nombre().trim();
    String plataforma = request.plataforma().trim();

    // Verificar unicidad
    if (gameRepository.existsByNombreAndPlataforma(nombre, plataforma)) {
        throw new DuplicateEntityException(
            "Ya existe el juego '" + nombre + "' para " + plataforma);
    }

    var game = gameMapper.toEntity(request, category);
    var saved = gameRepository.save(game);
    return gameMapper.toResponse(saved);
}
```

### GameController.java (añadir create)

```java
@PostMapping
@Operation(summary = "Crear nuevo juego")
public ResponseEntity<GameResponse> create(
        @Valid @RequestBody CreateGameRequest request) {
    var created = gameService.create(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}
```

### Tests para GAME-03

```java
// GameServiceTest.java
@Mock
private CategoryRepository categoryRepository;

@Test
@DisplayName("Debe crear juego cuando los datos son válidos")
void shouldCreateGame_WhenValid() {
    // Arrange
    var category = new Category("RPG", "Rol");
    category.setId(1L);
    var request = new CreateGameRequest(
        "Elden Ring", "PC", "Gran RPG", 2022, 1L);
    var game = createGame(1L, "Elden Ring", category);
    var response = createGameResponse(1L, "Elden Ring", "RPG");

    when(categoryRepository.findById(1L)).thenReturn(Optional.of(category));
    when(gameRepository.existsByNombreAndPlataforma("Elden Ring", "PC")).thenReturn(false);
    when(gameMapper.toEntity(request, category)).thenReturn(game);
    when(gameRepository.save(game)).thenReturn(game);
    when(gameMapper.toResponse(game)).thenReturn(response);

    // Act
    var result = gameService.create(request);

    // Assert
    assertThat(result.nombre()).isEqualTo("Elden Ring");
    verify(gameRepository).save(any(Game.class));
}

@Test
@DisplayName("Debe lanzar excepción cuando la categoría no existe")
void shouldThrowNotFound_WhenCategoryDoesNotExist() {
    // Arrange
    var request = new CreateGameRequest(
        "Elden Ring", "PC", "Gran RPG", 2022, 999L);

    when(categoryRepository.findById(999L)).thenReturn(Optional.empty());

    // Act & Assert
    assertThatThrownBy(() -> gameService.create(request))
        .isInstanceOf(RelatedEntityNotFoundException.class)
        .hasMessageContaining("999");
}

@Test
@DisplayName("Debe lanzar excepción cuando el juego ya existe")
void shouldThrowDuplicate_WhenGameAlreadyExists() {
    // Arrange
    var category = new Category("RPG", "Rol");
    var request = new CreateGameRequest(
        "Elden Ring", "PC", "Gran RPG", 2022, 1L);

    when(categoryRepository.findById(1L)).thenReturn(Optional.of(category));
    when(gameRepository.existsByNombreAndPlataforma("Elden Ring", "PC")).thenReturn(true);

    // Act & Assert
    assertThatThrownBy(() -> gameService.create(request))
        .isInstanceOf(DuplicateEntityException.class);
}
```

---

## GAME-04: GET/PUT/DELETE /api/games/{id}

### UpdateGameRequest.java

```java
package com.gametierlist.dto.request;

import jakarta.validation.constraints.*;

public record UpdateGameRequest(
    @NotBlank(message = "El nombre es obligatorio")
    @Size(max = 100, message = "El nombre no puede superar 100 caracteres")
    String nombre,

    @NotBlank(message = "La plataforma es obligatoria")
    @Size(max = 50, message = "La plataforma no puede superar 50 caracteres")
    String plataforma,

    @Size(max = 500, message = "La descripción no puede superar 500 caracteres")
    String descripcion,

    @NotNull(message = "El año de lanzamiento es obligatorio")
    @Min(value = 1970, message = "El año debe ser mayor o igual a 1970")
    @Max(value = 2030, message = "El año debe ser menor o igual a 2030")
    Integer anioLanzamiento,

    @NotNull(message = "La categoría es obligatoria")
    Long categoriaId
) {}
```

### GameService.java (añadir findById, update, delete)

```java
public GameResponse findById(Long id) {
    return gameRepository.findById(id)
        .map(gameMapper::toResponse)
        .orElseThrow(() -> new EntityNotFoundException("Juego", id));
}

@Transactional
public GameResponse update(Long id, UpdateGameRequest request) {
    var game = gameRepository.findById(id)
        .orElseThrow(() -> new EntityNotFoundException("Juego", id));

    var category = categoryRepository.findById(request.categoriaId())
        .orElseThrow(() -> new RelatedEntityNotFoundException(
            "Categoría", request.categoriaId()));

    String nombre = request.nombre().trim();
    String plataforma = request.plataforma().trim();

    // Verificar que no exista otro juego con el mismo nombre+plataforma
    if (gameRepository.existsByNombreAndPlataformaAndIdNot(nombre, plataforma, id)) {
        throw new DuplicateEntityException(
            "Ya existe otro juego '" + nombre + "' para " + plataforma);
    }

    game.setNombre(nombre);
    game.setPlataforma(plataforma);
    game.setDescripcion(request.descripcion());
    game.setAnioLanzamiento(request.anioLanzamiento());
    game.setCategory(category);

    var saved = gameRepository.save(game);
    return gameMapper.toResponse(saved);
}

@Transactional
public void delete(Long id) {
    if (!gameRepository.existsById(id)) {
        throw new EntityNotFoundException("Juego", id);
    }
    gameRepository.deleteById(id);
}
```

### GameController.java (añadir endpoints)

```java
@GetMapping("/{id}")
@Operation(summary = "Obtener juego por ID")
public ResponseEntity<GameResponse> getById(@PathVariable Long id) {
    return ResponseEntity.ok(gameService.findById(id));
}

@PutMapping("/{id}")
@Operation(summary = "Actualizar juego")
public ResponseEntity<GameResponse> update(
        @PathVariable Long id,
        @Valid @RequestBody UpdateGameRequest request) {
    return ResponseEntity.ok(gameService.update(id, request));
}

@DeleteMapping("/{id}")
@Operation(summary = "Eliminar juego")
public ResponseEntity<Void> delete(@PathVariable Long id) {
    gameService.delete(id);
    return ResponseEntity.noContent().build();
}
```

---

## GAME-05: GET /api/games/search - Búsqueda con filtros

### GameSpecification.java

```java
package com.gametierlist.specification;

import com.gametierlist.entity.Game;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public class GameSpecification {

    private GameSpecification() {
        // Utility class
    }

    public static Specification<Game> withFilters(
            String nombre,
            String plataforma,
            Long categoriaId,
            Integer anioMin,
            Integer anioMax) {

        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filtro por nombre (parcial, case-insensitive)
            if (nombre != null && !nombre.isBlank()) {
                predicates.add(cb.like(
                    cb.lower(root.get("nombre")),
                    "%" + nombre.toLowerCase() + "%"
                ));
            }

            // Filtro por plataforma (exacto)
            if (plataforma != null && !plataforma.isBlank()) {
                predicates.add(cb.equal(root.get("plataforma"), plataforma));
            }

            // Filtro por categoría
            if (categoriaId != null) {
                predicates.add(cb.equal(root.get("category").get("id"), categoriaId));
            }

            // Filtro por año mínimo
            if (anioMin != null) {
                predicates.add(cb.greaterThanOrEqualTo(
                    root.get("anioLanzamiento"), anioMin));
            }

            // Filtro por año máximo
            if (anioMax != null) {
                predicates.add(cb.lessThanOrEqualTo(
                    root.get("anioLanzamiento"), anioMax));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
```

### GameService.java (añadir search)

```java
public Page<GameResponse> search(
        String nombre,
        String plataforma,
        Long categoriaId,
        Integer anioMin,
        Integer anioMax,
        Pageable pageable) {

    var spec = GameSpecification.withFilters(
        nombre, plataforma, categoriaId, anioMin, anioMax);

    return gameRepository.findAll(spec, pageable)
        .map(gameMapper::toResponse);
}
```

### GameController.java (añadir search)

```java
@GetMapping("/search")
@Operation(summary = "Buscar juegos con filtros")
public ResponseEntity<Page<GameResponse>> search(
        @RequestParam(required = false) String nombre,
        @RequestParam(required = false) String plataforma,
        @RequestParam(required = false) Long categoriaId,
        @RequestParam(required = false) Integer anioMin,
        @RequestParam(required = false) Integer anioMax,
        @PageableDefault(size = 20, sort = "nombre") Pageable pageable) {

    return ResponseEntity.ok(gameService.search(
        nombre, plataforma, categoriaId, anioMin, anioMax, pageable));
}
```

### GameServiceTest.java (tests para search)

```java
@Test
@DisplayName("Debe buscar por nombre parcial case-insensitive")
void shouldSearchByNombrePartial() {
    // Arrange
    var pageable = PageRequest.of(0, 10);
    var category = new Category("RPG", "Rol");
    var game = createGame(1L, "Elden Ring", category);
    var response = createGameResponse(1L, "Elden Ring", "RPG");
    var page = new PageImpl<>(List.of(game), pageable, 1);

    when(gameRepository.findAll(any(Specification.class), eq(pageable)))
        .thenReturn(page);
    when(gameMapper.toResponse(game)).thenReturn(response);

    // Act
    var result = gameService.search("elden", null, null, null, null, pageable);

    // Assert
    assertThat(result.getContent()).hasSize(1);
    assertThat(result.getContent().get(0).nombre()).isEqualTo("Elden Ring");
}

@Test
@DisplayName("Debe buscar combinando múltiples filtros")
void shouldCombineMultipleFilters() {
    // Arrange
    var pageable = PageRequest.of(0, 10);
    var category = new Category("RPG", "Rol");
    var game = createGame(1L, "Elden Ring", category);
    var response = createGameResponse(1L, "Elden Ring", "RPG");
    var page = new PageImpl<>(List.of(game), pageable, 1);

    when(gameRepository.findAll(any(Specification.class), eq(pageable)))
        .thenReturn(page);
    when(gameMapper.toResponse(game)).thenReturn(response);

    // Act
    var result = gameService.search("elden", "PC", 1L, 2020, 2023, pageable);

    // Assert
    assertThat(result.getContent()).hasSize(1);
    verify(gameRepository).findAll(any(Specification.class), eq(pageable));
}

@Test
@DisplayName("Debe devolver todos los juegos cuando no hay filtros")
void shouldReturnAllWhenNoFilters() {
    // Arrange
    var pageable = PageRequest.of(0, 10);
    var category = new Category("RPG", "Rol");
    var games = List.of(
        createGame(1L, "Elden Ring", category),
        createGame(2L, "Dark Souls", category)
    );
    var page = new PageImpl<>(games, pageable, 2);

    when(gameRepository.findAll(any(Specification.class), eq(pageable)))
        .thenReturn(page);
    when(gameMapper.toResponse(any(Game.class)))
        .thenReturn(createGameResponse(1L, "Game", "RPG"));

    // Act
    var result = gameService.search(null, null, null, null, null, pageable);

    // Assert
    assertThat(result.getContent()).hasSize(2);
}
```

### GameSearchIT.java (test de integración)

```java
package com.gametierlist.integration;

import com.gametierlist.entity.Category;
import com.gametierlist.entity.Game;
import com.gametierlist.repository.CategoryRepository;
import com.gametierlist.repository.GameRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class GameSearchIT {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private GameRepository gameRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    private Category rpgCategory;
    private Category actionCategory;

    @BeforeEach
    void setUp() {
        gameRepository.deleteAll();
        categoryRepository.deleteAll();

        rpgCategory = categoryRepository.save(new Category("RPG", "Juegos de rol"));
        actionCategory = categoryRepository.save(new Category("Acción", "Juegos de acción"));

        gameRepository.save(new Game("Elden Ring", "PC", "RPG difícil", 2022, rpgCategory));
        gameRepository.save(new Game("Elden Ring", "PS5", "RPG difícil", 2022, rpgCategory));
        gameRepository.save(new Game("God of War", "PS5", "Acción nórdica", 2022, actionCategory));
        gameRepository.save(new Game("Dark Souls", "PC", "RPG difícil", 2011, rpgCategory));
    }

    @Test
    @DisplayName("Debe encontrar juegos por nombre parcial")
    void shouldFindGamesMatchingFilters() {
        // Buscar "elden"
        var response = restTemplate.getForEntity(
            "/api/games/search?nombre=elden",
            String.class);

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(response.getBody()).contains("Elden Ring");
    }

    @Test
    @DisplayName("Debe filtrar por plataforma")
    void shouldFilterByPlataforma() {
        var response = restTemplate.getForEntity(
            "/api/games/search?plataforma=PC",
            String.class);

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(response.getBody()).contains("Elden Ring");
        assertThat(response.getBody()).contains("Dark Souls");
        assertThat(response.getBody()).doesNotContain("God of War");
    }

    @Test
    @DisplayName("Debe filtrar por rango de años")
    void shouldFilterByYearRange() {
        var response = restTemplate.getForEntity(
            "/api/games/search?anioMin=2020&anioMax=2023",
            String.class);

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(response.getBody()).contains("Elden Ring");
        assertThat(response.getBody()).contains("God of War");
        assertThat(response.getBody()).doesNotContain("Dark Souls"); // 2011
    }
}
```

---

## 📂 Estructura final del Sprint 3

```
src/main/java/com/gametierlist/
├── controller/
│   ├── CategoryController.java
│   ├── GameController.java          // NUEVO
│   └── UserController.java
├── dto/
│   ├── request/
│   │   ├── CreateGameRequest.java   // NUEVO
│   │   ├── CreateUserRequest.java
│   │   ├── UpdateGameRequest.java   // NUEVO
│   │   └── UpdateUserRequest.java
│   └── response/
│       ├── CategoryResponse.java
│       ├── ErrorResponse.java
│       ├── GameResponse.java        // NUEVO
│       └── UserResponse.java
├── entity/
│   ├── BaseEntity.java
│   ├── Category.java
│   ├── Game.java                    // NUEVO
│   └── User.java
├── exception/
│   ├── DuplicateEntityException.java
│   ├── EntityNotFoundException.java
│   ├── GlobalExceptionHandler.java  // MODIFICADO
│   └── RelatedEntityNotFoundException.java  // NUEVO
├── mapper/
│   ├── CategoryMapper.java
│   ├── GameMapper.java              // NUEVO
│   └── UserMapper.java
├── repository/
│   ├── CategoryRepository.java
│   ├── GameRepository.java          // NUEVO
│   └── UserRepository.java
├── service/
│   ├── CategoryService.java
│   ├── GameService.java             // NUEVO
│   └── UserService.java
└── specification/
    └── GameSpecification.java       // NUEVO

src/test/java/com/gametierlist/
├── controller/
│   ├── CategoryControllerTest.java
│   ├── GameControllerTest.java      // NUEVO
│   └── UserControllerTest.java
├── integration/
│   ├── GameSearchIT.java            // NUEVO
│   └── UserControllerIT.java
├── repository/
│   ├── CategoryRepositoryTest.java
│   ├── GameRepositoryTest.java      // NUEVO
│   └── UserRepositoryTest.java
└── service/
    ├── CategoryServiceTest.java
    ├── GameServiceTest.java         // NUEVO
    └── UserServiceTest.java
```

---

## 📋 GameService.java (versión completa)

```java
package com.gametierlist.service;

import com.gametierlist.dto.request.CreateGameRequest;
import com.gametierlist.dto.request.UpdateGameRequest;
import com.gametierlist.dto.response.GameResponse;
import com.gametierlist.exception.DuplicateEntityException;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.exception.RelatedEntityNotFoundException;
import com.gametierlist.mapper.GameMapper;
import com.gametierlist.repository.CategoryRepository;
import com.gametierlist.repository.GameRepository;
import com.gametierlist.specification.GameSpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GameService {

    private final GameRepository gameRepository;
    private final CategoryRepository categoryRepository;
    private final GameMapper gameMapper;

    public Page<GameResponse> findAll(Pageable pageable) {
        return gameRepository.findAll(pageable)
            .map(gameMapper::toResponse);
    }

    public GameResponse findById(Long id) {
        return gameRepository.findById(id)
            .map(gameMapper::toResponse)
            .orElseThrow(() -> new EntityNotFoundException("Juego", id));
    }

    @Transactional
    public GameResponse create(CreateGameRequest request) {
        var category = categoryRepository.findById(request.categoriaId())
            .orElseThrow(() -> new RelatedEntityNotFoundException(
                "Categoría", request.categoriaId()));

        String nombre = request.nombre().trim();
        String plataforma = request.plataforma().trim();

        if (gameRepository.existsByNombreAndPlataforma(nombre, plataforma)) {
            throw new DuplicateEntityException(
                "Ya existe el juego '" + nombre + "' para " + plataforma);
        }

        var game = gameMapper.toEntity(request, category);
        var saved = gameRepository.save(game);
        return gameMapper.toResponse(saved);
    }

    @Transactional
    public GameResponse update(Long id, UpdateGameRequest request) {
        var game = gameRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Juego", id));

        var category = categoryRepository.findById(request.categoriaId())
            .orElseThrow(() -> new RelatedEntityNotFoundException(
                "Categoría", request.categoriaId()));

        String nombre = request.nombre().trim();
        String plataforma = request.plataforma().trim();

        if (gameRepository.existsByNombreAndPlataformaAndIdNot(nombre, plataforma, id)) {
            throw new DuplicateEntityException(
                "Ya existe otro juego '" + nombre + "' para " + plataforma);
        }

        game.setNombre(nombre);
        game.setPlataforma(plataforma);
        game.setDescripcion(request.descripcion());
        game.setAnioLanzamiento(request.anioLanzamiento());
        game.setCategory(category);

        var saved = gameRepository.save(game);
        return gameMapper.toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        if (!gameRepository.existsById(id)) {
            throw new EntityNotFoundException("Juego", id);
        }
        gameRepository.deleteById(id);
    }

    public Page<GameResponse> search(
            String nombre,
            String plataforma,
            Long categoriaId,
            Integer anioMin,
            Integer anioMax,
            Pageable pageable) {

        var spec = GameSpecification.withFilters(
            nombre, plataforma, categoriaId, anioMin, anioMax);

        return gameRepository.findAll(spec, pageable)
            .map(gameMapper::toResponse);
    }
}
```

---

## 📋 GameController.java (versión completa)

```java
package com.gametierlist.controller;

import com.gametierlist.dto.request.CreateGameRequest;
import com.gametierlist.dto.request.UpdateGameRequest;
import com.gametierlist.dto.response.GameResponse;
import com.gametierlist.service.GameService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/games")
@RequiredArgsConstructor
@Tag(name = "Games", description = "Catálogo de juegos")
public class GameController {

    private final GameService gameService;

    @GetMapping
    @Operation(summary = "Listar todos los juegos con paginación")
    public ResponseEntity<Page<GameResponse>> getAll(
            @PageableDefault(size = 20, sort = "nombre") Pageable pageable) {
        return ResponseEntity.ok(gameService.findAll(pageable));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obtener juego por ID")
    public ResponseEntity<GameResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(gameService.findById(id));
    }

    @PostMapping
    @Operation(summary = "Crear nuevo juego")
    public ResponseEntity<GameResponse> create(
            @Valid @RequestBody CreateGameRequest request) {
        var created = gameService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Actualizar juego")
    public ResponseEntity<GameResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody UpdateGameRequest request) {
        return ResponseEntity.ok(gameService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Eliminar juego")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        gameService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/search")
    @Operation(summary = "Buscar juegos con filtros")
    public ResponseEntity<Page<GameResponse>> search(
            @RequestParam(required = false) String nombre,
            @RequestParam(required = false) String plataforma,
            @RequestParam(required = false) Long categoriaId,
            @RequestParam(required = false) Integer anioMin,
            @RequestParam(required = false) Integer anioMax,
            @PageableDefault(size = 20, sort = "nombre") Pageable pageable) {

        return ResponseEntity.ok(gameService.search(
            nombre, plataforma, categoriaId, anioMin, anioMax, pageable));
    }
}
```
