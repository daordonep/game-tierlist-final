-- ============================================
-- GAME TIERLIST - Datos Iniciales
-- ============================================
-- Ejecutar después de que JPA cree las tablas
-- spring.jpa.defer-datasource-initialization=true
-- ============================================

-- ============================================
-- CATEGORÍAS (12 categorías de juegos)
-- ============================================
INSERT INTO category (nombre, descripcion, created_at, updated_at) VALUES
('Acción', 'Juegos de acción y combate', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Aventura', 'Juegos de exploración y narrativa', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('RPG', 'Juegos de rol con progresión de personaje', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Shooter', 'Juegos de disparos en primera o tercera persona', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Deportes', 'Simuladores deportivos', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Carreras', 'Juegos de conducción y carreras', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Puzzle', 'Juegos de rompecabezas y lógica', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Plataformas', 'Juegos de saltar y explorar niveles', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Estrategia', 'Juegos de planificación táctica', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Simulación', 'Simuladores de vida y gestión', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Terror', 'Juegos de horror y supervivencia', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Indie', 'Juegos independientes creativos', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- USUARIOS DE EJEMPLO (para testing)
-- ============================================
INSERT INTO users (nombre, email, created_at, updated_at) VALUES
('Carlos', 'carlos@example.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('María', 'maria@example.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Pedro', 'pedro@example.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Ana', 'ana@example.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- JUEGOS DE EJEMPLO
-- ============================================
-- Nota: category_id corresponde al orden de inserción arriba
-- 1=Acción, 2=Aventura, 3=RPG, 4=Shooter, 5=Deportes, 6=Carreras,
-- 7=Puzzle, 8=Plataformas, 9=Estrategia, 10=Simulación, 11=Terror, 12=Indie

INSERT INTO game (nombre, plataforma, descripcion, anio_lanzamiento, category_id, created_at, updated_at) VALUES
-- RPGs
('Elden Ring', 'PC', 'RPG de acción en mundo abierto creado por FromSoftware', 2022, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Elden Ring', 'PlayStation 5', 'RPG de acción en mundo abierto creado por FromSoftware', 2022, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Baldur''s Gate 3', 'PC', 'RPG basado en D&D con combate por turnos', 2023, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Final Fantasy XVI', 'PlayStation 5', 'Acción RPG con combate en tiempo real', 2023, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Persona 5 Royal', 'PC', 'JRPG con elementos de simulación social', 2022, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Aventura
('The Legend of Zelda: Tears of the Kingdom', 'Nintendo Switch', 'Secuela de Breath of the Wild con nuevas mecánicas', 2023, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('God of War Ragnarök', 'PlayStation 5', 'Continuación de la saga nórdica de Kratos', 2022, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Horizon Forbidden West', 'PlayStation 5', 'Aventura de acción en mundo post-apocalíptico', 2022, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Acción
('Hades', 'PC', 'Roguelike de acción con narrativa mitológica griega', 2020, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Hades', 'Nintendo Switch', 'Roguelike de acción con narrativa mitológica griega', 2020, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Dead Cells', 'PC', 'Metroidvania roguelike con combate fluido', 2018, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Plataformas
('Hollow Knight', 'PC', 'Metroidvania con estética oscura y desafiante', 2017, 8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Celeste', 'Nintendo Switch', 'Plataformas de precisión con historia emotiva', 2018, 8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Super Mario Odyssey', 'Nintendo Switch', 'Aventura de plataformas en 3D', 2017, 8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Puzzle
('Portal 2', 'PC', 'Puzzle en primera persona con portales', 2011, 7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('The Witness', 'PC', 'Puzzles en una isla misteriosa', 2016, 7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Deportes
('FIFA 24', 'PlayStation 5', 'Simulador de fútbol anual', 2023, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('NBA 2K24', 'PC', 'Simulador de baloncesto', 2023, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Terror
('Resident Evil 4 Remake', 'PC', 'Remake del clásico survival horror', 2023, 11, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Alan Wake 2', 'PC', 'Horror psicológico con narrativa compleja', 2023, 11, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Simulación
('Stardew Valley', 'PC', 'Simulador de granja con elementos de RPG', 2016, 10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Cities: Skylines II', 'PC', 'Simulador de construcción de ciudades', 2023, 10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Estrategia
('Civilization VI', 'PC', 'Estrategia por turnos histórica', 2016, 9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('XCOM 2', 'PC', 'Estrategia táctica contra alienígenas', 2016, 9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Indie
('Disco Elysium', 'PC', 'RPG narrativo sin combate tradicional', 2019, 12, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Outer Wilds', 'PC', 'Exploración espacial con bucle temporal', 2019, 12, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Inscryption', 'PC', 'Deckbuilder con elementos de horror', 2021, 12, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- TIERLISTS DE EJEMPLO
-- ============================================
INSERT INTO tierlist (user_id, anio, created_at, updated_at) VALUES
(1, 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),  -- Carlos 2023
(1, 2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),  -- Carlos 2024
(2, 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),  -- María 2023
(3, 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);  -- Pedro 2023

-- ============================================
-- ENTRIES DE EJEMPLO (con campos denormalizados)
-- ============================================
-- Tierlist 1: Carlos 2023
INSERT INTO tierlist_entry (tierlist_id, game_id, rating, anio_jugado, game_nombre, game_plataforma, game_categoria, game_descripcion, game_anio_lanzamiento, created_at, updated_at) VALUES
(1, 1, 10, 2023, 'Elden Ring', 'PC', 'RPG', 'RPG de acción en mundo abierto creado por FromSoftware', 2022, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 3, 10, 2023, 'Baldur''s Gate 3', 'PC', 'RPG', 'RPG basado en D&D con combate por turnos', 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 6, 9, 2023, 'The Legend of Zelda: Tears of the Kingdom', 'Nintendo Switch', 'Aventura', 'Secuela de Breath of the Wild con nuevas mecánicas', 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 19, 8, 2023, 'Resident Evil 4 Remake', 'PC', 'Terror', 'Remake del clásico survival horror', 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Tierlist 2: Carlos 2024
INSERT INTO tierlist_entry (tierlist_id, game_id, rating, anio_jugado, game_nombre, game_plataforma, game_categoria, game_descripcion, game_anio_lanzamiento, created_at, updated_at) VALUES
(2, 20, 9, 2024, 'Alan Wake 2', 'PC', 'Terror', 'Horror psicológico con narrativa compleja', 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 25, 10, 2024, 'Disco Elysium', 'PC', 'Indie', 'RPG narrativo sin combate tradicional', 2019, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Tierlist 3: María 2023
INSERT INTO tierlist_entry (tierlist_id, game_id, rating, anio_jugado, game_nombre, game_plataforma, game_categoria, game_descripcion, game_anio_lanzamiento, created_at, updated_at) VALUES
(3, 1, 9, 2023, 'Elden Ring', 'PC', 'RPG', 'RPG de acción en mundo abierto creado por FromSoftware', 2022, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 3, 10, 2023, 'Baldur''s Gate 3', 'PC', 'RPG', 'RPG basado en D&D con combate por turnos', 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 9, 8, 2023, 'Hades', 'PC', 'Acción', 'Roguelike de acción con narrativa mitológica griega', 2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 12, 9, 2023, 'Hollow Knight', 'PC', 'Plataformas', 'Metroidvania con estética oscura y desafiante', 2017, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Tierlist 4: Pedro 2023
INSERT INTO tierlist_entry (tierlist_id, game_id, rating, anio_jugado, game_nombre, game_plataforma, game_categoria, game_descripcion, game_anio_lanzamiento, created_at, updated_at) VALUES
(4, 1, 8, 2023, 'Elden Ring', 'PC', 'RPG', 'RPG de acción en mundo abierto creado por FromSoftware', 2022, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 3, 9, 2023, 'Baldur''s Gate 3', 'PC', 'RPG', 'RPG basado en D&D con combate por turnos', 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 17, 7, 2023, 'FIFA 24', 'PlayStation 5', 'Deportes', 'Simulador de fútbol anual', 2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 21, 9, 2023, 'Stardew Valley', 'PC', 'Simulación', 'Simulador de granja con elementos de RPG', 2016, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
