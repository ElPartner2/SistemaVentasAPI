/*
    Proyecto: SistemaVentasAPI
    Autor: Daniel Castro
    Archivo: 03_SistemaVentas_Consultas.sql

    Consultas de relaciones y comprobacion.
    No modifica los datos.
*/

USE SistemaVentas;
GO

SET NOCOUNT ON;

-- 1. Cantidad de registros por tabla

SELECT N'CLIENTES' AS Tabla, COUNT(*) AS Registros
FROM dbo.CLIENTES
UNION ALL
SELECT N'CATEGORIAS', COUNT(*)
FROM dbo.CATEGORIAS
UNION ALL
SELECT N'PRODUCTOS', COUNT(*)
FROM dbo.PRODUCTOS
UNION ALL
SELECT N'VENTAS', COUNT(*)
FROM dbo.VENTAS
UNION ALL
SELECT N'DETALLE_VENTAS', COUNT(*)
FROM dbo.DETALLE_VENTAS;


-- 2. Productos con su categoria y existencia actual

SELECT
    p.IdProducto,
    p.Nombre AS Producto,
    c.Nombre AS Categoria,
    p.Precio,
    p.Existencia,
    p.Activo
FROM dbo.PRODUCTOS AS p
INNER JOIN dbo.CATEGORIAS AS c
    ON c.IdCategoria = p.IdCategoria
ORDER BY p.IdProducto;


-- 3. Ventas con el nombre del cliente

SELECT
    v.IdVenta,
    c.Nombre AS Cliente,
    v.FechaVenta,
    v.Total,
    v.Estado
FROM dbo.VENTAS AS v
INNER JOIN dbo.CLIENTES AS c
    ON c.IdCliente = v.IdCliente
ORDER BY v.IdVenta;


-- 4. Detalles de todas las ventas

SELECT
    v.IdVenta,
    c.Nombre AS Cliente,
    d.IdDetalleVenta,
    p.Nombre AS Producto,
    d.Cantidad,
    d.PrecioUnitario,
    d.Subtotal,
    v.Estado
FROM dbo.DETALLE_VENTAS AS d
INNER JOIN dbo.VENTAS AS v
    ON v.IdVenta = d.IdVenta
INNER JOIN dbo.CLIENTES AS c
    ON c.IdCliente = v.IdCliente
INNER JOIN dbo.PRODUCTOS AS p
    ON p.IdProducto = d.IdProducto
ORDER BY v.IdVenta, d.IdDetalleVenta;


-- 5. Comparacion del total guardado contra sus detalles
-- LEFT JOIN permite incluir ventas que no tengan detalles.

SELECT
    v.IdVenta,
    v.Total AS TotalGuardado,
    COALESCE(SUM(d.Subtotal), 0) AS TotalCalculado,
    v.Total - COALESCE(SUM(d.Subtotal), 0) AS Diferencia,
    COUNT(d.IdDetalleVenta) AS NumeroDetalles,
    CASE
        WHEN COUNT(d.IdDetalleVenta) = 0
            THEN N'SIN DETALLES'
        WHEN v.Total <> COALESCE(SUM(d.Subtotal), 0)
            THEN N'TOTAL INCORRECTO'
        ELSE N'CORRECTO'
    END AS Resultado
FROM dbo.VENTAS AS v
LEFT JOIN dbo.DETALLE_VENTAS AS d
    ON d.IdVenta = v.IdVenta
GROUP BY v.IdVenta, v.Total
ORDER BY v.IdVenta;


-- 6. Comparacion del subtotal guardado contra su calculo
-- Se utiliza el precio historico del detalle.

SELECT
    IdDetalleVenta,
    IdVenta,
    Cantidad,
    PrecioUnitario,
    Subtotal AS SubtotalGuardado,
    Cantidad * PrecioUnitario AS SubtotalCalculado,
    Subtotal - (Cantidad * PrecioUnitario) AS Diferencia,
    CASE
        WHEN Subtotal = Cantidad * PrecioUnitario
            THEN N'CORRECTO'
        ELSE N'SUBTOTAL INCORRECTO'
    END AS Resultado
FROM dbo.DETALLE_VENTAS
ORDER BY IdVenta, IdDetalleVenta;


-- 7. Resumen de ventas registradas por cliente
-- Incluye clientes que aun no tienen ventas registradas.

SELECT
    c.IdCliente,
    c.Nombre AS Cliente,
    COUNT(v.IdVenta) AS VentasRegistradas,
    COALESCE(SUM(v.Total), 0) AS ImporteVentasRegistradas
FROM dbo.CLIENTES AS c
LEFT JOIN dbo.VENTAS AS v
    ON v.IdCliente = c.IdCliente
    AND v.Estado = N'Registrada'
GROUP BY c.IdCliente, c.Nombre
ORDER BY c.IdCliente;


-- 8. Unidades vendidas por producto
-- Las ventas canceladas no cuentan como unidades vendidas.

SELECT
    p.IdProducto,
    p.Nombre AS Producto,
    p.Existencia AS ExistenciaActual,
    COALESCE(vendidos.UnidadesVendidas, 0) AS UnidadesVendidas
FROM dbo.PRODUCTOS AS p
LEFT JOIN
(
    SELECT
        d.IdProducto,
        SUM(d.Cantidad) AS UnidadesVendidas
    FROM dbo.DETALLE_VENTAS AS d
    INNER JOIN dbo.VENTAS AS v
        ON v.IdVenta = d.IdVenta
    WHERE v.Estado = N'Registrada'
    GROUP BY d.IdProducto
) AS vendidos
    ON vendidos.IdProducto = p.IdProducto
ORDER BY p.IdProducto;


-- 9. Comprobacion de existencias de la carga inicial
-- Esta consulta aplica antes de realizar cambios con la API.

SELECT
    p.Nombre AS Producto,
    inicial.ExistenciaInicial,
    COALESCE(vendidos.UnidadesVendidas, 0) AS UnidadesVendidas,
    inicial.ExistenciaInicial
        - COALESCE(vendidos.UnidadesVendidas, 0) AS ExistenciaEsperada,
    p.Existencia AS ExistenciaActual,
    CASE
        WHEN p.Existencia =
            inicial.ExistenciaInicial
            - COALESCE(vendidos.UnidadesVendidas, 0)
            THEN N'CORRECTO'
        ELSE N'REVISAR'
    END AS Resultado
FROM dbo.PRODUCTOS AS p
INNER JOIN
(
    VALUES
        (N'Agua natural 1 L', 50),
        (N'Refresco 600 ml', 40),
        (N'Jugo de naranja 1 L', 30),
        (N'Papas fritas 150 g', 35),
        (N'Galletas 200 g', 45),
        (N'Arroz 1 kg', 25),
        (N'Frijol 1 kg', 25),
        (N'Aceite vegetal 1 L', 20),
        (N'Detergente 1 kg', 20),
        (N'Cloro 1 L', 30)
) AS inicial (NombreProducto, ExistenciaInicial)
    ON inicial.NombreProducto = p.Nombre
LEFT JOIN
(
    SELECT
        d.IdProducto,
        SUM(d.Cantidad) AS UnidadesVendidas
    FROM dbo.DETALLE_VENTAS AS d
    INNER JOIN dbo.VENTAS AS v
        ON v.IdVenta = d.IdVenta
    WHERE v.Estado = N'Registrada'
    GROUP BY d.IdProducto
) AS vendidos
    ON vendidos.IdProducto = p.IdProducto
ORDER BY p.IdProducto;


-- 10. Resumen de inconsistencias
-- Todos los conteos deben ser cero.

SELECT
    N'Ventas sin detalles' AS Comprobacion,
    COUNT(*) AS Inconsistencias
FROM dbo.VENTAS AS v
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.DETALLE_VENTAS AS d
    WHERE d.IdVenta = v.IdVenta
)

UNION ALL

SELECT
    N'Totales de venta diferentes a sus detalles',
    COUNT(*)
FROM dbo.VENTAS AS v
WHERE v.Total <> COALESCE
(
    (
        SELECT SUM(d.Subtotal)
        FROM dbo.DETALLE_VENTAS AS d
        WHERE d.IdVenta = v.IdVenta
    ),
    0
)

UNION ALL

SELECT
    N'Subtotales diferentes a cantidad por precio',
    COUNT(*)
FROM dbo.DETALLE_VENTAS
WHERE Subtotal <> Cantidad * PrecioUnitario

UNION ALL

SELECT
    N'Productos con precio o existencia invalidos',
    COUNT(*)
FROM dbo.PRODUCTOS
WHERE Precio <= 0 OR Existencia < 0

UNION ALL

SELECT
    N'Detalles con valores invalidos',
    COUNT(*)
FROM dbo.DETALLE_VENTAS
WHERE Cantidad <= 0 OR PrecioUnitario <= 0 OR Subtotal < 0

UNION ALL

SELECT
    N'Ventas con total o estado invalidos',
    COUNT(*)
FROM dbo.VENTAS
WHERE Total < 0
   OR Estado NOT IN (N'Registrada', N'Cancelada');
GO