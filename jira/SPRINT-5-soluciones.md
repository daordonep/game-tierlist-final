# 📖 Sprint 5: Soluciones de Referencia

> ⚠️ **Usa este documento solo si te atascas.** Intenta implementar primero por tu cuenta siguiendo las especificaciones del ticket.

---

## EXPL-01: GET /api/tierlists - Listar todas las tierlists

### TierlistOverview.java

```java
package com.gametierlist.dto.response;

import java.time.LocalDateTime;

public record TierlistOverview(
    Long id,
    Long userId,
    String userName,
    Integer anio,
    Integer totalJuegos,
    LocalDateTime fechaCreacion
) {}
```

### TierlistRepository.java (añadir método)

```java
@EntityGraph(attributePaths = {"user"})
Page<Tierlist> findAllByAnio(Integer anio, Pageable pageable);

@EntityGraph(attributePaths = {"user"})
Page<Tierlist> findAllBy(Pageable pageable);
```

### ExploreService.java

```java
package com.gametierlist.service;

import com.gametierlist.dto.response.*;
import com.gametierlist.entity.Tierlist;
import com.gametierlist.entity.TierlistEntry;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.exception.InvalidParameterException;
import com.gametierlist.repository.TierlistEntryRepository;
import com.gametierlist.repository.TierlistRepository;
import com.gametierlist.repository.UserRepository;
import com.gametierlist.specification.TierlistEntrySpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ExploreService {

    private final TierlistRepository tierlistRepository;
    private final TierlistEntryRepository entryRepository;
    private final UserRepository userRepository;

    public Page<TierlistOverview> findAllTierlists(Integer anio, Pageable pageable) {
        Page<Tierlist> page;
        
        if (anio != null) {
            page = tierlistRepository.findAllByAnio(anio, pageable);
        } else {
            page = tierlistRepository.findAllBy(pageable);
        }

        return page.map(this::toOverview);
    }

    private TierlistOverview toOverview(Tierlist tierlist) {
        return new TierlistOverview(
            tierlist.getId(),
            tierlist.getUser().getId(),
            tierlist.getUser().getNombre(),
            tierlist.getAnio(),
            tierlist.getTotalJuegos(),
            tierlist.getCreatedAt()
        );
    }
}
```

### ExploreController.java

```java
package com.gametierlist.controller;

import com.gametierlist.dto.response.*;
import com.gametierlist.service.ExploreService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tierlists")
@RequiredArgsConstructor
@Tag(name = "Explore", description = "Explorar y comparar tierlists")
public class ExploreController {

    private final ExploreService exploreService;

    @GetMapping
    @Operation(summary = "Listar todas las tierlists")
    public ResponseEntity<Page<TierlistOverview>> getAll(
            @RequestParam(required = false) Integer anio,
            @PageableDefault(size = 20, sort = "anio", direction = Sort.Direction.DESC) 
            Pageable pageable) {
        return ResponseEntity.ok(exploreService.findAllTierlists(anio, pageable));
    }
}
```

---

## EXPL-02: GET /api/tierlists/entries - Buscar entries con filtros

### TierlistEntryWithUser.java

```java
package com.gametierlist.dto.response;

public record TierlistEntryWithUser(
    Long entryId,
    Long userId,
    String userName,
    Integer anio,
    String gameNombre,
    String gamePlataforma,
    String gameCategoria,
    Integer rating,
    String tier
) {}
```

### TierlistEntrySpecification.java

```java
package com.gametierlist.specification;

import com.gametierlist.entity.TierlistEntry;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public class TierlistEntrySpecification {

    private TierlistEntrySpecification() {}

    public static Specification<TierlistEntry> withFilters(
            Long userId,
            Integer anio,
            String gameNombre,
            String gameCategoria,
            String plataforma,
            Integer ratingMin,
            Integer ratingMax) {

        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filtro por usuario
            if (userId != null) {
                predicates.add(cb.equal(
                    root.get("tierlist").get("user").get("id"), userId));
            }

            // Filtro por año de tierlist
            if (anio != null) {
                predicates.add(cb.equal(
                    root.get("tierlist").get("anio"), anio));
            }

            // Filtro por nombre de juego (parcial, case-insensitive)
            // Usa el campo denormalizado
            if (gameNombre != null && !gameNombre.isBlank()) {
                predicates.add(cb.like(
                    cb.lower(root.get("gameNombre")),
                    "%" + gameNombre.toLowerCase() + "%"));
            }

            // Filtro por categoría (usa campo denormalizado)
            if (gameCategoria != null && !gameCategoria.isBlank()) {
                predicates.add(cb.equal(root.get("gameCategoria"), gameCategoria));
            }

            // Filtro por plataforma (usa campo denormalizado)
            if (plataforma != null && !plataforma.isBlank()) {
                predicates.add(cb.equal(root.get("gamePlataforma"), plataforma));
            }

            // Filtro por rating mínimo
            if (ratingMin != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("rating"), ratingMin));
            }

            // Filtro por rating máximo
            if (ratingMax != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("rating"), ratingMax));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
```

### ExploreService.java (añadir searchEntries)

```java
public Page<TierlistEntryWithUser> searchEntries(
        Long userId,
        Integer anio,
        String gameNombre,
        String gameCategoria,
        String plataforma,
        Integer ratingMin,
        Integer ratingMax,
        Pageable pageable) {

    var spec = TierlistEntrySpecification.withFilters(
        userId, anio, gameNombre, gameCategoria, plataforma, ratingMin, ratingMax);

    return entryRepository.findAll(spec, pageable)
        .map(this::toEntryWithUser);
}

private TierlistEntryWithUser toEntryWithUser(TierlistEntry entry) {
    var tierlist = entry.getTierlist();
    return new TierlistEntryWithUser(
        entry.getId(),
        tierlist.getUser().getId(),
        tierlist.getUser().getNombre(),
        tierlist.getAnio(),
        entry.getGameNombre(),
        entry.getGamePlataforma(),
        entry.getGameCategoria(),
        entry.getRating(),
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
```

### ExploreController.java (añadir searchEntries)

```java
@GetMapping("/entries")
@Operation(summary = "Buscar entries con filtros")
public ResponseEntity<Page<TierlistEntryWithUser>> searchEntries(
        @RequestParam(required = false) Long userId,
        @RequestParam(required = false) Integer anio,
        @RequestParam(required = false) String gameNombre,
        @RequestParam(required = false) String gameCategoria,
        @RequestParam(required = false) String plataforma,
        @RequestParam(required = false) Integer ratingMin,
        @RequestParam(required = false) Integer ratingMax,
        @PageableDefault(size = 20, sort = "rating", direction = Sort.Direction.DESC)
        Pageable pageable) {

    return ResponseEntity.ok(exploreService.searchEntries(
        userId, anio, gameNombre, gameCategoria, plataforma, 
        ratingMin, ratingMax, pageable));
}
```

---

## EXPL-03: GET /api/tierlists/compare - Comparar tierlists

### DTOs para comparación

```java
// TierlistComparison.java
package com.gametierlist.dto.response;

import java.util.List;
import java.util.Map;

public record TierlistComparison(
    Integer anio,
    List<ComparisonUser> users,
    List<CommonGame> commonGames,
    Map<Long, List<UniqueGame>> uniqueGames
) {}

// ComparisonUser.java
package com.gametierlist.dto.response;

public record ComparisonUser(
    Long userId,
    String userName,
    Integer totalJuegos
) {}

// CommonGame.java
package com.gametierlist.dto.response;

import java.util.Map;

public record CommonGame(
    String gameNombre,
    String gamePlataforma,
    Map<Long, Integer> ratings,
    Double averageRating,
    Integer maxDifference
) {}

// UniqueGame.java
package com.gametierlist.dto.response;

public record UniqueGame(
    String gameNombre,
    String gamePlataforma,
    Integer rating
) {}
```

### InvalidParameterException.java

```java
package com.gametierlist.exception;

public class InvalidParameterException extends RuntimeException {

    public InvalidParameterException(String message) {
        super(message);
    }
}
```

### GlobalExceptionHandler.java (añadir handler)

```java
@ExceptionHandler(InvalidParameterException.class)
public ResponseEntity<ErrorResponse> handleInvalidParameter(
        InvalidParameterException ex,
        HttpServletRequest request) {
    
    var error = new ErrorResponse(
        "INVALID_PARAMETER",
        ex.getMessage(),
        request.getRequestURI()
    );
    return ResponseEntity.badRequest().body(error);
}
```

### ExploreService.java (añadir compare)

```java
public TierlistComparison compare(List<Long> userIds, Integer anio) {
    // Validar mínimo 2 usuarios
    if (userIds == null || userIds.size() < 2) {
        throw new InvalidParameterException("Se requieren al menos 2 usuarios para comparar");
    }

    // Verificar que todos los usuarios existen
    for (Long userId : userIds) {
        if (!userRepository.existsById(userId)) {
            throw new EntityNotFoundException("Usuario", userId);
        }
    }

    // Cargar tierlists de los usuarios para ese año
    List<Tierlist> tierlists = userIds.stream()
        .map(userId -> tierlistRepository.findWithEntriesByUserIdAndAnio(userId, anio))
        .filter(Optional::isPresent)
        .map(Optional::get)
        .toList();

    // Crear lista de usuarios comparados
    List<ComparisonUser> comparisonUsers = tierlists.stream()
        .map(t -> new ComparisonUser(
            t.getUser().getId(),
            t.getUser().getNombre(),
            t.getTotalJuegos()))
        .toList();

    // Agrupar entries por juego (nombre + plataforma como clave)
    Map<String, Map<Long, TierlistEntry>> entriesByGame = new HashMap<>();
    
    for (Tierlist tierlist : tierlists) {
        Long userId = tierlist.getUser().getId();
        for (TierlistEntry entry : tierlist.getEntries()) {
            String gameKey = entry.getGameNombre() + "|" + entry.getGamePlataforma();
            entriesByGame
                .computeIfAbsent(gameKey, k -> new HashMap<>())
                .put(userId, entry);
        }
    }

    // Encontrar juegos comunes (todos los usuarios los tienen)
    List<CommonGame> commonGames = entriesByGame.entrySet().stream()
        .filter(e -> e.getValue().size() == userIds.size())
        .map(e -> {
            String[] parts = e.getKey().split("\\|");
            Map<Long, Integer> ratings = new HashMap<>();
            for (var userEntry : e.getValue().entrySet()) {
                ratings.put(userEntry.getKey(), userEntry.getValue().getRating());
            }
            
            double avg = ratings.values().stream()
                .mapToInt(Integer::intValue)
                .average()
                .orElse(0.0);
            
            int max = Collections.max(ratings.values());
            int min = Collections.min(ratings.values());
            
            return new CommonGame(parts[0], parts[1], ratings, avg, max - min);
        })
        .sorted((a, b) -> Double.compare(b.averageRating(), a.averageRating()))
        .toList();

    // Encontrar juegos únicos (solo un usuario lo tiene)
    Map<Long, List<UniqueGame>> uniqueGames = new HashMap<>();
    
    entriesByGame.entrySet().stream()
        .filter(e -> e.getValue().size() == 1)
        .forEach(e -> {
            String[] parts = e.getKey().split("\\|");
            var userEntry = e.getValue().entrySet().iterator().next();
            Long userId = userEntry.getKey();
            Integer rating = userEntry.getValue().getRating();
            
            uniqueGames
                .computeIfAbsent(userId, k -> new ArrayList<>())
                .add(new UniqueGame(parts[0], parts[1], rating));
        });

    return new TierlistComparison(anio, comparisonUsers, commonGames, uniqueGames);
}
```

### ExploreController.java (añadir compare)

```java
@GetMapping("/compare")
@Operation(summary = "Comparar tierlists de varios usuarios")
public ResponseEntity<TierlistComparison> compare(
        @RequestParam List<Long> userIds,
        @RequestParam Integer anio) {
    return ResponseEntity.ok(exploreService.compare(userIds, anio));
}
```

---

## EXPL-04: GET /api/tierlists/stats - Estadísticas agregadas

### DTOs para estadísticas

```java
// TierlistStats.java
package com.gametierlist.dto.response;

import java.util.List;

public record TierlistStats(
    Long totalEntries,
    Double averageRating,
    List<CategoryStats> categoryStats,
    List<TopGame> topGames,
    List<ActiveUser> activeUsers
) {}

// CategoryStats.java
package com.gametierlist.dto.response;

public record CategoryStats(
    String categoria,
    Integer totalJuegos,
    Double averageRating
) {}

// TopGame.java
package com.gametierlist.dto.response;

public record TopGame(
    String gameNombre,
    String gamePlataforma,
    Double averageRating,
    Integer timesRated
) {}

// ActiveUser.java
package com.gametierlist.dto.response;

public record ActiveUser(
    Long userId,
    String userName,
    Integer totalGamesRated
) {}
```

### ExploreService.java (añadir getStats)

```java
public TierlistStats getStats(Integer anio) {
    List<TierlistEntry> entries;
    
    if (anio != null) {
        entries = entryRepository.findAll(
            TierlistEntrySpecification.withFilters(null, anio, null, null, null, null, null));
    } else {
        entries = entryRepository.findAll();
    }

    if (entries.isEmpty()) {
        return new TierlistStats(0L, 0.0, List.of(), List.of(), List.of());
    }

    // Total y promedio general
    long totalEntries = entries.size();
    double averageRating = entries.stream()
        .mapToInt(TierlistEntry::getRating)
        .average()
        .orElse(0.0);

    // Estadísticas por categoría
    List<CategoryStats> categoryStats = entries.stream()
        .collect(Collectors.groupingBy(TierlistEntry::getGameCategoria))
        .entrySet().stream()
        .map(e -> new CategoryStats(
            e.getKey(),
            e.getValue().size(),
            e.getValue().stream().mapToInt(TierlistEntry::getRating).average().orElse(0.0)
        ))
        .sorted((a, b) -> Double.compare(b.averageRating(), a.averageRating()))
        .toList();

    // Top 10 juegos por promedio de rating
    List<TopGame> topGames = entries.stream()
        .collect(Collectors.groupingBy(
            e -> e.getGameNombre() + "|" + e.getGamePlataforma()))
        .entrySet().stream()
        .map(e -> {
            String[] parts = e.getKey().split("\\|");
            double avg = e.getValue().stream()
                .mapToInt(TierlistEntry::getRating)
                .average().orElse(0.0);
            return new TopGame(parts[0], parts[1], avg, e.getValue().size());
        })
        .sorted((a, b) -> Double.compare(b.averageRating(), a.averageRating()))
        .limit(10)
        .toList();

    // Top 5 usuarios más activos
    List<ActiveUser> activeUsers = entries.stream()
        .collect(Collectors.groupingBy(
            e -> e.getTierlist().getUser().getId()))
        .entrySet().stream()
        .map(e -> {
            var firstEntry = e.getValue().get(0);
            return new ActiveUser(
                e.getKey(),
                firstEntry.getTierlist().getUser().getNombre(),
                e.getValue().size()
            );
        })
        .sorted((a, b) -> Integer.compare(b.totalGamesRated(), a.totalGamesRated()))
        .limit(5)
        .toList();

    return new TierlistStats(totalEntries, averageRating, categoryStats, topGames, activeUsers);
}
```

### ExploreController.java (añadir getStats)

```java
@GetMapping("/stats")
@Operation(summary = "Obtener estadísticas agregadas")
public ResponseEntity<TierlistStats> getStats(
        @RequestParam(required = false) Integer anio) {
    return ResponseEntity.ok(exploreService.getStats(anio));
}
```

---

## 📂 Estructura final del Sprint 5

```
src/main/java/com/gametierlist/
├── controller/
│   ├── CategoryController.java
│   ├── ExploreController.java       // NUEVO
│   ├── GameController.java
│   ├── TierlistController.java
│   └── UserController.java
├── dto/
│   ├── request/
│   │   └── ... (sin cambios)
│   └── response/
│       ├── ActiveUser.java          // NUEVO
│       ├── CategoryResponse.java
│       ├── CategoryStats.java       // NUEVO
│       ├── CommonGame.java          // NUEVO
│       ├── ComparisonUser.java      // NUEVO
│       ├── ErrorResponse.java
│       ├── GameResponse.java
│       ├── TierlistComparison.java  // NUEVO
│       ├── TierlistDetail.java
│       ├── TierlistEntryResponse.java
│       ├── TierlistEntryWithUser.java // NUEVO
│       ├── TierlistOverview.java    // NUEVO
│       ├── TierlistStats.java       // NUEVO
│       ├── TierlistSummary.java
│       ├── TopGame.java             // NUEVO
│       ├── UniqueGame.java          // NUEVO
│       └── UserResponse.java
├── exception/
│   ├── DuplicateEntityException.java
│   ├── EntityInUseException.java
│   ├── EntityNotFoundException.java
│   ├── GlobalExceptionHandler.java  // MODIFICADO
│   ├── InvalidParameterException.java // NUEVO
│   └── RelatedEntityNotFoundException.java
├── service/
│   ├── CategoryService.java
│   ├── ExploreService.java          // NUEVO
│   ├── GameService.java
│   ├── TierlistService.java
│   └── UserService.java
└── specification/
    ├── GameSpecification.java
    └── TierlistEntrySpecification.java // NUEVO
```

---

## 📋 ExploreService.java (versión completa)

```java
package com.gametierlist.service;

import com.gametierlist.dto.response.*;
import com.gametierlist.entity.Tierlist;
import com.gametierlist.entity.TierlistEntry;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.exception.InvalidParameterException;
import com.gametierlist.repository.TierlistEntryRepository;
import com.gametierlist.repository.TierlistRepository;
import com.gametierlist.repository.UserRepository;
import com.gametierlist.specification.TierlistEntrySpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ExploreService {

    private final TierlistRepository tierlistRepository;
    private final TierlistEntryRepository entryRepository;
    private final UserRepository userRepository;

    // ========== LISTAR TIERLISTS ==========

    public Page<TierlistOverview> findAllTierlists(Integer anio, Pageable pageable) {
        Page<Tierlist> page;
        
        if (anio != null) {
            page = tierlistRepository.findAllByAnio(anio, pageable);
        } else {
            page = tierlistRepository.findAllBy(pageable);
        }

        return page.map(this::toOverview);
    }

    private TierlistOverview toOverview(Tierlist tierlist) {
        return new TierlistOverview(
            tierlist.getId(),
            tierlist.getUser().getId(),
            tierlist.getUser().getNombre(),
            tierlist.getAnio(),
            tierlist.getTotalJuegos(),
            tierlist.getCreatedAt()
        );
    }

    // ========== BUSCAR ENTRIES ==========

    public Page<TierlistEntryWithUser> searchEntries(
            Long userId,
            Integer anio,
            String gameNombre,
            String gameCategoria,
            String plataforma,
            Integer ratingMin,
            Integer ratingMax,
            Pageable pageable) {

        var spec = TierlistEntrySpecification.withFilters(
            userId, anio, gameNombre, gameCategoria, plataforma, ratingMin, ratingMax);

        return entryRepository.findAll(spec, pageable)
            .map(this::toEntryWithUser);
    }

    private TierlistEntryWithUser toEntryWithUser(TierlistEntry entry) {
        var tierlist = entry.getTierlist();
        return new TierlistEntryWithUser(
            entry.getId(),
            tierlist.getUser().getId(),
            tierlist.getUser().getNombre(),
            tierlist.getAnio(),
            entry.getGameNombre(),
            entry.getGamePlataforma(),
            entry.getGameCategoria(),
            entry.getRating(),
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

    // ========== COMPARAR TIERLISTS ==========

    public TierlistComparison compare(List<Long> userIds, Integer anio) {
        if (userIds == null || userIds.size() < 2) {
            throw new InvalidParameterException(
                "Se requieren al menos 2 usuarios para comparar");
        }

        for (Long userId : userIds) {
            if (!userRepository.existsById(userId)) {
                throw new EntityNotFoundException("Usuario", userId);
            }
        }

        List<Tierlist> tierlists = userIds.stream()
            .map(userId -> tierlistRepository.findWithEntriesByUserIdAndAnio(userId, anio))
            .filter(Optional::isPresent)
            .map(Optional::get)
            .toList();

        List<ComparisonUser> comparisonUsers = tierlists.stream()
            .map(t -> new ComparisonUser(
                t.getUser().getId(),
                t.getUser().getNombre(),
                t.getTotalJuegos()))
            .toList();

        Map<String, Map<Long, TierlistEntry>> entriesByGame = new HashMap<>();
        
        for (Tierlist tierlist : tierlists) {
            Long userId = tierlist.getUser().getId();
            for (TierlistEntry entry : tierlist.getEntries()) {
                String gameKey = entry.getGameNombre() + "|" + entry.getGamePlataforma();
                entriesByGame
                    .computeIfAbsent(gameKey, k -> new HashMap<>())
                    .put(userId, entry);
            }
        }

        List<CommonGame> commonGames = entriesByGame.entrySet().stream()
            .filter(e -> e.getValue().size() == userIds.size())
            .map(e -> createCommonGame(e.getKey(), e.getValue()))
            .sorted((a, b) -> Double.compare(b.averageRating(), a.averageRating()))
            .toList();

        Map<Long, List<UniqueGame>> uniqueGames = new HashMap<>();
        
        entriesByGame.entrySet().stream()
            .filter(e -> e.getValue().size() == 1)
            .forEach(e -> {
                String[] parts = e.getKey().split("\\|");
                var userEntry = e.getValue().entrySet().iterator().next();
                uniqueGames
                    .computeIfAbsent(userEntry.getKey(), k -> new ArrayList<>())
                    .add(new UniqueGame(parts[0], parts[1], userEntry.getValue().getRating()));
            });

        return new TierlistComparison(anio, comparisonUsers, commonGames, uniqueGames);
    }

    private CommonGame createCommonGame(String gameKey, Map<Long, TierlistEntry> entries) {
        String[] parts = gameKey.split("\\|");
        Map<Long, Integer> ratings = entries.entrySet().stream()
            .collect(Collectors.toMap(Map.Entry::getKey, e -> e.getValue().getRating()));
        
        double avg = ratings.values().stream()
            .mapToInt(Integer::intValue)
            .average().orElse(0.0);
        
        int max = Collections.max(ratings.values());
        int min = Collections.min(ratings.values());
        
        return new CommonGame(parts[0], parts[1], ratings, avg, max - min);
    }

    // ========== ESTADÍSTICAS ==========

    public TierlistStats getStats(Integer anio) {
        List<TierlistEntry> entries;
        
        if (anio != null) {
            entries = entryRepository.findAll(
                TierlistEntrySpecification.withFilters(
                    null, anio, null, null, null, null, null));
        } else {
            entries = entryRepository.findAll();
        }

        if (entries.isEmpty()) {
            return new TierlistStats(0L, 0.0, List.of(), List.of(), List.of());
        }

        long totalEntries = entries.size();
        double averageRating = entries.stream()
            .mapToInt(TierlistEntry::getRating)
            .average().orElse(0.0);

        List<CategoryStats> categoryStats = entries.stream()
            .collect(Collectors.groupingBy(TierlistEntry::getGameCategoria))
            .entrySet().stream()
            .map(e -> new CategoryStats(
                e.getKey(),
                e.getValue().size(),
                e.getValue().stream().mapToInt(TierlistEntry::getRating).average().orElse(0.0)))
            .sorted((a, b) -> Double.compare(b.averageRating(), a.averageRating()))
            .toList();

        List<TopGame> topGames = entries.stream()
            .collect(Collectors.groupingBy(
                e -> e.getGameNombre() + "|" + e.getGamePlataforma()))
            .entrySet().stream()
            .map(e -> {
                String[] parts = e.getKey().split("\\|");
                double avg = e.getValue().stream()
                    .mapToInt(TierlistEntry::getRating).average().orElse(0.0);
                return new TopGame(parts[0], parts[1], avg, e.getValue().size());
            })
            .sorted((a, b) -> Double.compare(b.averageRating(), a.averageRating()))
            .limit(10)
            .toList();

        List<ActiveUser> activeUsers = entries.stream()
            .collect(Collectors.groupingBy(e -> e.getTierlist().getUser().getId()))
            .entrySet().stream()
            .map(e -> {
                var first = e.getValue().get(0);
                return new ActiveUser(
                    e.getKey(),
                    first.getTierlist().getUser().getNombre(),
                    e.getValue().size());
            })
            .sorted((a, b) -> Integer.compare(b.totalGamesRated(), a.totalGamesRated()))
            .limit(5)
            .toList();

        return new TierlistStats(totalEntries, averageRating, categoryStats, topGames, activeUsers);
    }
}
```

---

## 📋 ExploreController.java (versión completa)

```java
package com.gametierlist.controller;

import com.gametierlist.dto.response.*;
import com.gametierlist.service.ExploreService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tierlists")
@RequiredArgsConstructor
@Tag(name = "Explore", description = "Explorar y comparar tierlists")
public class ExploreController {

    private final ExploreService exploreService;

    @GetMapping
    @Operation(summary = "Listar todas las tierlists")
    public ResponseEntity<Page<TierlistOverview>> getAll(
            @RequestParam(required = false) Integer anio,
            @PageableDefault(size = 20, sort = "anio", direction = Sort.Direction.DESC)
            Pageable pageable) {
        return ResponseEntity.ok(exploreService.findAllTierlists(anio, pageable));
    }

    @GetMapping("/entries")
    @Operation(summary = "Buscar entries con filtros")
    public ResponseEntity<Page<TierlistEntryWithUser>> searchEntries(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer anio,
            @RequestParam(required = false) String gameNombre,
            @RequestParam(required = false) String gameCategoria,
            @RequestParam(required = false) String plataforma,
            @RequestParam(required = false) Integer ratingMin,
            @RequestParam(required = false) Integer ratingMax,
            @PageableDefault(size = 20, sort = "rating", direction = Sort.Direction.DESC)
            Pageable pageable) {
        return ResponseEntity.ok(exploreService.searchEntries(
            userId, anio, gameNombre, gameCategoria, plataforma,
            ratingMin, ratingMax, pageable));
    }

    @GetMapping("/compare")
    @Operation(summary = "Comparar tierlists de varios usuarios")
    public ResponseEntity<TierlistComparison> compare(
            @RequestParam List<Long> userIds,
            @RequestParam Integer anio) {
        return ResponseEntity.ok(exploreService.compare(userIds, anio));
    }

    @GetMapping("/stats")
    @Operation(summary = "Obtener estadísticas agregadas")
    public ResponseEntity<TierlistStats> getStats(
            @RequestParam(required = false) Integer anio) {
        return ResponseEntity.ok(exploreService.getStats(anio));
    }
}
```
