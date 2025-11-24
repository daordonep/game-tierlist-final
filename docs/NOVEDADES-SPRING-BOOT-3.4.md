# 🆕 Novedades de Spring Boot 3.4

Este documento cubre las mejoras de Spring Boot 3.4.x respecto a versiones anteriores.

---

## ¿Por qué Spring Boot 3.4.12?

| Aspecto | Detalle |
|---------|---------|
| **Lanzamiento** | Noviembre 2024 |
| **Tipo** | LTS (Long Term Support) |
| **Soporte hasta** | Noviembre 2026 |
| **Madurez** | 1 año (a nov 2025) |
| **Uso enterprise** | ✅ Recomendado para producción |

---

## Principales mejoras vs 3.2

### 1. Soporte mejorado para Virtual Threads (Java 21+)

Aunque usamos Java 17 en este proyecto, Spring Boot 3.4 está preparado para:

```java
// Cuando migres a Java 21+
@Bean
@ConditionalOnProperty(name = "spring.threads.virtual.enabled", havingValue = "true")
public TomcatProtocolHandlerCustomizer<?> protocolHandlerVirtualThreadExecutorCustomizer() {
    return protocolHandler -> protocolHandler.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
}
```

### 2. Hibernate 6.6 (vs 6.4 en Spring Boot 3.2)

Mejoras en:
- Performance en queries complejos
- Mejor soporte para DTOs
- Optimizaciones en el cache de segundo nivel

### 3. Observability mejorada

Mejor integración con Micrometer:

```java
@Observed(name = "user.creation")
public UserResponse create(CreateUserRequest request) {
    // Automáticamente genera métricas y traces
}
```

### 4. Testcontainers integrado

```java
@SpringBootTest
@ServiceConnection  // Nuevo en 3.4
class UserServiceIT {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");
    
    // No necesitas configurar datasource manualmente
}
```

### 5. Actualizaciones de dependencias

| Dependencia | Spring Boot 3.2 | Spring Boot 3.4 |
|-------------|-----------------|-----------------|
| Spring Framework | 6.1.x | 6.2.x |
| Hibernate | 6.4.x | 6.6.x |
| Jackson | 2.15.x | 2.18.x |
| Tomcat | 10.1.x | 10.1.x |

---

## Cambios que NO afectan a este proyecto

Como usamos Java 17, estas features no están disponibles:

| Feature | Requiere |
|---------|----------|
| Virtual Threads | Java 21+ |
| Pattern Matching for switch mejorado | Java 21+ |
| Record Patterns | Java 21+ |
| Sequenced Collections | Java 21+ |

---

## Migración de 3.2 a 3.4

### Cambios necesarios: NINGUNO

Spring Boot 3.4 es **100% compatible** con código de 3.2. Solo necesitas:

```xml
<!-- En pom.xml, cambiar: -->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.4.12</version>  <!-- Era 3.2.x -->
</parent>
```

### Deprecated/Removals

No hay deprecations significativas que afecten este proyecto.

---

## Configuraciones nuevas (opcionales)

### 1. Estructuración de properties mejorada

```yaml
# Ahora puedes organizar mejor
spring:
  application:
    name: game-tierlist
    
  datasource:
    url: jdbc:h2:mem:gametierlist
    
  jpa:
    hibernate:
      ddl-auto: create-drop
    properties:
      hibernate:
        format_sql: true
```

### 2. Logging estructurado

```yaml
# Logs en formato JSON (opcional)
logging:
  structured:
    format: json
    ecs:
      enabled: true
```

---

## Testing mejorado

### @ServiceConnection (nuevo)

Simplifica tests de integración:

```java
@SpringBootTest
class GameControllerIT {
    
    @Container
    @ServiceConnection  // Nuevo - conecta automáticamente
    static PostgreSQLContainer<?> postgres = 
        new PostgreSQLContainer<>("postgres:16");
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    // Ya no necesitas configurar datasource manualmente
}
```

### RestClient mejorado

```java
// Alternativa moderna a RestTemplate
@Bean
RestClient restClient(RestClient.Builder builder) {
    return builder
        .baseUrl("http://localhost:8080")
        .build();
}
```

---

## Performance

### Mejoras automáticas

Spring Boot 3.4 incluye:
- ✅ Startup ~5-10% más rápido
- ✅ Menor uso de memoria en contexto pequeño
- ✅ Optimizaciones en auto-configuración

No necesitas hacer nada, son automáticas.

---

## Recomendaciones para este proyecto

### ✅ Usar (incluido en el proyecto)

- Spring Boot 3.4.12
- Java 17
- H2 para desarrollo
- springdoc-openapi 2.3.0+

### 🟡 Considerar para producción

- PostgreSQL en lugar de H2
- Testcontainers para tests de integración
- Micrometer para observability

### ❌ No necesario ahora

- Virtual Threads (requiere Java 21)
- GraalVM Native Image (complejidad extra)
- Redis/cache distribuido (overkill para el alcance)

---

## Referencias

- [Spring Boot 3.4 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.4-Release-Notes)
- [Spring Framework 6.2 What's New](https://docs.spring.io/spring-framework/reference/6.2/whatsnew.html)
- [Hibernate 6.6 Migration Guide](https://docs.jboss.org/hibernate/orm/6.6/migration-guide/migration-guide.html)

---

## Resumen

| Aspecto | Conclusión |
|---------|------------|
| **¿Vale la pena 3.4 vs 3.2?** | ✅ Sí - mejor performance y soporte LTS |
| **¿Requiere cambios?** | ❌ No - compatible 100% |
| **¿Para aprendizaje?** | ✅ Perfecto - aprenderás la versión actual |
| **¿Para empresa?** | ✅ Recomendado - LTS con 2 años de soporte |
