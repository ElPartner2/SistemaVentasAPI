/*
    Proyecto: SistemaVentasAPI
    Autor: Daniel Castro
    Archivo: 01_SistemaVentas_DDL.sql

    Crea la base de datos y sus cinco tablas.
    No elimina bases de datos ni tablas existentes.
*/

USE master;
GO

IF DB_ID(N'SistemaVentas') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE SistemaVentas;');
END;
GO

USE SistemaVentas;
GO

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Impide recrear parcialmente una estructura existente.
    IF OBJECT_ID(N'dbo.CLIENTES', N'U') IS NOT NULL
       OR OBJECT_ID(N'dbo.CATEGORIAS', N'U') IS NOT NULL
       OR OBJECT_ID(N'dbo.PRODUCTOS', N'U') IS NOT NULL
       OR OBJECT_ID(N'dbo.VENTAS', N'U') IS NOT NULL
       OR OBJECT_ID(N'dbo.DETALLE_VENTAS', N'U') IS NOT NULL
    BEGIN
        THROW 50001,
            N'Ya existe alguna tabla del sistema. Revise la estructura antes de ejecutar nuevamente este script.',
            1;
    END;

    CREATE TABLE dbo.CLIENTES
    (
        IdCliente INT IDENTITY(1,1) NOT NULL,
        Nombre NVARCHAR(100) NOT NULL,
        Telefono VARCHAR(15) NULL,
        Correo NVARCHAR(150) NOT NULL,
        Activo BIT NOT NULL
            CONSTRAINT DF_CLIENTES_Activo DEFAULT (1),
        FechaRegistro DATETIME2 NOT NULL
            CONSTRAINT DF_CLIENTES_FechaRegistro
            DEFAULT (SYSDATETIME()),

        CONSTRAINT PK_CLIENTES
            PRIMARY KEY (IdCliente),

        CONSTRAINT UQ_CLIENTES_Correo
            UNIQUE (Correo)
    );

    CREATE TABLE dbo.CATEGORIAS
    (
        IdCategoria INT IDENTITY(1,1) NOT NULL,
        Nombre NVARCHAR(80) NOT NULL,
        Descripcion NVARCHAR(250) NULL,
        Activo BIT NOT NULL
            CONSTRAINT DF_CATEGORIAS_Activo DEFAULT (1),

        CONSTRAINT PK_CATEGORIAS
            PRIMARY KEY (IdCategoria),

        CONSTRAINT UQ_CATEGORIAS_Nombre
            UNIQUE (Nombre)
    );

    CREATE TABLE dbo.PRODUCTOS
    (
        IdProducto INT IDENTITY(1,1) NOT NULL,
        IdCategoria INT NOT NULL,
        Nombre NVARCHAR(100) NOT NULL,
        Descripcion NVARCHAR(250) NULL,
        Precio DECIMAL(10,2) NOT NULL,
        Existencia INT NOT NULL,
        Activo BIT NOT NULL
            CONSTRAINT DF_PRODUCTOS_Activo DEFAULT (1),

        CONSTRAINT PK_PRODUCTOS
            PRIMARY KEY (IdProducto),

        CONSTRAINT FK_PRODUCTOS_CATEGORIAS
            FOREIGN KEY (IdCategoria)
            REFERENCES dbo.CATEGORIAS (IdCategoria),

        CONSTRAINT CK_PRODUCTOS_Precio
            CHECK (Precio > 0),

        CONSTRAINT CK_PRODUCTOS_Existencia
            CHECK (Existencia >= 0)
    );

    CREATE TABLE dbo.VENTAS
    (
        IdVenta INT IDENTITY(1,1) NOT NULL,
        IdCliente INT NOT NULL,
        FechaVenta DATETIME2 NOT NULL
            CONSTRAINT DF_VENTAS_FechaVenta
            DEFAULT (SYSDATETIME()),
        Total DECIMAL(12,2) NOT NULL,
        Estado NVARCHAR(20) NOT NULL
            CONSTRAINT DF_VENTAS_Estado DEFAULT (N'Registrada'),

        CONSTRAINT PK_VENTAS
            PRIMARY KEY (IdVenta),

        CONSTRAINT FK_VENTAS_CLIENTES
            FOREIGN KEY (IdCliente)
            REFERENCES dbo.CLIENTES (IdCliente),

        CONSTRAINT CK_VENTAS_Total
            CHECK (Total >= 0),

        CONSTRAINT CK_VENTAS_Estado
            CHECK (Estado IN (N'Registrada', N'Cancelada'))
    );

    CREATE TABLE dbo.DETALLE_VENTAS
    (
        IdDetalleVenta INT IDENTITY(1,1) NOT NULL,
        IdVenta INT NOT NULL,
        IdProducto INT NOT NULL,
        Cantidad INT NOT NULL,
        PrecioUnitario DECIMAL(10,2) NOT NULL,
        Subtotal DECIMAL(12,2) NOT NULL,

        CONSTRAINT PK_DETALLE_VENTAS
            PRIMARY KEY (IdDetalleVenta),

        CONSTRAINT FK_DETALLE_VENTAS_VENTAS
            FOREIGN KEY (IdVenta)
            REFERENCES dbo.VENTAS (IdVenta),

        CONSTRAINT FK_DETALLE_VENTAS_PRODUCTOS
            FOREIGN KEY (IdProducto)
            REFERENCES dbo.PRODUCTOS (IdProducto),

        CONSTRAINT CK_DETALLE_VENTAS_Cantidad
            CHECK (Cantidad > 0),

        CONSTRAINT CK_DETALLE_VENTAS_PrecioUnitario
            CHECK (PrecioUnitario > 0),

        CONSTRAINT CK_DETALLE_VENTAS_Subtotal
            CHECK (Subtotal >= 0)
    );

    COMMIT TRANSACTION;

    PRINT N'Base de datos SistemaVentas y cinco tablas creadas correctamente.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO