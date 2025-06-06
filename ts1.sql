SELECT * FROM pg_language WHERE lanname = 'plpgsql';


-- Creamos una tabla 
	
CREATE TABLE ventas (
    Month DATE,
    furniture_price_adjusted Float
);

Select * From ventas;

copy public.ventas1 from '/Users/user/Documents/Downloads/varios code python/Capacitacion_pancer/data/df_furniture.csv' DELIMITER ',' CSV HEADER;

Select * From ventas

-- Visualizar las ultimas 5 lineas

SELECT *
FROM ventas
ORDER BY month DESC
LIMIT 5;

-- Estadisticas descriptivas

SELECT
  COUNT(*) AS total_count,
  MIN(furniture_price_adjusted) AS min,
  MAX(furniture_price_adjusted) AS max,
  AVG(furniture_price_adjusted) AS media,
  STDDEV(furniture_price_adjusted) AS stddev
FROM ventas;

--  Suma acumulada

SELECT Month,
furniture_price_adjusted,
sum(furniture_price_adjusted) OVER (ORDER BY Month) as running_total
FROM ventas

-- promedio movil


SELECT
  Month, 
  furniture_price_adjusted,
  AVG(furniture_price_adjusted) OVER (ORDER BY Month ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS moving_average
FROM ventas
ORDER BY Month;

-- Moving Average Convergence Divergence (MACD)

-- 1. Calcular la EMA de 12 días (EMA12):

WITH ema12 AS (
  SELECT
    Month, 
  furniture_price_adjusted,
    AVG(furniture_price_adjusted) OVER (ORDER BY Month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS ema12
  FROM ventas
)
SELECT
  Month,
  furniture_price_adjusted,
  ema12
FROM ema12
ORDER BY Month;

-- Calcular la EMA de 26 días (EMA26):

WITH ema26 AS (
  SELECT
    Month, 
  furniture_price_adjusted,
    AVG(furniture_price_adjusted) OVER (ORDER BY Month ROWS BETWEEN 25 PRECEDING AND CURRENT ROW) AS ema26
  FROM ventas
)
SELECT
  Month, 
  furniture_price_adjusted,
  ema26
FROM ema26
ORDER BY Month;

-- Calcular el MACD:

WITH ema12 AS (
  SELECT
    Month, 
  furniture_price_adjusted,
    AVG(furniture_price_adjusted) OVER (ORDER BY Month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS ema12
  FROM ventas
),
ema26 AS (
  SELECT
    Month, 
  furniture_price_adjusted,
    AVG(furniture_price_adjusted) OVER (ORDER BY Month ROWS BETWEEN 25 PRECEDING AND CURRENT ROW) AS ema26
  FROM Ventas
)
SELECT
  ema12.Month,
  ema12.furniture_price_adjusted,
  ema12.ema12,
  ema26.ema26,
  ema12.ema12 - ema26.ema26 AS macd
FROM ema12
JOIN ema26 ON ema12.Month = ema26.Month
ORDER BY ema12.Month;


-- Otra forma con CTE (Common Table Expression)

WITH macd_data AS (
  SELECT
    Month, 
  furniture_price_adjusted,
    AVG(furniture_price_adjusted) OVER (ORDER BY Month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS ema_fast,
    AVG(furniture_price_adjusted) OVER (ORDER BY Month ROWS BETWEEN 26 PRECEDING AND CURRENT ROW) AS ema_slow
  FROM ventas
)
SELECT
   Month, 
  furniture_price_adjusted,
  ema_fast,
  ema_slow,
  ema_fast - ema_slow AS macd,
  AVG(ema_fast - ema_slow) OVER (ORDER BY Month ROWS BETWEEN 8 PRECEDING AND CURRENT ROW) AS signal_line,
  (ema_fast - ema_slow) - AVG(ema_fast - ema_slow) OVER (ORDER BY Month ROWS BETWEEN 8 PRECEDING AND CURRENT ROW) AS macd_histogram
FROM macd_data
ORDER BY Month;

-- RANK 
select Month, 
  furniture_price_adjusted,
 rank() over (order by furniture_price_adjusted desc) as ranking
from ventas 


select Month, 
  furniture_price_adjusted,
 dense_rank() over (order by furniture_price_adjusted desc) as ranking_dense
from ventas

-- Rango proximo periodo 

with ranking as (
select Month, 
  furniture_price_adjusted,
  rank() over (order by furniture_price_adjusted desc) as value_rank
from ventas
)
select Month, 
  furniture_price_adjusted,
	value_rank,
 LAG(value_rank) over (order by Month) - value_rank  as rank_change
from ranking

-- Funcion lead 

select 
   Month, 
  furniture_price_adjusted,
   lead(furniture_price_adjusted) over (order by Month)
from ventas

-- Lag 

select 
   Month, 
  furniture_price_adjusted, 
   lag(furniture_price_adjusted) over (order by Month) 
from ventas

-- Percentage Change

select 
  Month, 
  furniture_price_adjusted,
  lag(furniture_price_adjusted) over (order by Month) as Lags,
  furniture_price_adjusted - LAG(furniture_price_adjusted) OVER (ORDER BY Month) AS diferencia, 
  to_char(cast((((furniture_price_adjusted - lag(furniture_price_adjusted) over (order by Month))*1.0/lag(furniture_price_adjusted) over (order by Month))*100) as decimal(10,2)),'999D99%') 
from ventas

-- Estacionariedad

-- Calcular la descomposición de la serie
WITH decomposition AS (
  SELECT Month, 
  furniture_price_adjusted, 
         furniture_price_adjusted - avg(furniture_price_adjusted) OVER (ORDER BY Month) AS detrended,
         avg(furniture_price_adjusted) OVER (ORDER BY Month) AS trend
  FROM ventas
)
-- Mostrar los resultados
SELECT Month, 
  furniture_price_adjusted, detrended, trend
FROM decomposition;

-- -- Calcular la autocorrelación parcial de la serie

SELECT * FROM pg_language WHERE lanname = 'plpgsql';


CREATE FUNCTION acf(
  columna_serie VARCHAR(255),
  rezagos INTEGER
)
RETURNS TABLE
LANGUAGE plpgsql
AS $$
DECLARE
  i INTEGER;
  acf_valores NUMERIC ARRAY;
BEGIN
  -- Inicializar el arreglo de valores ACF
  FOR i IN 0..rezagos LOOP
    acf_valores[i] := 0;
  END LOOP;

  -- Calcular ACF para cada rezago
  FOR i IN 0..rezagos LOOP
    SELECT corr(columna_serie, LAG(columna_serie, i) OVER (ORDER BY fecha_mes))
      INTO acf_valores[i]
    FROM ventas_mensuales;
  END LOOP;

  -- Devolver tabla con rezagos y valores ACF
  RETURN TABLE
    SELECT rezago, acf_valor
    FROM UNNEST(ARRAY['rezago', 'acf_valor']::text[]) AS col
    WITH ORDINALITY AS i,
         UNNEST(acf_valores) AS valor
    ORDER BY i;
END;
$$;

-- otra
SELECT * FROM ventas

WITH acf AS (
	SELECT
	lag(furniture_price_adjusted) OVER (ORDER BY Month) AS valor_previo,
	furniture_price_adjusted,
	(furniture_price_adjusted - AVG(furniture_price_adjusted) OVER (ORDER BY Month)) * (valor_previo - AVG(valor_previo) OVER (ORDER BY Month)) AS cov
	FROM ventas
)
SELECT
	lag(Month) OVER (ORDER BY Month) AS fecha_lag,
	corr(cov) AS acf
	FROM acf
	ORDER BY fecha_lag;

SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';

SELECT 
    correlation(furniture_price_adjusted, ventas, 'auto') AS acf,
    correlation(furniture_price_adjusted, ventas, 'partial') AS pacf
FROM ventas;