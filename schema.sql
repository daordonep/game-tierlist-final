-- ============================================
-- GAME TIERLIST - Schema de Base de Datos
-- ============================================
-- Compatible con H2 Database
-- Spring Boot 3 + Java 17
-- ============================================

-- Nota: Con spring.jpa.hibernate.ddl-auto=create-drop,
-- JPA genera las tablas automáticamente.
-- Este archivo es de referencia y para data.sql.

-- ============================================
-- TABLA: CATEGORY (Catálogo de categorías)
-- ============================================
CREATE TABLE IF NOT EXISTS category (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: USERS (Usuarios de la aplicación)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(150) UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: GAME (Catálogo de juegos)
-- ============================================
CREATE TABLE IF NOT EXISTS game (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    plataforma VARCHAR(50) NOT NULL,
    descripcion VARCHAR(500),
    anio_lanzamiento INT NOT NULL,
    category_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_game_nombre_plataforma UNIQUE (nombre, plataforma),
    CONSTRAINT fk_game_category FOREIGN KEY (category_id) REFERENCES category(id)
);

-- ============================================
-- TABLA: TIERLIST (Tierlists por usuario y año)
-- ============================================
CREATE TABLE IF NOT EXISTS tierlist (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    anio INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_tierlist_user_anio UNIQUE (user_id, anio),
    CONSTRAINT fk_tierlist_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================
-- TABLA: TIERLIST_ENTRY (Juegos en tierlists)
-- ============================================
-- Incluye campos denormalizados para optimizar consultas
CREATE TABLE IF NOT EXISTS tierlist_entry (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tierlist_id BIGINT NOT NULL,
    game_id BIGINT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 10),
    anio_jugado INT NOT NULL,
    
    -- Campos denormalizados (copiados del juego)
    game_nombre VARCHAR(100) NOT NULL,
    game_plataforma VARCHAR(50) NOT NULL,
    game_categoria VARCHAR(50) NOT NULL,
    game_descripcion VARCHAR(500),
    game_anio_lanzamiento INT NOT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_entry_tierlist_game UNIQUE (tierlist_id, game_id),
    CONSTRAINT fk_entry_tierlist FOREIGN KEY (tierlist_id) REFERENCES tierlist(id) ON DELETE CASCADE,
    CONSTRAINT fk_entry_game FOREIGN KEY (game_id) REFERENCES game(id)
);

-- ============================================
-- ÍNDICES para optimizar consultas
-- ============================================
CREATE INDEX IF NOT EXISTS idx_game_category ON game(category_id);
CREATE INDEX IF NOT EXISTS idx_tierlist_user ON tierlist(user_id);
CREATE INDEX IF NOT EXISTS idx_entry_tierlist ON tierlist_entry(tierlist_id);
CREATE INDEX IF NOT EXISTS idx_entry_game ON tierlist_entry(game_id);
CREATE INDEX IF NOT EXISTS idx_entry_game_nombre ON tierlist_entry(game_nombre);
CREATE INDEX IF NOT EXISTS idx_entry_game_categoria ON tierlist_entry(game_categoria);
CREATE INDEX IF NOT EXISTS idx_entry_rating ON tierlist_entry(rating);
