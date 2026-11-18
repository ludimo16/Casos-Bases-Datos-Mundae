/* ============================================================
   CASO: Bases de Datos en PyME - Retail
   Script adaptado para dbfiddle.uk (SQL Server)
   ============================================================ */

-- Tabla Clientes
CREATE TABLE Clientes (
    id_cliente      INT IDENTITY(1,1) PRIMARY KEY,
    nombre          NVARCHAR(50)  NOT NULL,
    apellido        NVARCHAR(50)  NOT NULL,
    email           NVARCHAR(100) UNIQUE,
    telefono        NVARCHAR(20),
    direccion       NVARCHAR(150),
    fecha_registro  DATETIME2 DEFAULT GETDATE(),
    activo          BIT DEFAULT 1
);

-- Tabla Productos
CREATE TABLE Productos (
    id_producto     INT IDENTITY(1,1) PRIMARY KEY,
    codigo_sku      NVARCHAR(30)  NOT NULL UNIQUE,
    nombre          NVARCHAR(100) NOT NULL,
    descripcion     NVARCHAR(300),
    precio_actual   DECIMAL(10,2) NOT NULL CHECK (precio_actual >= 0),
    stock           INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    categoria       NVARCHAR(50),
    activo          BIT DEFAULT 1
);

-- Tabla Ventas
CREATE TABLE Ventas (
    id_venta        INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente      INT NOT NULL,
    fecha_hora      DATETIME2 NOT NULL DEFAULT GETDATE(),
    total           DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_Ventas_Clientes FOREIGN KEY (id_cliente)
        REFERENCES Clientes(id_cliente)
);

-- Tabla Detalle_Ventas
CREATE TABLE Detalle_Ventas (
    id_detalle      INT IDENTITY(1,1) PRIMARY KEY,
    id_venta        INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Detalle_Ventas FOREIGN KEY (id_venta)
        REFERENCES Ventas(id_venta),
    CONSTRAINT FK_Detalle_Productos FOREIGN KEY (id_producto)
        REFERENCES Productos(id_producto)
);

-- Tabla Historial_Precios
CREATE TABLE Historial_Precios (
    id_historial    INT IDENTITY(1,1) PRIMARY KEY,
    id_producto     INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo    DECIMAL(10,2) NOT NULL,
    fecha_cambio    DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Historial_Productos FOREIGN KEY (id_producto)
        REFERENCES Productos(id_producto)
);

-- Datos de ejemplo
INSERT INTO Clientes (nombre, apellido, email, telefono, direccion)
VALUES 
('Ana', 'García', 'ana.garcia@email.com', '612345678', 'Calle Mayor 12, Madrid'),
('Luis', 'Martínez', 'luis.martinez@email.com', '698765432', 'Av. Libertad 45, Barcelona'),
('María', 'López', 'maria.lopez@email.com', '611223344', 'Plaza España 3, Valencia');

INSERT INTO Productos (codigo_sku, nombre, descripcion, precio_actual, stock, categoria)
VALUES 
('SKU-001', 'Camiseta Básica', 'Camiseta 100% algodón', 19.99, 50, 'Ropa'),
('SKU-002', 'Pantalón Vaquero', 'Pantalón slim fit', 49.90, 30, 'Ropa'),
('SKU-003', 'Zapatillas Running', 'Zapatillas deportivas ligeras', 79.50, 20, 'Calzado');

INSERT INTO Ventas (id_cliente, fecha_hora)
VALUES (1, GETDATE());

INSERT INTO Detalle_Ventas (id_venta, id_producto, cantidad, precio_unitario)
VALUES 
(1, 1, 2, 19.99),
(1, 3, 1, 79.50);

UPDATE Ventas
SET total = (SELECT SUM(cantidad * precio_unitario) FROM Detalle_Ventas WHERE id_venta = 1)
WHERE id_venta = 1;

INSERT INTO Historial_Precios (id_producto, precio_anterior, precio_nuevo)
VALUES (1, 19.99, 17.99);

UPDATE Productos SET precio_actual = 17.99 WHERE id_producto = 1;

-- Consultas de verificación
SELECT * FROM Clientes;

SELECT id_producto, codigo_sku, nombre, precio_actual, stock 
FROM Productos 
WHERE activo = 1;

SELECT 
    v.id_venta,
    c.nombre + ' ' + c.apellido AS cliente,
    v.fecha_hora,
    p.nombre AS producto,
    d.cantidad,
    d.precio_unitario,
    (d.cantidad * d.precio_unitario) AS subtotal,
    v.total
FROM Ventas v
INNER JOIN Clientes c ON v.id_cliente = c.id_cliente
INNER JOIN Detalle_Ventas d ON v.id_venta = d.id_venta
INNER JOIN Productos p ON d.id_producto = p.id_producto;

SELECT 
    p.nombre,
    h.precio_anterior,
    h.precio_nuevo,
    h.fecha_cambio
FROM Historial_Precios h
INNER JOIN Productos p ON h.id_producto = p.id_producto;