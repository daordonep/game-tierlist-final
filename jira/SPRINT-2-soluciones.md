# 📖 Sprint 2: Soluciones de Referencia

> ⚠️ **Usa este documento solo si te atascas.** Intenta implementar primero por tu cuenta siguiendo las especificaciones del ticket.

---

## USER-01: Crear entidad User

### User.java

```java
package com.gametierlist.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "app_user")  // "user" es palabra reservada en SQL
@Getter
@Setter
@NoArgsConstructor
public class User extends BaseEntity {

    @Column(nullable = false, unique = true, length = 50)
    private String nombre;

    public User(String nombre) {
        this.nombre = nombre;
    }
}
```

### UserRepository.java

```java
package com.gametierlist.repository;

import com.gametierlist.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByNombre(String nombre);

    boolean existsByNombre(String nombre);

    boolean existsByNombreAndIdNot(String nombre, Long id);

    List<User> findAllByOrderByNombreAsc();
}
```

### UserRepositoryTest.java

```java
package com.gametierlist.repository;

import com.gametierlist.entity.User;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    @DisplayName("Debe encontrar usuario por nombre")
    void shouldFindByNombre() {
        // Arrange
        entityManager.persistAndFlush(new User("Carlos"));

        // Act
        var result = userRepository.findByNombre("Carlos");

        // Assert
        assertThat(result).isPresent();
        assertThat(result.get().getNombre()).isEqualTo("Carlos");
    }

    @Test
    @DisplayName("Debe devolver true cuando el usuario existe")
    void shouldReturnTrueWhenUserExists() {
        // Arrange
        entityManager.persistAndFlush(new User("Carlos"));

        // Act & Assert
        assertThat(userRepository.existsByNombre("Carlos")).isTrue();
        assertThat(userRepository.existsByNombre("NoExiste")).isFalse();
    }

    @Test
    @DisplayName("Debe encontrar todos los usuarios ordenados por nombre")
    void shouldFindAllUsersOrderedByName() {
        // Arrange
        entityManager.persistAndFlush(new User("Zoe"));
        entityManager.persistAndFlush(new User("Ana"));
        entityManager.persistAndFlush(new User("Carlos"));

        // Act
        var users = userRepository.findAllByOrderByNombreAsc();

        // Assert
        assertThat(users)
            .hasSize(3)
            .extracting(User::getNombre)
            .containsExactly("Ana", "Carlos", "Zoe");
    }

    @Test
    @DisplayName("Debe verificar si nombre existe excluyendo un ID")
    void shouldCheckExistsByNombreExcludingId() {
        // Arrange
        var user1 = entityManager.persistAndFlush(new User("Carlos"));
        entityManager.persistAndFlush(new User("Ana"));

        // Act & Assert
        // "Ana" existe y no es el user1
        assertThat(userRepository.existsByNombreAndIdNot("Ana", user1.getId())).isTrue();
        // "Carlos" existe pero ES el user1, así que devuelve false
        assertThat(userRepository.existsByNombreAndIdNot("Carlos", user1.getId())).isFalse();
    }
}
```

---

## USER-02: GET /api/users - Listar usuarios

### UserResponse.java

```java
package com.gametierlist.dto.response;

import java.time.LocalDateTime;

public record UserResponse(
    Long id,
    String nombre,
    LocalDateTime fechaCreacion
) {}
```

### UserMapper.java

```java
package com.gametierlist.mapper;

import com.gametierlist.dto.request.CreateUserRequest;
import com.gametierlist.dto.response.UserResponse;
import com.gametierlist.entity.User;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {

    public UserResponse toResponse(User user) {
        return new UserResponse(
            user.getId(),
            user.getNombre(),
            user.getCreatedAt()
        );
    }

    public User toEntity(CreateUserRequest request) {
        return new User(request.nombre().trim());
    }
}
```

### UserService.java (versión inicial)

```java
package com.gametierlist.service;

import com.gametierlist.dto.response.UserResponse;
import com.gametierlist.mapper.UserMapper;
import com.gametierlist.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public List<UserResponse> findAll() {
        return userRepository.findAllByOrderByNombreAsc()
            .stream()
            .map(userMapper::toResponse)
            .toList();
    }
}
```

### UserController.java (versión inicial)

```java
package com.gametierlist.controller;

import com.gametierlist.dto.response.UserResponse;
import com.gametierlist.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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

### UserServiceTest.java (para USER-02)

```java
package com.gametierlist.service;

import com.gametierlist.dto.response.UserResponse;
import com.gametierlist.entity.User;
import com.gametierlist.mapper.UserMapper;
import com.gametierlist.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserMapper userMapper;

    @InjectMocks
    private UserService userService;

    @Test
    @DisplayName("Debe devolver todos los usuarios ordenados")
    void shouldReturnAllUsersOrdered() {
        // Arrange
        var user1 = createUser(1L, "Ana");
        var user2 = createUser(2L, "Carlos");
        var response1 = new UserResponse(1L, "Ana", LocalDateTime.now());
        var response2 = new UserResponse(2L, "Carlos", LocalDateTime.now());

        when(userRepository.findAllByOrderByNombreAsc()).thenReturn(List.of(user1, user2));
        when(userMapper.toResponse(user1)).thenReturn(response1);
        when(userMapper.toResponse(user2)).thenReturn(response2);

        // Act
        var result = userService.findAll();

        // Assert
        assertThat(result).hasSize(2);
        assertThat(result.get(0).nombre()).isEqualTo("Ana");
        assertThat(result.get(1).nombre()).isEqualTo("Carlos");
    }

    @Test
    @DisplayName("Debe devolver lista vacía cuando no hay usuarios")
    void shouldReturnEmptyListWhenNoUsers() {
        // Arrange
        when(userRepository.findAllByOrderByNombreAsc()).thenReturn(Collections.emptyList());

        // Act
        var result = userService.findAll();

        // Assert
        assertThat(result).isEmpty();
    }

    private User createUser(Long id, String nombre) {
        var user = new User(nombre);
        user.setId(id);
        user.setCreatedAt(LocalDateTime.now());
        return user;
    }
}
```

---

## USER-03: POST /api/users - Crear usuario

### CreateUserRequest.java

```java
package com.gametierlist.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateUserRequest(
    @NotBlank(message = "El nombre es obligatorio")
    @Size(min = 2, max = 50, message = "El nombre debe tener entre 2 y 50 caracteres")
    String nombre
) {}
```

### UserService.java (añadir método create)

```java
@Transactional
public UserResponse create(CreateUserRequest request) {
    String nombre = request.nombre().trim();

    if (userRepository.existsByNombre(nombre)) {
        throw new DuplicateEntityException(
            "Ya existe un usuario con el nombre '" + nombre + "'"
        );
    }

    var user = new User(nombre);
    var saved = userRepository.save(user);
    return userMapper.toResponse(saved);
}
```

### UserController.java (añadir método create)

```java
@PostMapping
@Operation(summary = "Crear nuevo usuario")
public ResponseEntity<UserResponse> create(
        @Valid @RequestBody CreateUserRequest request) {
    var created = userService.create(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}
```

### Tests adicionales para UserServiceTest.java

```java
@Test
@DisplayName("Debe crear usuario cuando el nombre es único")
void shouldCreateUser_WhenNameIsUnique() {
    // Arrange
    var request = new CreateUserRequest("Carlos");
    var user = createUser(1L, "Carlos");
    var response = new UserResponse(1L, "Carlos", LocalDateTime.now());

    when(userRepository.existsByNombre("Carlos")).thenReturn(false);
    when(userRepository.save(any(User.class))).thenReturn(user);
    when(userMapper.toResponse(user)).thenReturn(response);

    // Act
    var result = userService.create(request);

    // Assert
    assertThat(result.nombre()).isEqualTo("Carlos");
    verify(userRepository).save(any(User.class));
}

@Test
@DisplayName("Debe lanzar excepción cuando el nombre ya existe")
void shouldThrowDuplicateException_WhenNameExists() {
    // Arrange
    var request = new CreateUserRequest("Carlos");
    when(userRepository.existsByNombre("Carlos")).thenReturn(true);

    // Act & Assert
    assertThatThrownBy(() -> userService.create(request))
        .isInstanceOf(DuplicateEntityException.class)
        .hasMessageContaining("Carlos");

    verify(userRepository, never()).save(any());
}

@Test
@DisplayName("Debe aplicar trim a los espacios del nombre")
void shouldTrimSpaces_WhenNameHasSpaces() {
    // Arrange
    var request = new CreateUserRequest("  Carlos  ");
    var user = createUser(1L, "Carlos");
    var response = new UserResponse(1L, "Carlos", LocalDateTime.now());

    when(userRepository.existsByNombre("Carlos")).thenReturn(false);
    when(userRepository.save(any(User.class))).thenReturn(user);
    when(userMapper.toResponse(user)).thenReturn(response);

    // Act
    var result = userService.create(request);

    // Assert
    verify(userRepository).existsByNombre("Carlos");  // Verificar que buscó sin espacios
}
```

### UserControllerTest.java

```java
package com.gametierlist.controller;

import com.gametierlist.dto.response.UserResponse;
import com.gametierlist.exception.DuplicateEntityException;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.service.UserService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Test
    @DisplayName("GET /api/users debe devolver 200 con lista de usuarios")
    void shouldReturn200WithUsers() throws Exception {
        var users = List.of(
            new UserResponse(1L, "Ana", LocalDateTime.now()),
            new UserResponse(2L, "Carlos", LocalDateTime.now())
        );
        when(userService.findAll()).thenReturn(users);

        mockMvc.perform(get("/api/users"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(2)))
            .andExpect(jsonPath("$[0].nombre").value("Ana"));
    }

    @Test
    @DisplayName("GET /api/users debe devolver 200 con lista vacía")
    void shouldReturn200WithEmptyList() throws Exception {
        when(userService.findAll()).thenReturn(List.of());

        mockMvc.perform(get("/api/users"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    @DisplayName("POST /api/users debe devolver 201 cuando es válido")
    void shouldReturn201_WhenValidRequest() throws Exception {
        var response = new UserResponse(1L, "Carlos", LocalDateTime.now());
        when(userService.create(any())).thenReturn(response);

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nombre": "Carlos"}
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.nombre").value("Carlos"));
    }

    @Test
    @DisplayName("POST /api/users debe devolver 400 cuando nombre está vacío")
    void shouldReturn400_WhenNameIsBlank() throws Exception {
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nombre": ""}
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    @DisplayName("POST /api/users debe devolver 400 cuando nombre es muy corto")
    void shouldReturn400_WhenNameTooShort() throws Exception {
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nombre": "A"}
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    @DisplayName("POST /api/users debe devolver 409 cuando nombre duplicado")
    void shouldReturn409_WhenNameIsDuplicate() throws Exception {
        when(userService.create(any()))
            .thenThrow(new DuplicateEntityException("Ya existe un usuario con el nombre 'Carlos'"));

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nombre": "Carlos"}
                    """))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("DUPLICATE_ENTITY"));
    }
}
```

---

## USER-04: GET /api/users/{id} - Obtener usuario por ID

### UserService.java (añadir método findById)

```java
public UserResponse findById(Long id) {
    return userRepository.findById(id)
        .map(userMapper::toResponse)
        .orElseThrow(() -> new EntityNotFoundException("Usuario", id));
}
```

### UserController.java (añadir método getById)

```java
@GetMapping("/{id}")
@Operation(summary = "Obtener usuario por ID")
public ResponseEntity<UserResponse> getById(@PathVariable Long id) {
    return ResponseEntity.ok(userService.findById(id));
}
```

### Tests adicionales

```java
// UserServiceTest.java
@Test
@DisplayName("Debe devolver usuario cuando el ID existe")
void shouldReturnUser_WhenIdExists() {
    // Arrange
    var user = createUser(1L, "Carlos");
    var response = new UserResponse(1L, "Carlos", LocalDateTime.now());

    when(userRepository.findById(1L)).thenReturn(Optional.of(user));
    when(userMapper.toResponse(user)).thenReturn(response);

    // Act
    var result = userService.findById(1L);

    // Assert
    assertThat(result.nombre()).isEqualTo("Carlos");
}

@Test
@DisplayName("Debe lanzar excepción cuando el ID no existe")
void shouldThrowNotFound_WhenIdDoesNotExist() {
    // Arrange
    when(userRepository.findById(999L)).thenReturn(Optional.empty());

    // Act & Assert
    assertThatThrownBy(() -> userService.findById(999L))
        .isInstanceOf(EntityNotFoundException.class)
        .hasMessageContaining("999");
}

// UserControllerTest.java
@Test
@DisplayName("GET /api/users/{id} debe devolver 200 cuando existe")
void shouldReturn200_WhenUserExists() throws Exception {
    var response = new UserResponse(1L, "Carlos", LocalDateTime.now());
    when(userService.findById(1L)).thenReturn(response);

    mockMvc.perform(get("/api/users/1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.nombre").value("Carlos"));
}

@Test
@DisplayName("GET /api/users/{id} debe devolver 404 cuando no existe")
void shouldReturn404_WhenUserNotFound() throws Exception {
    when(userService.findById(999L))
        .thenThrow(new EntityNotFoundException("Usuario", 999L));

    mockMvc.perform(get("/api/users/999"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.code").value("NOT_FOUND"));
}
```

---

## USER-05: PUT /api/users/{id} - Actualizar usuario

### UpdateUserRequest.java

```java
package com.gametierlist.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
    @NotBlank(message = "El nombre es obligatorio")
    @Size(min = 2, max = 50, message = "El nombre debe tener entre 2 y 50 caracteres")
    String nombre
) {}
```

### UserService.java (añadir método update)

```java
@Transactional
public UserResponse update(Long id, UpdateUserRequest request) {
    var user = userRepository.findById(id)
        .orElseThrow(() -> new EntityNotFoundException("Usuario", id));

    String nuevoNombre = request.nombre().trim();

    // Verificar si el nuevo nombre ya está en uso por OTRO usuario
    if (userRepository.existsByNombreAndIdNot(nuevoNombre, id)) {
        throw new DuplicateEntityException(
            "Ya existe otro usuario con el nombre '" + nuevoNombre + "'"
        );
    }

    user.setNombre(nuevoNombre);
    var saved = userRepository.save(user);
    return userMapper.toResponse(saved);
}
```

### UserController.java (añadir método update)

```java
@PutMapping("/{id}")
@Operation(summary = "Actualizar usuario")
public ResponseEntity<UserResponse> update(
        @PathVariable Long id,
        @Valid @RequestBody UpdateUserRequest request) {
    return ResponseEntity.ok(userService.update(id, request));
}
```

### Tests adicionales

```java
// UserServiceTest.java
@Test
@DisplayName("Debe actualizar usuario cuando el nuevo nombre es único")
void shouldUpdateUser_WhenNewNameIsUnique() {
    // Arrange
    var user = createUser(1L, "Carlos");
    var request = new UpdateUserRequest("NuevoNombre");
    var response = new UserResponse(1L, "NuevoNombre", LocalDateTime.now());

    when(userRepository.findById(1L)).thenReturn(Optional.of(user));
    when(userRepository.existsByNombreAndIdNot("NuevoNombre", 1L)).thenReturn(false);
    when(userRepository.save(user)).thenReturn(user);
    when(userMapper.toResponse(user)).thenReturn(response);

    // Act
    var result = userService.update(1L, request);

    // Assert
    assertThat(result.nombre()).isEqualTo("NuevoNombre");
    verify(userRepository).save(user);
}

@Test
@DisplayName("Debe actualizar usuario cuando el nombre no cambia")
void shouldUpdateUser_WhenNameUnchanged() {
    // Arrange
    var user = createUser(1L, "Carlos");
    var request = new UpdateUserRequest("Carlos");
    var response = new UserResponse(1L, "Carlos", LocalDateTime.now());

    when(userRepository.findById(1L)).thenReturn(Optional.of(user));
    when(userRepository.existsByNombreAndIdNot("Carlos", 1L)).thenReturn(false);
    when(userRepository.save(user)).thenReturn(user);
    when(userMapper.toResponse(user)).thenReturn(response);

    // Act
    var result = userService.update(1L, request);

    // Assert
    assertThat(result.nombre()).isEqualTo("Carlos");
}

@Test
@DisplayName("Debe lanzar excepción cuando el nombre está usado por otro")
void shouldThrowDuplicate_WhenNameUsedByAnother() {
    // Arrange
    var user = createUser(1L, "Carlos");
    var request = new UpdateUserRequest("NombreDeOtro");

    when(userRepository.findById(1L)).thenReturn(Optional.of(user));
    when(userRepository.existsByNombreAndIdNot("NombreDeOtro", 1L)).thenReturn(true);

    // Act & Assert
    assertThatThrownBy(() -> userService.update(1L, request))
        .isInstanceOf(DuplicateEntityException.class);

    verify(userRepository, never()).save(any());
}

// UserControllerTest.java
@Test
@DisplayName("PUT /api/users/{id} debe devolver 200 cuando actualización exitosa")
void shouldReturn200_WhenUpdateSuccessful() throws Exception {
    var response = new UserResponse(1L, "NuevoNombre", LocalDateTime.now());
    when(userService.update(eq(1L), any())).thenReturn(response);

    mockMvc.perform(put("/api/users/1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"nombre": "NuevoNombre"}
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.nombre").value("NuevoNombre"));
}

@Test
@DisplayName("PUT /api/users/{id} debe devolver 404 cuando usuario no existe")
void shouldReturn404_WhenUserToUpdateNotFound() throws Exception {
    when(userService.update(eq(999L), any()))
        .thenThrow(new EntityNotFoundException("Usuario", 999L));

    mockMvc.perform(put("/api/users/999")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"nombre": "NuevoNombre"}
                """))
        .andExpect(status().isNotFound());
}

@Test
@DisplayName("PUT /api/users/{id} debe devolver 409 cuando nombre duplicado")
void shouldReturn409_WhenNewNameIsDuplicate() throws Exception {
    when(userService.update(eq(1L), any()))
        .thenThrow(new DuplicateEntityException("Ya existe otro usuario con ese nombre"));

    mockMvc.perform(put("/api/users/1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"nombre": "NombreDeOtro"}
                """))
        .andExpect(status().isConflict());
}
```

---

## USER-06: DELETE /api/users/{id} - Eliminar usuario

### UserService.java (añadir método delete)

```java
@Transactional
public void delete(Long id) {
    if (!userRepository.existsById(id)) {
        throw new EntityNotFoundException("Usuario", id);
    }
    userRepository.deleteById(id);
}
```

### UserController.java (añadir método delete)

```java
@DeleteMapping("/{id}")
@Operation(summary = "Eliminar usuario")
public ResponseEntity<Void> delete(@PathVariable Long id) {
    userService.delete(id);
    return ResponseEntity.noContent().build();
}
```

### Tests adicionales

```java
// UserServiceTest.java
@Test
@DisplayName("Debe eliminar usuario cuando existe")
void shouldDeleteUser_WhenExists() {
    // Arrange
    when(userRepository.existsById(1L)).thenReturn(true);

    // Act
    userService.delete(1L);

    // Assert
    verify(userRepository).deleteById(1L);
}

@Test
@DisplayName("Debe lanzar excepción cuando usuario a eliminar no existe")
void shouldThrowNotFound_WhenUserToDeleteDoesNotExist() {
    // Arrange
    when(userRepository.existsById(999L)).thenReturn(false);

    // Act & Assert
    assertThatThrownBy(() -> userService.delete(999L))
        .isInstanceOf(EntityNotFoundException.class);

    verify(userRepository, never()).deleteById(anyLong());
}

// UserControllerTest.java
@Test
@DisplayName("DELETE /api/users/{id} debe devolver 204 cuando exitoso")
void shouldReturn204_WhenDeleteSuccessful() throws Exception {
    doNothing().when(userService).delete(1L);

    mockMvc.perform(delete("/api/users/1"))
        .andExpect(status().isNoContent());
}

@Test
@DisplayName("DELETE /api/users/{id} debe devolver 404 cuando no existe")
void shouldReturn404_WhenUserToDeleteNotFound() throws Exception {
    doThrow(new EntityNotFoundException("Usuario", 999L))
        .when(userService).delete(999L);

    mockMvc.perform(delete("/api/users/999"))
        .andExpect(status().isNotFound());
}
```

### UserControllerIT.java (Test de integración)

```java
package com.gametierlist.integration;

import com.gametierlist.dto.request.CreateUserRequest;
import com.gametierlist.dto.response.UserResponse;
import com.gametierlist.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class UserControllerIT {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("Debe eliminar usuario y verificar que no existe en BD")
    void shouldDeleteUserAndVerifyNotInDatabase() {
        // Arrange - Crear usuario
        var createRequest = new CreateUserRequest("Carlos");
        var createResponse = restTemplate.postForEntity(
            "/api/users", createRequest, UserResponse.class);
        
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        var userId = createResponse.getBody().id();

        // Act - Eliminar usuario
        restTemplate.delete("/api/users/" + userId);

        // Assert - Verificar que no existe
        var getResponse = restTemplate.getForEntity(
            "/api/users/" + userId, String.class);
        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);

        // Verificar directamente en BD
        assertThat(userRepository.findById(userId)).isEmpty();
    }
}
```

---

## 📂 Estructura final del Sprint 2

```
src/main/java/com/gametierlist/
├── controller/
│   ├── CategoryController.java
│   └── UserController.java          // NUEVO
├── dto/
│   ├── request/
│   │   ├── CreateUserRequest.java   // NUEVO
│   │   └── UpdateUserRequest.java   // NUEVO
│   └── response/
│       ├── CategoryResponse.java
│       ├── ErrorResponse.java
│       └── UserResponse.java        // NUEVO
├── entity/
│   ├── BaseEntity.java
│   ├── Category.java
│   └── User.java                    // NUEVO
├── mapper/
│   ├── CategoryMapper.java
│   └── UserMapper.java              // NUEVO
├── repository/
│   ├── CategoryRepository.java
│   └── UserRepository.java          // NUEVO
└── service/
    ├── CategoryService.java
    └── UserService.java             // NUEVO

src/test/java/com/gametierlist/
├── controller/
│   ├── CategoryControllerTest.java
│   └── UserControllerTest.java      // NUEVO
├── integration/
│   └── UserControllerIT.java        // NUEVO
├── repository/
│   ├── CategoryRepositoryTest.java
│   └── UserRepositoryTest.java      // NUEVO
└── service/
    ├── CategoryServiceTest.java
    └── UserServiceTest.java         // NUEVO
```

---

## 📋 UserService.java (versión completa)

```java
package com.gametierlist.service;

import com.gametierlist.dto.request.CreateUserRequest;
import com.gametierlist.dto.request.UpdateUserRequest;
import com.gametierlist.dto.response.UserResponse;
import com.gametierlist.entity.User;
import com.gametierlist.exception.DuplicateEntityException;
import com.gametierlist.exception.EntityNotFoundException;
import com.gametierlist.mapper.UserMapper;
import com.gametierlist.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public List<UserResponse> findAll() {
        return userRepository.findAllByOrderByNombreAsc()
            .stream()
            .map(userMapper::toResponse)
            .toList();
    }

    public UserResponse findById(Long id) {
        return userRepository.findById(id)
            .map(userMapper::toResponse)
            .orElseThrow(() -> new EntityNotFoundException("Usuario", id));
    }

    @Transactional
    public UserResponse create(CreateUserRequest request) {
        String nombre = request.nombre().trim();

        if (userRepository.existsByNombre(nombre)) {
            throw new DuplicateEntityException(
                "Ya existe un usuario con el nombre '" + nombre + "'"
            );
        }

        var user = new User(nombre);
        var saved = userRepository.save(user);
        return userMapper.toResponse(saved);
    }

    @Transactional
    public UserResponse update(Long id, UpdateUserRequest request) {
        var user = userRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Usuario", id));

        String nuevoNombre = request.nombre().trim();

        if (userRepository.existsByNombreAndIdNot(nuevoNombre, id)) {
            throw new DuplicateEntityException(
                "Ya existe otro usuario con el nombre '" + nuevoNombre + "'"
            );
        }

        user.setNombre(nuevoNombre);
        var saved = userRepository.save(user);
        return userMapper.toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        if (!userRepository.existsById(id)) {
            throw new EntityNotFoundException("Usuario", id);
        }
        userRepository.deleteById(id);
    }
}
```

---

## 📋 UserController.java (versión completa)

```java
package com.gametierlist.controller;

import com.gametierlist.dto.request.CreateUserRequest;
import com.gametierlist.dto.request.UpdateUserRequest;
import com.gametierlist.dto.response.UserResponse;
import com.gametierlist.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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

    @GetMapping("/{id}")
    @Operation(summary = "Obtener usuario por ID")
    public ResponseEntity<UserResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.findById(id));
    }

    @PostMapping
    @Operation(summary = "Crear nuevo usuario")
    public ResponseEntity<UserResponse> create(
            @Valid @RequestBody CreateUserRequest request) {
        var created = userService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Actualizar usuario")
    public ResponseEntity<UserResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRequest request) {
        return ResponseEntity.ok(userService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Eliminar usuario")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```
