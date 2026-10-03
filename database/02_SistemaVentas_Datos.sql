/*
    Proyecto: SistemaVentasAPI
    Autor: Daniel Castro
    Archivo: 02_SistemaVentas_Datos.sql

    Carga inicial:
    - 5 clientes.
    - 4 categorias.
    - 10 productos.
    - 3 ventas.
    - 8 detalles de venta.

    Los datos son ficticios.
    Requiere las cinco tablas vacias.
*/

USE SistemaVentas;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM dbo.CLIENTES)
       OR EXISTS (SELECT 1 FROM dbo.CATEGORIAS)
       OR EXISTS (SELECT 1 FROM dbo.PRODUCTOS)
       OR EXISTS (SELECT 1 FROM dbo.VENTAS)
       OR EXISTS (SELECT 1 FROM dbo.DETALLE_VENTAS)
    BEGIN
        THROW 50002,
            N'Las tablas deben estar vacias para ejecutar la carga inicial.',
            1;
    END;

    -- 1. Clientes

    INSERT INTO dbo.CLIENTES (Nombre, Telefono, Correo)
    VALUES
        (N'Ana López', '6641000001', N'ana@example.com'),
        (N'Luis Martínez', '6641000002', N'luis@example.com'),
        (N'María García', '6641000003', N'maria@example.com'),
        (N'Carlos Hernández', '6641000004', N'carlos@example.com'),
        (N'Sofía Pérez', NULL, N'sofia@example.com');

    -- 2. Categorias

    INSERT INTO dbo.CATEGORIAS (Nombre, Descripcion)
    VALUES
        (N'Bebidas', N'Bebidas envasadas'),
        (N'Botanas', N'Productos para consumo entre comidas'),
        (N'Abarrotes', N'Alimentos de despensa'),
        (N'Limpieza', N'Productos de limpieza para el hogar');

    DECLARE @IdBebidas INT;
    DECLARE @IdBotanas INT;
    DECLARE @IdAbarrotes INT;
    DECLARE @IdLimpieza INT;

    SELECT @IdBebidas = IdCategoria
    FROM dbo.CATEGORIAS
    WHERE Nombre = N'Bebidas';

    SELECT @IdBotanas = IdCategoria
    FROM dbo.CATEGORIAS
    WHERE Nombre = N'Botanas';

    SELECT @IdAbarrotes = IdCategoria
    FROM dbo.CATEGORIAS
    WHERE Nombre = N'Abarrotes';

    SELECT @IdLimpieza = IdCategoria
    FROM dbo.CATEGORIAS
    WHERE Nombre = N'Limpieza';

    -- 3. Productos con existencias iniciales

    INSERT INTO dbo.PRODUCTOS
        (IdCategoria, Nombre, Descripcion, Precio, Existencia)
    VALUES
        (@IdBebidas, N'Agua natural 1 L',
         N'Botella de agua natural', 18.00, 50),

        (@IdBebidas, N'Refresco 600 ml',
         N'Botella de refresco', 25.00, 40),

        (@IdBebidas, N'Jugo de naranja 1 L',
         N'Envase de jugo de naranja', 32.50, 30),

        (@IdBotanas, N'Papas fritas 150 g',
         N'Bolsa de papas fritas', 30.00, 35),

        (@IdBotanas, N'Galletas 200 g',
         N'Paquete de galletas', 22.00, 45),

        (@IdAbarrotes, N'Arroz 1 kg',
         N'Bolsa de arroz', 38.00, 25),

        (@IdAbarrotes, N'Frijol 1 kg',
         N'Bolsa de frijol', 42.00, 25),

        (@IdAbarrotes, N'Aceite vegetal 1 L',
         N'Botella de aceite vegetal', 48.50, 20),

        (@IdLimpieza, N'Detergente 1 kg',
         N'Bolsa de detergente en polvo', 65.00, 20),

        (@IdLimpieza, N'Cloro 1 L',
         N'Botella de cloro', 20.00, 30);

    /*
        Capturamos los identificadores reales.
        No suponemos que IDENTITY empieza en 1.
    */

    DECLARE @IdAna INT;
    DECLARE @IdLuis INT;
    DECLARE @IdMaria INT;

    SELECT @IdAna = IdCliente
    FROM dbo.CLIENTES
    WHERE Correo = N'ana@example.com';

    SELECT @IdLuis = IdCliente
    FROM dbo.CLIENTES
    WHERE Correo = N'luis@example.com';

    SELECT @IdMaria = IdCliente
    FROM dbo.CLIENTES
    WHERE Correo = N'maria@example.com';

    -- 4. Encabezados de ventas

    DECLARE @IdVentaAna INT;
    DECLARE @IdVentaLuis INT;
    DECLARE @IdVentaMaria INT;

    INSERT INTO dbo.VENTAS (IdCliente, Total)
    VALUES (@IdAna, 0);

    SET @IdVentaAna = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.VENTAS (IdCliente, Total)
    VALUES (@IdLuis, 0);

    SET @IdVentaLuis = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.VENTAS (IdCliente, Total)
    VALUES (@IdMaria, 0);

    SET @IdVentaMaria = CONVERT(INT, SCOPE_IDENTITY());

    -- 5. Detalles: precios obtenidos del catalogo de productos

    INSERT INTO dbo.DETALLE_VENTAS
        (IdVenta, IdProducto, Cantidad, PrecioUnitario, Subtotal)
    SELECT
        pedidos.IdVenta,
        productos.IdProducto,
        pedidos.Cantidad,
        productos.Precio,
        pedidos.Cantidad * productos.Precio
    FROM
    (
        VALUES
            (@IdVentaAna, N'Agua natural 1 L', 2),
            (@IdVentaAna, N'Papas fritas 150 g', 1),

            (@IdVentaLuis, N'Arroz 1 kg', 2),
            (@IdVentaLuis, N'Frijol 1 kg', 1),
            (@IdVentaLuis, N'Aceite vegetal 1 L', 1),

            (@IdVentaMaria, N'Detergente 1 kg', 1),
            (@IdVentaMaria, N'Cloro 1 L', 2),
            (@IdVentaMaria, N'Galletas 200 g', 1)
    ) AS pedidos (IdVenta, NombreProducto, Cantidad)
    INNER JOIN dbo.PRODUCTOS AS productos
        ON productos.Nombre = pedidos.NombreProducto;

    IF (SELECT COUNT(*) FROM dbo.DETALLE_VENTAS) <> 8
    BEGIN
        THROW 50003,
            N'No se crearon los ocho detalles esperados.',
            1;
    END;

    -- 6. Totales calculados a partir de los detalles

    UPDATE ventas
    SET ventas.Total = importes.TotalCalculado
    FROM dbo.VENTAS AS ventas
    INNER JOIN
    (
        SELECT
            IdVenta,
            SUM(Subtotal) AS TotalCalculado
        FROM dbo.DETALLE_VENTAS
        GROUP BY IdVenta
    ) AS importes
        ON importes.IdVenta = ventas.IdVenta;

    -- 7. Comprobacion de inventario antes del descuento

    IF EXISTS
    (
        SELECT 1
        FROM dbo.PRODUCTOS AS productos
        INNER JOIN
        (
            SELECT
                IdProducto,
                SUM(Cantidad) AS CantidadVendida
            FROM dbo.DETALLE_VENTAS
            GROUP BY IdProducto
        ) AS vendidos
            ON vendidos.IdProducto = productos.IdProducto
        WHERE vendidos.CantidadVendida > productos.Existencia
    )
    BEGIN
        THROW 50004,
            N'La existencia es insuficiente para la carga de ventas.',
            1;
    END;

    -- 8. Descuento de existencias

    UPDATE productos
    SET productos.Existencia =
        productos.Existencia - vendidos.CantidadVendida
    FROM dbo.PRODUCTOS AS productos
    INNER JOIN
    (
        SELECT
            IdProducto,
            SUM(Cantidad) AS CantidadVendida
        FROM dbo.DETALLE_VENTAS
        GROUP BY IdProducto
    ) AS vendidos
        ON vendidos.IdProducto = productos.IdProducto;

    COMMIT TRANSACTION;

    PRINT N'Datos iniciales cargados correctamente.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO