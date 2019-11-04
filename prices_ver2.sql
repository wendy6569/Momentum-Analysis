--create master temporary table for financial year 
CREATE TEMP TABLE master_tbl AS
(
SELECT 
CASE 
	WHEN sale_date BETWEEN '1999-07-01' AND '2000-06-30' 
		THEN '1999-00'
	WHEN sale_date BETWEEN '2000-07-01' AND '2001-06-30' 
		THEN '2000-01'
	WHEN sale_date BETWEEN '2001-07-01' AND '2002-06-30' 
		THEN '2001-02'
	WHEN sale_date BETWEEN '2002-07-01' AND '2003-06-30' 
		THEN '2002-03'
	WHEN sale_date BETWEEN '2003-07-01' AND '2004-06-30' 
		THEN '2003-04'
	WHEN sale_date BETWEEN '2004-07-01' AND '2005-06-30' 
		THEN '2004-05'
	WHEN sale_date BETWEEN '2005-07-01' AND '2006-06-30' 
		THEN '2005-06'
	WHEN sale_date BETWEEN '2006-07-01' AND '2007-06-30' 
		THEN '2006-07'
	WHEN sale_date BETWEEN '2007-07-01' AND '2008-06-30' 
		THEN '2007-08'
	WHEN sale_date BETWEEN '2008-07-01' AND '2009-06-30' 
		THEN '2008-09'
	WHEN sale_date BETWEEN '2009-07-01' AND '2010-06-30' 
		THEN '2009-10'
	WHEN sale_date BETWEEN '2010-07-01' AND '2011-06-30' 
		THEN '2010-11'
	WHEN sale_date BETWEEN '2011-07-01' AND '2012-06-30' 
		THEN '2011-12'
	WHEN sale_date BETWEEN '2012-07-01' AND '2013-06-30' 
		THEN '2012-13'
	WHEN sale_date BETWEEN '2013-07-01' AND '2014-06-30' 
		THEN '2013-14'
	WHEN sale_date BETWEEN '2014-07-01' AND '2015-06-30' 
		THEN '2014-15'
	WHEN sale_date BETWEEN '2015-07-01' AND '2016-06-30' 
		THEN '2015-16'
	WHEN sale_date BETWEEN '2016-07-01' AND '2017-06-30' 
		THEN '2016-17'
	WHEN sale_date BETWEEN '2017-07-01' AND '2018-06-30' 
		THEN '2017-18'
	WHEN sale_date BETWEEN '2018-07-01' AND '2019-06-30' 
		THEN '2018-19'
	WHEN sale_date BETWEEN '2019-07-01' AND '2020-06-30' 
		THEN '2019-20'
	END AS financial_year,
CASE 
	WHEN date_part( 'month', sale_date) = 07 
		THEN '01_JUL'
	WHEN date_part( 'month', sale_date) = 08 
		THEN '02_AUG'
	WHEN date_part( 'month', sale_date) = 09 
		THEN '03_SEP'
	WHEN date_part( 'month', sale_date) = 10 
		THEN '04_OCT'
	WHEN date_part( 'month', sale_date) = 11 
		THEN '05_NOV'
	WHEN date_part( 'month', sale_date) = 12 
		THEN '06_DEC'
	WHEN date_part( 'month', sale_date) = 01 
		THEN '07_JAN'
	WHEN date_part( 'month', sale_date) = 02 
		THEN '08_FEB'
	WHEN date_part( 'month', sale_date) = 03 
		THEN '09_MAR'
	WHEN date_part( 'month', sale_date) = 04 
		THEN '10_APR'
	WHEN date_part( 'month', sale_date) = 05 
		THEN '11_MAY'
	WHEN date_part( 'month', sale_date) = 06 
		THEN '12_JUN'
	END AS months,
*
FROM prices_new
);

-- a1: finding first day of trade by year
CREATE TEMP TABLE a1 AS
(
SELECT 
	financial_year, 
	MIN(sale_date) AS a_open
FROM master_tbl
GROUP BY 1
);

-- a1a: finding open price per year
CREATE TEMP TABLE a1a AS
(
SELECT 
	a1.financial_year, 
	a1.a_open AS open_date_1, 
	m.open_price AS o_price
FROM a1 
JOIN master_tbl m
	ON a1.a_open = m.sale_date
);

-- a2: finding last day of trade by year
CREATE TEMP TABLE a2 AS
(
SELECT 
	financial_year, 
	MAX(sale_date) AS a_close
FROM master_tbl
GROUP BY 1
);

-- a2a: finding close price per year
CREATE TEMP TABLE a2a AS
(
SELECT 
	a2.financial_year, 
	a2.a_close AS close_date_1, 
	m.close_price AS c_price
FROM a2
JOIN master_tbl m
	ON a2.a_close = m.sale_date
);

-- a3: finding highest price per year
CREATE TEMP TABLE a3 AS
(
SELECT 
	financial_year, 
MAX(high) AS a_high
FROM master_tbl
GROUP BY 1
);

-- a3a: finding date for highest price per year
CREATE TEMP TABLE a3a AS
(
SELECT 
	a3.financial_year, 
	m.sale_date AS high_date_1, 
	a3.a_high
FROM a3
JOIN master_tbl m
	ON a3.financial_year = m.financial_year
	AND a3.a_high = m.high
);

-- a4: finding lowest price by year
CREATE TEMP TABLE a4 AS
(
SELECT 
	financial_year, 
	MIN(low) AS a_low
FROM master_tbl
GROUP BY 1
);

-- a4a: finding the date for lowest price per year
CREATE TEMP TABLE a4a AS
(
SELECT 
	a4.financial_year, 
	m.sale_date AS low_date_1, 
	a4.a_low
FROM a4
JOIN master_tbl m
	ON a4.financial_year = m.financial_year
	AND a4.a_low = m.low
);

-- b1: finding differences of growth
CREATE TEMP TABLE b1 AS
(
SELECT 
	a1a.financial_year,
	a2a.c_price - a1a.o_price AS growth,
	a3.a_high - a1a.o_price AS max_increase,
	a4.a_low - a1a.o_price AS min_increase
FROM a1a
JOIN a2a 
	ON a1a.financial_year = a2a.financial_year
JOIN a3 
	ON a1a.financial_year = a3.financial_year
JOIN a4 
	ON a1a.financial_year = a4.financial_year
);

-- b2: finding % differences ingrowth
CREATE TEMP TABLE b2 AS
(
SELECT 
	a1a.financial_year,
	ROUND( 100* (b1.growth / a1a.o_price), 2) AS growth_p,
	ROUND( 100* (b1.max_increase / a1a.o_price), 2) AS max_p,
	ROUND( 100* (b1.min_increase / a1a.o_price), 2) As min_p
FROM b1
JOIN a1a 
	ON b1.financial_year = a1a.financial_year
);

-- c1: MONTHLY: average high per year
CREATE TEMP TABLE c1 AS
(
SELECT 
	financial_year,
	months,
	ROUND(AVG(high),2) AS m_high
FROM master_tbl
GROUP BY 1, 2
ORDER BY 1, 2
);

-- c2: MONTHLY: average low per year
CREATE TEMP TABLE c2 AS
(
SELECT
	financial_year,
	months,
	ROUND(AVG(low),2) AS m_low
FROM master_tbl
GROUP BY 1, 2
ORDER BY 1 ,2
);

-- c3: MONTHLY: difference in growth 
CREATE TEMP TABLE c3 AS
(
SELECT
	c1.financial_year,
	c1.months,
	c1.m_high - a1a.o_price AS m_h_diff,
	c2.m_low - a1a.o_price AS m_l_diff
FROM c1
JOIN c2 
	ON c1.financial_year = c2.financial_year 
	AND c1.months = c2.months
LEFT JOIN a1a 
	ON c1.financial_year = a1a.financial_year
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2
);

-- c4: MONTHLY: finding % monthly
CREATE TEMP TABLE c4 AS
(
SELECT 
	c3.financial_year,
	c3.months,
	c3.m_h_diff / a1a.o_price AS m_h_per,
	c3.m_l_diff / a1a.o_price AS m_l_per
FROM c3
LEFT JOIN a1a 
	ON c3.financial_year = a1a.financial_year
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2
);	


-- OUTPUTS
-- yearly figure 1- general 
SELECT 
	a1a.financial_year, 
	a1a.o_price AS OPEN, 
	a1a.open_date_1AS open_date,
	a2a.c_price AS CLOSE, 		
	a2a.close_date_1 AS close_date,
	a3a.a_high AS HIGH, 
	a3a.high_date_1 AS high_date,
	a4a.a_low AS LOW,
	a4a.low_date_1 AS low_date
FROM a1a 
JOIN a2a 
	ON a1a.financial_year = a2a.financial_year
JOIN a3a 
	ON a1a.financial_year = a3a.financial_year
JOIN a4a 
	ON a1a.financial_year = a4a.financial_year
;

-- yearly figure 2: yearly % growth by year
SELECT 
	financial_year,
	growth_p AS growth_percent,
	max_p AS high_percent,
	min_p AS low_percent
FROM b2
;

-- 20 years in average
SELECT 
	ROUND( AVG(growth_p), 2) AS avg_growth_percent,
	ROUND( AVG(max_p),2) AS avg_high_percent,
	ROUND( AVG(min_p),2) AS avg_low_percent
FROM b2
;

-- Best months to buy and sell - increase/ decrease by %
SELECT 
	months,
	ROUND( 100 * AVG(m_h_per), 4) AS avg_high,
	ROUND( 100 * AVG(m_l_per), 4) AS avg_low
FROM c4
GROUP BY 1
ORDER BY 1
;

-- Best month to buy - in order
SELECT
	months,
	ROUND( 100 * AVG(m_l_per), 4) AS avg_low
FROM c4
GROUP BY 1
ORDER BY 2 asc
;

-- Best month to sell - in order
SELECT
	months,
	ROUND( 100 * AVG(m_h_per), 4) AS avg_high
FROM c4
GROUP BY 1
ORDER BY 2 desc
;

-- historic dates - 20 years highest and lowest
SELECT
	a3a.financial_year,
	a3a.a_high AS highest,
	CONCAT (date_part ( 'month', a3a.sale_date), ' - ', date_part ( 'day', a3a.sale_date)) AS high_date_MM_DD,
	a4a.a_low AS lowest,
	CONCAT (date_part ( 'month', a4a.sale_date), ' - ', date_part ( 'day', a4a.sale_date)) AS low_date_MM_DD
FROM a4a
LEFT JOIN a3a ON a3a.financial_year = a4a.financial_year
;
	
