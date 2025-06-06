-- Creamos una tabla 
	
CREATE TABLE vent_nuevo (
    fecha DATE,
    sales INTEGER
);

-- Podemos ver la tabla;

SELECT * FROM ventas;

-- Ahora vamos agregar los datos

INSERT INTO ventas (fecha, sales)
VALUES
    ('2021-01-01', 100),
    ('2021-02-01', 150),
    ('2021-03-01', 200),
    ('2021-04-01', 250),
    ('2021-05-01', 300),
    ('2021-06-01', 350),
    ('2021-07-01', 400),
    ('2021-08-01', 450),
    ('2021-09-01', 500),
    ('2021-10-01', 550),
    ('2021-11-01', 600),
    ('2021-12-01', 650);

--Veamos la tabla nuevamente
SELECT * FROM ventas;

-- vamos a realizar la suma acumulada
SELECT
	fecha,
	sales,
	SUM(sales) OVER (ORDER BY fecha) as suma_acumu
	FROM 
	ventas

-- Ahora realizaremos los lags 

SELECT 
fecha, 
sales,
LAG(sales) OVER (ORDER BY fecha) AS PrevSales
From
ventas;


-- Calculamos el porcentaje
	
SELECT
	fecha,
	sales,
	(sales - LAG(sales) OVER (ORDER BY fecha)) / LAG(sales) OVER (ORDER BY fecha)
	FROM
	ventas;


	
SELECT
  fecha,
  sales,
  LAG(sales) OVER (ORDER BY fecha) AS lags,
  sales - LAG(sales) OVER (ORDER BY fecha) AS difference,
 ((sales - LAG(sales) OVER (ORDER BY fecha)) / (LAG(sales) OVER (ORDER BY fecha))) * 100 AS porcentual
FROM ventas
ORDER BY fecha;

/* agregamos promedio movil */

SELECT fecha, 
	sales, 
	AVG(sales) OVER (ORDER BY fecha ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)
	AS Day_Moving_Average
	FROM ventas
	ORDER BY fecha


WITH sales_data AS (
  SELECT
    TO_DATE(fecha, 'DD/MM/YY') AS fecha,
    sales
  FROM (
    VALUES
      ('01/01/21', 100),
      ('02/01/21', 150),
      ('03/01/21', 200),
      ('04/01/21', 250),
      ('05/01/21', 300),
      ('06/01/21', 350),
      ('07/01/21', 400),
      ('08/01/21', 450),
      ('09/01/21', 500),
      ('10/01/21', 550),
      ('11/01/21', 600),
      ('12/01/21', 650)
  ) AS data(fecha, sales)
)
SELECT
  fecha,
  sales
FROM sales_data
ORDER BY fecha;

-- CTE for time series analysis

WITH sales_data AS (
  SELECT fecha, sales,
         ROW_NUMBER() OVER (ORDER BY fecha) AS row_num
  FROM ventas
)
SELECT
  fecha,
  sales,
  LAG(sales) OVER (ORDER BY fecha) AS previous_sales,
  LEAD(sales) OVER (ORDER BY fecha) AS next_sales,
  sales - LAG(sales) OVER (ORDER BY fecha) AS sales_diff,
  sales - LEAD(sales) OVER (ORDER BY fecha) AS sales_diff_next
FROM ventas
ORDER BY fecha;

-- 
WITH sales_data AS (
  SELECT
    TO_CHAR(fecha, 'DD/MM/YYYY') AS fecha_formatted,
    sales
  FROM ventas
)
SELECT
  fecha_formatted,
  sales
FROM sales_data
ORDER BY fecha_formatted;

-- otra forma de hacerlo
Select * from ventas

WITH sales_data AS (
  SELECT
    TO_DATE(fecha, 'DD/MM/YY') AS fecha_converted,
    sales
  FROM ventas
)
SELECT
  fecha_converted,
  sales
FROM sales_data
ORDER BY fecha_converted;