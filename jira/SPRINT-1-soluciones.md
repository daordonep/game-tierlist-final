# 📖 Sprint 1: Soluciones de Referencia

> ⚠️ **Usa este documento solo si te atascas.** Intenta implementar primero por tu cuenta siguiendo las especificaciones del ticket.

---

## SETUP-01: Crear proyecto Spring Boot 3

### pom.xml (sección properties y dependencies)

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
    <description>API para gestionar tierlists de juegos</description>
    
    <properties>
        <java.version>17</java.version>
    </properties>
    
    <dependencies>
        <!-- Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <!-- JPA -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <!-- Validación -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <!-- H2 (desarrollo) -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        
        <!-- PostgreSQL (producción) -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
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
        
        <!-- Test -->
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

### application.yml

```yaml
spring:
  application:
    name: game-tierlist
  profiles:
    active: dev
  jpa:
    open-in-view: false

server:
  port: 8080
```

### GameTierlistApplication.java

```java
package com.gametierlist;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class GameTierlistApplication {

    public static void main(String[] args) {
        SpringApplication.run(GameTierlistApplication.class, args);
    }
}
```

---

## SETUP-02: Configurar perfil de desarrollo (H2)

### application-dev.yml

```yaml
spring:
  datasource:
    url: jdbc:h2:mem:gametierlist
    driver-class-name: org.h2.Driver
    username: sa
    password:
  h2:
    console:
      enabled: true
      path: /h2-console
      settings:
        web-allow-others: false
  jpa:
    database-platform: org.hibernate.dialect.H2Dialect
    hibernate:
      ddl-auto: create-drop
    show-sql: true
    properties:
      hibernate:
        format_sql: true
  sql:
    init:
      mode: always

logging:
  level:
    com.gametierlist: DEBUG
    org.springframework.web: DEBUG
    org.hibernate.SQL: DEBUG
    org.hibernate.orm.jdbc.bind: TRACE
```

---

## SETUP-03: Configurar CORS

### CorsConfig.java

```java
package com.gametierlist.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins("*")
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowedHeaders("*")
                    .maxAge(3600);
            }
        };
    }
}
```

---

## SETUP-04: Configurar Swagger/OpenAPI

### OpenApiConfig.java

```java
package com.gametierlist.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Game Tierlist API")
                .version("1.0")
                .description("API para gestionar tierlists de juegos entre amigos")
                .contact(new Contact()
                    .name("Tu Nombre")
                    .email("tu@email.com")));
    }
}
```

### Configuración adicional en application.yml

```yaml
springdoc:
  swagger-ui:
    path: /swagger-ui.html
    tags-sorter: alpha
    operations-sorter: method
  api-docs:
    path: /api-docs
```

---

## SETUP-05: Crear manejador global de excepciones

### ErrorResponse.java

```java
package com.gametierlist.dto.response;

import java.time.LocalDateTime;

public record ErrorResponse(
    String code,
    String message,
    LocalDateTime timestamp,
    String path
) {
    // Constructor compacto que añade timestamp automáticamente
    public ErrorResponse(String code, String message, String path) {
        this(code, message, LocalDateTime.now(), path);
    }
}
```

### EntityNotFoundException.java

```java
package com.gametierlist.exception;

public class EntityNotFoundException extends RuntimeException {

    public EntityNotFoundException(String message) {
        super(message);
    }

    public EntityNotFoundException(String entity, Long id) {
        super(entity + " con id " + id + " no encontrado");
    }
}
```

### DuplicateEntityException.java

```java
package com.gametierlist.exception;

public class DuplicateEntityException extends RuntimeException {

    public DuplicateEntityException(String message) {
        super(message);
    }
}
```

### GlobalExceptionHandler.java

```java
package com.gametierlist.exception;

import com.gametierlist.dto.response.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(
            EntityNotFoundException ex,
            HttpServletRequest request) {
        
        var error = new ErrorResponse(
            "NOT_FOUND",
            ex.getMessage(),
            request.getRequestURI()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    @ExceptionHandler(DuplicateEntityException.class)
    public ResponseEntity<ErrorResponse> handleDuplicate(
            DuplicateEntityException ex,
            HttpServletRequest request) {
        
        var error = new ErrorResponse(
            "DUPLICATE_ENTITY",
            ex.getMessage(),
            request.getRequestURI()
        );
        return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        
        String message = ex.getBindingResult().getFieldErrors().stream()
            .map(err -> err.getField() + ": " + err.getDefaultMessage())
            .collect(Collectors.joining(", "));
        
        var error = new ErrorResponse(
            "VALIDATION_ERROR",
            message,
            request.getRequestURI()
        );
        return ResponseEntity.badRequest().body(error);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(
            Exception ex,
            HttpServletRequest request) {
        
        var error = new ErrorResponse(
            "INTERNAL_ERROR",
            "Error interno del servidor",
            request.getRequestURI()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
```

---

## SETUP-06: Crear BaseEntity con auditoría

### JpaAuditingConfig.java

```java
package com.gametierlist.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration
@EnableJpaAuditing
public class JpaAuditingConfig {
}
```

### BaseEntity.java

```java
package com.gametierlist.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Getter
@Setter
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
```

---

## CAT-01: Crear entidad Category y datos iniciales

### Category.java

```java
package com.gametierlist.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "category")
@Getter
@Setter
@NoArgsConstructor
public class Category extends BaseEntity {

    @Column(nullable = false, unique = true, length = 50)
    private String nombre;

    @Column(length = 255)
    private String descripcion;

    public Category(String nombre, String descripcion) {
        this.nombre = nombre;
        this.descripcion = descripcion;
    }
}
```

### CategoryRepository.java

```java
package com.gametierlist.repository;

import com.gametierlist.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    List<Category> findAllByOrderByNombreAsc();

    Optional<Category> findByNombre(String nombre);

    boolean existsByNombre(String nombre);
}
```

### data.sql

```sql
-- Categorías de juegos
INSERT INTO category (nombre, descripcion, created_at, updated_at) VALUES
('Acción', 'Juegos de combate y reflejos rápidos', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Aventura', 'Juegos de exploración y narrativa', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Carreras', 'Juegos de conducción y velocidad', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Deportes', 'Simuladores deportivos', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Estrategia', 'Juegos de táctica y gestión de recursos', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Indie', 'Juegos independientes de diversos géneros', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Plataformas', 'Juegos de saltos y habilidad', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Puzzle', 'Juegos de lógica y rompecabezas', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('RPG', 'Juegos de rol con progresión de personaje', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Shooter', 'Juegos de disparos en primera o tercera persona', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Simulación', 'Simuladores de vida, construcción o gestión', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Terror', 'Juegos de horror y supervivencia', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
```

### CategoryRepositoryTest.java

```java
package com.gametierlist.repository;

import com.gametierlist.entity.Category;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class CategoryRepositoryTest {

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    @DisplayName("Debe encontrar todas las categorías ordenadas por nombre")
    void shouldFindAllCategoriesOrderedByName() {
        // Arrange
        entityManager.persistAndFlush(new Category("Puzzle", "Rompecabezas"));
        entityManager.persistAndFlush(new Category("Acción", "Combate"));
        entityManager.persistAndFlush(new Category("RPG", "Rol"));

        // Act
        var categories = categoryRepository.findAllByOrderByNombreAsc();

        // Assert
        assertThat(categories)
            .hasSize(3)
            .extracting(Category::getNombre)
            .containsExactly("Acción", "Puzzle", "RPG");
    }

    @Test
    @DisplayName("Debe encontrar categoría por nombre")
    void shouldFindByNombre() {
        // Arrange
        entityManager.persistAndFlush(new Category("RPG", "Juegos de rol"));

        // Act
        var result = categoryRepository.findByNombre("RPG");

        // Assert
        assertThat(result).isPresent();
        assertThat(result.get().getDescripcion()).isEqualTo("Juegos de rol");
    }
}
```

---

## CAT-02: Crear endpoints de categorías

### CategoryResponse.java

```java
package com.gametierlist.dto.response;

public record CategoryResponse(
    Long id,
    String nombre,
    String descripcion
) {}
```

### CategoryMapper.java

```java
package com.gametierlist.mapper;

import com.gametierlist.dto.response.CategoryResponse;
import com.gametierlist.entity.Category;
import org.springframework.stereotype.Component;

@Component
public class CategoryMapper {

    public CategoryResponse toResponse(Category category) {
        return new CategoryResponse(
            category.getId(),
            category.getNombre(),
            category.getDescripcion()
        );
    }
}
```

### CategoryService.java

```java
package com.gametierlist.service;

import com.gametierlist.dto.response.CategoryResponse;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.mapper.CategoryMapper;
import com.gametierlist.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final CategoryMapper categoryMapper;

    public List<CategoryResponse> findAll() {
        return categoryRepository.findAllByOrderByNombreAsc()
            .stream()
            .map(categoryMapper::toResponse)
            .toList();
    }

    public CategoryResponse findById(Long id) {
        return categoryRepository.findById(id)
            .map(categoryMapper::toResponse)
            .orElseThrow(() -> new EntityNotFoundException("Categoría", id));
    }
}
```

### CategoryController.java

```java
package com.gametierlist.controller;

import com.gametierlist.dto.response.CategoryResponse;
import com.gametierlist.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@Tag(name = "Categories", description = "Categorías de juegos")
public class CategoryController {

    private final CategoryService categoryService;

    @GetMapping
    @Operation(summary = "Listar todas las categorías")
    public ResponseEntity<List<CategoryResponse>> getAll() {
        return ResponseEntity.ok(categoryService.findAll());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obtener categoría por ID")
    public ResponseEntity<CategoryResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(categoryService.findById(id));
    }
}
```

### CategoryServiceTest.java

```java
package com.gametierlist.service;

import com.gametierlist.dto.response.CategoryResponse;
import com.gametierlist.entity.Category;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.mapper.CategoryMapper;
import com.gametierlist.repository.CategoryRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private CategoryMapper categoryMapper;

    @InjectMocks
    private CategoryService categoryService;

    @Test
    @DisplayName("Debe devolver todas las categorías ordenadas")
    void shouldReturnAllCategoriesOrdered() {
        // Arrange
        var category1 = new Category("Acción", "Combate");
        var category2 = new Category("RPG", "Rol");
        var response1 = new CategoryResponse(1L, "Acción", "Combate");
        var response2 = new CategoryResponse(2L, "RPG", "Rol");

        when(categoryRepository.findAllByOrderByNombreAsc())
            .thenReturn(List.of(category1, category2));
        when(categoryMapper.toResponse(category1)).thenReturn(response1);
        when(categoryMapper.toResponse(category2)).thenReturn(response2);

        // Act
        var result = categoryService.findAll();

        // Assert
        assertThat(result).hasSize(2);
        assertThat(result.get(0).nombre()).isEqualTo("Acción");
    }

    @Test
    @DisplayName("Debe devolver categoría por ID")
    void shouldReturnCategoryById() {
        // Arrange
        var category = new Category("RPG", "Rol");
        category.setId(1L);
        var response = new CategoryResponse(1L, "RPG", "Rol");

        when(categoryRepository.findById(1L)).thenReturn(Optional.of(category));
        when(categoryMapper.toResponse(category)).thenReturn(response);

        // Act
        var result = categoryService.findById(1L);

        // Assert
        assertThat(result.nombre()).isEqualTo("RPG");
    }

    @Test
    @DisplayName("Debe lanzar excepción cuando la categoría no existe")
    void shouldThrowNotFound_WhenCategoryDoesNotExist() {
        // Arrange
        when(categoryRepository.findById(999L)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> categoryService.findById(999L))
            .isInstanceOf(EntityNotFoundException.class)
            .hasMessageContaining("999");
    }
}
```

### CategoryControllerTest.java

```java
package com.gametierlist.controller;

import com.gametierlist.dto.response.CategoryResponse;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.service.CategoryService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(CategoryController.class)
class CategoryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CategoryService categoryService;

    @Test
    @DisplayName("GET /api/categories debe devolver 200 con lista de categorías")
    void shouldReturn200WithCategories() throws Exception {
        // Arrange
        var categories = List.of(
            new CategoryResponse(1L, "Acción", "Combate"),
            new CategoryResponse(2L, "RPG", "Rol")
        );
        when(categoryService.findAll()).thenReturn(categories);

        // Act & Assert
        mockMvc.perform(get("/api/categories"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(2)))
            .andExpect(jsonPath("$[0].nombre").value("Acción"))
            .andExpect(jsonPath("$[1].nombre").value("RPG"));
    }

    @Test
    @DisplayName("GET /api/categories/{id} debe devolver 404 si no existe")
    void shouldReturn404WhenCategoryNotFound() throws Exception {
        // Arrange
        when(categoryService.findById(999L))
            .thenThrow(new EntityNotFoundException("Categoría", 999L));

        // Act & Assert
        mockMvc.perform(get("/api/categories/999"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.code").value("NOT_FOUND"));
    }
}
```

---

## 📂 Estructura final del Sprint 1

```
src/main/java/com/gametierlist/
├── GameTierlistApplication.java
├── config/
│   ├── CorsConfig.java
│   ├── JpaAuditingConfig.java
│   └── OpenApiConfig.java
├── controller/
│   └── CategoryController.java
├── dto/
│   ├── request/
│   └── response/
│       ├── CategoryResponse.java
│       └── ErrorResponse.java
├── entity/
│   ├── BaseEntity.java
│   └── Category.java
├── exception/
│   ├── DuplicateEntityException.java
│   ├── EntityNotFoundException.java
│   └── GlobalExceptionHandler.java
├── mapper/
│   └── CategoryMapper.java
├── repository/
│   └── CategoryRepository.java
└── service/
    └── CategoryService.java

src/main/resources/
├── application.yml
├── application-dev.yml
└── data.sql

src/test/java/com/gametierlist/
├── controller/
│   └── CategoryControllerTest.java
├── repository/
│   └── CategoryRepositoryTest.java
└── service/
    └── CategoryServiceTest.java
```
