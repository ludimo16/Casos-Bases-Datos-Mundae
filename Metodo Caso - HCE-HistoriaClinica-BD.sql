/* ============================================================
   CASO 3: Sistema de Gestión de Historia Clínica Electrónica (HCE)
   Script adaptado para dbfiddle.uk (SQL Server)
   Incluye: Tablas, Vistas, Función, Procedimiento, Índices,
            JOINs, DML, Agregaciones y consultas avanzadas
   ============================================================ */

-- ===================== TABLAS =====================

CREATE TABLE Especialidades (
    id_especialidad INT IDENTITY(1,1) PRIMARY KEY,          -- Clustered
    nombre          NVARCHAR(80) NOT NULL UNIQUE,
    descripcion     NVARCHAR(200)
);

CREATE TABLE Medicos (
    id_medico       INT IDENTITY(1,1) PRIMARY KEY,          -- Clustered
    nombre          NVARCHAR(50) NOT NULL,
    apellido        NVARCHAR(50) NOT NULL,
    email           NVARCHAR(100) UNIQUE,
    telefono        NVARCHAR(20),
    id_especialidad INT NOT NULL,
    CONSTRAINT FK_Medicos_Especialidades FOREIGN KEY (id_especialidad) 
        REFERENCES Especialidades(id_especialidad)
);

CREATE TABLE Pacientes (
    id_paciente     INT IDENTITY(1,1) PRIMARY KEY,          -- Clustered
    nombre          NVARCHAR(50) NOT NULL,
    apellido        NVARCHAR(50) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero          CHAR(1) CHECK (genero IN ('M','F','O')),
    telefono        NVARCHAR(20),
    email           NVARCHAR(100),
    direccion       NVARCHAR(150),
    fecha_registro  DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Consultas (
    id_consulta     INT IDENTITY(1,1) PRIMARY KEY,
    id_paciente     INT NOT NULL,
    id_medico       INT NOT NULL,
    fecha_consulta  DATETIME2 NOT NULL,
    motivo          NVARCHAR(200),
    diagnostico     NVARCHAR(300),
    observaciones   NVARCHAR(300),
    CONSTRAINT FK_Consultas_Pacientes FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente),
    CONSTRAINT FK_Consultas_Medicos FOREIGN KEY (id_medico) REFERENCES Medicos(id_medico)
);

CREATE TABLE Tratamientos (
    id_tratamiento  INT IDENTITY(1,1) PRIMARY KEY,
    id_consulta     INT NOT NULL,
    medicamento     NVARCHAR(100) NOT NULL,
    dosis           NVARCHAR(50),
    duracion_dias   INT,
    CONSTRAINT FK_Tratamientos_Consultas FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta)
);

-- ===================== ÍNDICES =====================

-- Non-clustered para búsquedas frecuentes
CREATE NONCLUSTERED INDEX IX_Pacientes_Apellido ON Pacientes(apellido);
CREATE NONCLUSTERED INDEX IX_Consultas_Fecha ON Consultas(fecha_consulta);
CREATE NONCLUSTERED INDEX IX_Medicos_Especialidad ON Medicos(id_especialidad);

-- ===================== DATOS DE EJEMPLO =====================

INSERT INTO Especialidades (nombre, descripcion) VALUES
('Medicina General', 'Atención primaria'),
('Cardiología', 'Enfermedades del corazón'),
('Pediatría', 'Atención infantil');

INSERT INTO Medicos (nombre, apellido, email, telefono, id_especialidad) VALUES
('Ana', 'López', 'ana.lopez@hospital.com', '611111111', 1),
('Pedro', 'García', 'pedro.garcia@hospital.com', '622222222', 2),
('María', 'Fernández', 'maria.fernandez@hospital.com', '633333333', 3);

INSERT INTO Pacientes (nombre, apellido, fecha_nacimiento, genero, telefono, email) VALUES
('Juan', 'Pérez', '1985-03-15', 'M', '644444444', 'juan.perez@email.com'),
('Laura', 'Martínez', '1992-07-22', 'F', '655555555', 'laura.martinez@email.com'),
('Carlos', 'Ruiz', '2010-11-05', 'M', '666666666', 'carlos.ruiz@email.com'),
('Sofía', 'Gómez', '1978-01-30', 'F', '677777777', 'sofia.gomez@email.com');

INSERT INTO Consultas (id_paciente, id_medico, fecha_consulta, motivo, diagnostico) VALUES
(1, 1, '2026-10-10 09:30:00', 'Dolor de cabeza', 'Migraña'),
(2, 2, '2026-10-12 11:00:00', 'Dolor en el pecho', 'Hipertensión'),
(3, 3, '2026-10-15 16:00:00', 'Control rutinario', 'Sano'),
(1, 2, '2026-11-01 10:00:00', 'Seguimiento', 'Control de migraña'),
(4, 1, '2026-11-05 12:30:00', 'Fiebre', 'Infección viral');

INSERT INTO Tratamientos (id_consulta, medicamento, dosis, duracion_dias) VALUES
(1, 'Ibuprofeno', '400mg cada 8h', 5),
(2, 'Enalapril', '10mg diario', 30),
(5, 'Paracetamol', '500mg cada 6h', 3);

-- ===================== FUNCIÓN (Calcular Edad) =====================

CREATE FUNCTION dbo.CalcularEdad (@FechaNacimiento DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Edad INT;
    SET @Edad = DATEDIFF(YEAR, @FechaNacimiento, GETDATE());
    IF (MONTH(@FechaNacimiento) > MONTH(GETDATE())) 
       OR (MONTH(@FechaNacimiento) = MONTH(GETDATE()) AND DAY(@FechaNacimiento) > DAY(GETDATE()))
    BEGIN
        SET @Edad = @Edad - 1;
    END
    RETURN @Edad;
END;

-- ===================== VISTA =====================

CREATE VIEW Vista_Historial_Paciente AS
SELECT 
    p.id_paciente,
    p.nombre + ' ' + p.apellido AS paciente,
    dbo.CalcularEdad(p.fecha_nacimiento) AS edad,
    m.nombre + ' ' + m.apellido AS medico,
    e.nombre AS especialidad,
    c.fecha_consulta,
    c.motivo,
    c.diagnostico
FROM Consultas c
INNER JOIN Pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN Medicos m ON c.id_medico = m.id_medico
INNER JOIN Especialidades e ON m.id_especialidad = e.id_especialidad;

-- ===================== PROCEDIMIENTO ALMACENADO =====================

CREATE PROCEDURE RegistrarNuevaConsulta
    @id_paciente INT,
    @id_medico INT,
    @motivo NVARCHAR(200),
    @diagnostico NVARCHAR(300)
AS
BEGIN
    INSERT INTO Consultas (id_paciente, id_medico, fecha_consulta, motivo, diagnostico)
    VALUES (@id_paciente, @id_medico, GETDATE(), @motivo, @diagnostico);
    
    SELECT 'Consulta registrada correctamente' AS Mensaje;
END;

-- ===================== CONSULTAS DE DEMOSTRACIÓN =====================

-- 1. INNER JOIN + columnas calculadas + alias
SELECT 
    p.nombre + ' ' + p.apellido AS Paciente,
    dbo.CalcularEdad(p.fecha_nacimiento) AS Edad,
    c.fecha_consulta,
    c.diagnostico
FROM Pacientes p
INNER JOIN Consultas c ON p.id_paciente = c.id_paciente;

-- 2. LEFT JOIN (pacientes aunque no tengan consultas)
SELECT p.nombre, p.apellido, c.fecha_consulta
FROM Pacientes p
LEFT JOIN Consultas c ON p.id_paciente = c.id_paciente;

-- 3. Agregaciones (GROUP BY + HAVING)
SELECT 
    m.nombre + ' ' + m.apellido AS Medico,
    COUNT(c.id_consulta) AS Total_Consultas
FROM Medicos m
LEFT JOIN Consultas c ON m.id_medico = c.id_medico
GROUP BY m.nombre, m.apellido
HAVING COUNT(c.id_consulta) > 0
ORDER BY Total_Consultas DESC;

-- 4. Filtros avanzados (WHERE + LIKE + BETWEEN + ORDER BY)
SELECT nombre, apellido, fecha_nacimiento
FROM Pacientes
WHERE apellido LIKE 'P%'
  AND fecha_nacimiento BETWEEN '1980-01-01' AND '2000-12-31'
ORDER BY apellido;

-- 5. Función de edad
SELECT nombre, apellido, dbo.CalcularEdad(fecha_nacimiento) AS Edad
FROM Pacientes;

-- 6. Vista
SELECT * FROM Vista_Historial_Paciente;

-- 7. Ejecutar procedimiento
EXEC RegistrarNuevaConsulta 
    @id_paciente = 2, 
    @id_medico = 1, 
    @motivo = 'Control de presión', 
    @diagnostico = 'Estable';