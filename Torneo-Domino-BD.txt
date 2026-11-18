/* ============================================================
   CASO 2: Convocatoria Torneo de Dominó
   Script adaptado para dbfiddle.uk (SQL Server)
   Incluye: Tablas, Vistas, Procedimiento, Función e Índices
   ============================================================ */

-- ===================== TABLAS =====================

-- Tabla de Categorías (niveles de habilidad)
CREATE TABLE Categorias (
    id_categoria    INT IDENTITY(1,1) PRIMARY KEY,          -- Índice clustered (PK)
    nombre          NVARCHAR(50) NOT NULL UNIQUE,
    descripcion     NVARCHAR(200),
    edad_minima     INT,
    edad_maxima     INT
);

-- Tabla de Jugadores
CREATE TABLE Jugadores (
    id_jugador      INT IDENTITY(1,1) PRIMARY KEY,          -- Índice clustered
    nombre          NVARCHAR(50) NOT NULL,
    apellido        NVARCHAR(50) NOT NULL,
    email           NVARCHAR(100) NOT NULL UNIQUE,
    telefono        NVARCHAR(20),
    fecha_nacimiento DATE NOT NULL,
    nivel_habilidad NVARCHAR(30) DEFAULT 'Principiante',
    fecha_registro  DATETIME2 DEFAULT GETDATE()
);

-- Tabla de Inscripciones
CREATE TABLE Inscripciones (
    id_inscripcion  INT IDENTITY(1,1) PRIMARY KEY,
    id_jugador      INT NOT NULL,
    id_categoria    INT NOT NULL,
    fecha_inscripcion DATETIME2 DEFAULT GETDATE(),
    confirmado      BIT NOT NULL DEFAULT 0,                 -- 0 = pendiente, 1 = confirmado
    observaciones   NVARCHAR(200),
    CONSTRAINT FK_Inscripciones_Jugadores FOREIGN KEY (id_jugador) REFERENCES Jugadores(id_jugador),
    CONSTRAINT FK_Inscripciones_Categorias FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria)
);

-- Tabla de Partidas
CREATE TABLE Partidas (
    id_partida      INT IDENTITY(1,1) PRIMARY KEY,
    id_categoria    INT NOT NULL,
    fecha_hora      DATETIME2 NOT NULL,
    mesa            NVARCHAR(20),
    estado          NVARCHAR(20) DEFAULT 'Programada',     -- Programada, En curso, Finalizada
    CONSTRAINT FK_Partidas_Categorias FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria)
);

-- Tabla intermedia (relación N:M entre Partidas y Jugadores)
CREATE TABLE Participacion_Partida (
    id_participacion INT IDENTITY(1,1) PRIMARY KEY,
    id_partida      INT NOT NULL,
    id_jugador      INT NOT NULL,
    posicion        INT,                                    -- 1º, 2º, etc.
    puntos          INT DEFAULT 0,
    CONSTRAINT FK_Participacion_Partida FOREIGN KEY (id_partida) REFERENCES Partidas(id_partida),
    CONSTRAINT FK_Participacion_Jugador FOREIGN KEY (id_jugador) REFERENCES Jugadores(id_jugador)
);

-- ===================== ÍNDICES =====================

-- Índice non-clustered en email (búsquedas frecuentes)
CREATE NONCLUSTERED INDEX IX_Jugadores_Email ON Jugadores(email);

-- Índice non-clustered en fecha de inscripción
CREATE NONCLUSTERED INDEX IX_Inscripciones_Fecha ON Inscripciones(fecha_inscripcion);

-- ===================== DATOS DE EJEMPLO =====================

INSERT INTO Categorias (nombre, descripcion, edad_minima, edad_maxima)
VALUES 
('Principiante', 'Jugadores con poca experiencia', 12, 99),
('Intermedio', 'Jugadores con experiencia media', 16, 99),
('Avanzado', 'Jugadores experimentados', 18, 99);

INSERT INTO Jugadores (nombre, apellido, email, telefono, fecha_nacimiento, nivel_habilidad)
VALUES 
('Carlos', 'Ruiz', 'carlos.ruiz@email.com', '611223344', '1990-05-12', 'Intermedio'),
('Laura', 'Sánchez', 'laura.sanchez@email.com', '622334455', '1985-08-22', 'Avanzado'),
('Miguel', 'Torres', 'miguel.torres@email.com', '633445566', '2000-03-15', 'Principiante'),
('Elena', 'Moreno', 'elena.moreno@email.com', '644556677', '1995-11-30', 'Intermedio');

INSERT INTO Inscripciones (id_jugador, id_categoria, confirmado)
VALUES 
(1, 2, 1),  -- Carlos confirmado en Intermedio
(2, 3, 1),  -- Laura confirmada en Avanzado
(3, 1, 0),  -- Miguel pendiente
(4, 2, 1);  -- Elena confirmada en Intermedio

INSERT INTO Partidas (id_categoria, fecha_hora, mesa, estado)
VALUES 
(2, '2026-12-05 10:00:00', 'Mesa 1', 'Programada'),
(3, '2026-12-05 12:00:00', 'Mesa 3', 'Programada');

INSERT INTO Participacion_Partida (id_partida, id_jugador)
VALUES (1, 1), (1, 4), (2, 2);

-- ===================== VISTA =====================

CREATE VIEW Vista_Participantes_Confirmados AS
SELECT 
    j.id_jugador,
    j.nombre + ' ' + j.apellido AS nombre_completo,
    j.email,
    c.nombre AS categoria,
    i.fecha_inscripcion,
    i.confirmado
FROM Inscripciones i
INNER JOIN Jugadores j ON i.id_jugador = j.id_jugador
INNER JOIN Categorias c ON i.id_categoria = c.id_categoria
WHERE i.confirmado = 1;

-- ===================== FUNCIÓN =====================

CREATE FUNCTION ContarParticipantesConfirmados()
RETURNS INT
AS
BEGIN
    DECLARE @Total INT;
    SELECT @Total = COUNT(*) 
    FROM Inscripciones 
    WHERE confirmado = 1;
    RETURN @Total;
END;

-- ===================== PROCEDIMIENTO ALMACENADO =====================

CREATE PROCEDURE ConfirmarInscripcion
    @id_inscripcion INT
AS
BEGIN
    UPDATE Inscripciones
    SET confirmado = 1
    WHERE id_inscripcion = @id_inscripcion;
    
    SELECT 'Inscripción confirmada correctamente' AS Mensaje;
END;

-- ===================== CONSULTAS DE VERIFICACIÓN =====================

-- Ver todas las tablas
SELECT * FROM Categorias;
SELECT * FROM Jugadores;
SELECT * FROM Inscripciones;
SELECT * FROM Partidas;
SELECT * FROM Participacion_Partida;

-- Probar la Vista
SELECT * FROM Vista_Participantes_Confirmados;

-- Probar la Función
SELECT dbo.ContarParticipantesConfirmados() AS Total_Confirmados;

-- Probar el Procedimiento (confirma la inscripción del jugador pendiente)
EXEC ConfirmarInscripcion @id_inscripcion = 3;

-- Ver resultado después de confirmar
SELECT * FROM Vista_Participantes_Confirmados;