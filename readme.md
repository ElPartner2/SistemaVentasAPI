# SistemaVentasAPI

Proyecto universitario de una API REST para administrar clientes,
categorías, productos y ventas utilizando ASP.NET Core y SQL Server.

## Autor

Daniel Castro.

## Objetivo

Desarrollar una API REST que permita gestionar catálogos y registrar
ventas con validaciones de datos, cálculo de importes y control de
existencias.

## Alcance

La primera versión utiliza cinco tablas:

- CLIENTES.
- CATEGORIAS.
- PRODUCTOS.
- VENTAS.
- DETALLE_VENTAS.

La API permitirá registrar ventas con varios productos y cancelarlas
devolviendo las existencias correspondientes.

## Tecnologías

- Visual Studio 2022.
- C# y ASP.NET Core Web API.
- SQL Server 2022.
- SQL Server Management Studio.
- Entity Framework Core para SQL Server.
- Swagger/OpenAPI.
- Postman.
- Git y GitHub.

## Organización del repositorio

- database/: scripts de estructura, datos y comprobación.
- docs/diagrama-er/: diagrama de la base de datos.
- src/: código de la API, pendiente de creación.
- postman/: colección de pruebas, pendiente de creación.

## Preparación de la base de datos

Abrir los scripts en SQL Server Management Studio y ejecutarlos
en este orden:

1. database/01_SistemaVentas_DDL.sql
2. database/02_SistemaVentas_Datos.sql
3. database/03_SistemaVentas_Consultas.sql

El primer script crea la base de datos SistemaVentas y sus tablas.

El segundo script requiere las cinco tablas vacías y carga:

- 5 clientes.
- 4 categorías.
- 10 productos.
- 3 ventas.
- 8 detalles de venta.

El tercer script consulta las relaciones y comprueba la consistencia
de los importes y del inventario inicial.

## Configuración y ejecución de la API

Pendiente de implementación.

Las credenciales de SQL Server se configurarán fuera del repositorio
mediante User Secrets.

## Endpoints y pruebas HTTP

Pendientes de implementación y comprobación con Swagger y Postman.

## Flujo de trabajo con Git

La rama main contiene los avances comprobados.

Para funcionalidades importantes se utilizarán ramas feature
y se integrarán a main después de comprobar su funcionamiento.

Antes de iniciar una sesión, actualizar el repositorio con git pull.
Después de cada avance comprobado, crear un commit y subirlo
mediante git push.

## Estado actual

- Entorno de desarrollo identificado.
- Diagrama E-R revisado.
- Base de datos creada.
- Datos de prueba cargados.
- Consultas de comprobación ejecutadas.
- API pendiente de implementación.
