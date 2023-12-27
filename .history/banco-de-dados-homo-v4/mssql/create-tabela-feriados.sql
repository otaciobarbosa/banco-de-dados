-- Tabela simplificada:
SET LANGUAGE 'Brazilian'

-- IF (OBJECT_ID('dbo.Calendario') IS NOT NULL) DROP TABLE dbo.Calendario
CREATE TABLE dbo.Calendario (
    Dt_Referencia DATETIME,
    Nr_Dia TINYINT,
    Nr_Mes TINYINT,
    Nr_Ano INT,
    Nr_Dia_Semana TINYINT,
    Ds_Dia_Semana VARCHAR(13),
    Nr_Semana INT,
    Nr_Semana_Mes INT,
    Nr_Dia_Ano INT
)
 
DECLARE @Dt_Inicial DATETIME = '19900101', @Dt_Final DATETIME = '20991231'
 
WHILE (@Dt_Inicial <= @Dt_Final)
BEGIN
    
    INSERT INTO dbo.Calendario
    SELECT 
        @Dt_Inicial AS Dt_Referencia, 
        DATEPART(DAY, @Dt_Inicial) AS Nr_Dia,
        DATEPART(MONTH, @Dt_Inicial) AS Nr_Mes,
        DATEPART(YEAR, @Dt_Inicial) AS Nr_Ano,
        DATEPART(WEEKDAY, @Dt_Inicial) AS Nr_Dia_Semana,
        DATENAME(WEEKDAY, @Dt_Inicial) AS Ds_Dia_Semana,
        DATEPART(WEEK, @Dt_Inicial) AS Nr_Semana,
        DATEPART(WEEK, @Dt_Inicial) - DATEPART(WEEK, @Dt_Inicial - DATEPART(DAY, @Dt_Inicial) + 1) + 1 AS Nr_Semana_Mes,
        DATEPART(DAYOFYEAR, @Dt_Inicial) AS Nr_Dia_Ano
        
 
    SET @Dt_Inicial = DATEADD(DAY, 1, @Dt_Inicial)
    
END
 

-- ADICIONA MAIS INFORMAÇÕES NA TABELA
ALTER TABLE dbo.Calendario ADD Fl_Ultimo_Dia_Mes BIT
 
UPDATE dbo.Calendario SET Fl_Ultimo_Dia_Mes = 0
 
UPDATE A 
SET
    A.Fl_Ultimo_Dia_Mes = 1
FROM 
    dbo.Calendario A
    JOIN (
        SELECT Nr_Ano, Nr_Mes, MAX(Dt_Referencia) AS Dt_Referencia
        FROM dbo.Calendario
        GROUP BY Nr_Ano, Nr_Mes
    ) B ON B.Dt_Referencia = A.Dt_Referencia
 
 
ALTER TABLE dbo.Calendario ADD Nr_Bimestre TINYINT, Nr_Trimestre TINYINT, Nr_Semestre TINYINT
 
UPDATE dbo.Calendario
SET
    Nr_Bimestre = CEILING((Nr_Mes * 1.0) / 2),
    Nr_Trimestre = CEILING((Nr_Mes * 1.0) / 3),
    Nr_Semestre = CEILING((Nr_Mes * 1.0) / 6)
 
 
ALTER TABLE dbo.Calendario ADD Nm_Mes VARCHAR(20), Nm_Mes_Ano VARCHAR(30), Nm_Mes_Ano_Abreviado VARCHAR(20), Nr_Mes_Ano INT
 
 
UPDATE dbo.Calendario
SET
    Nm_Mes = DATENAME(MONTH, Dt_Referencia),
    Nm_Mes_Ano = DATENAME(MONTH, Dt_Referencia) + ' ' + CAST(Nr_Ano AS VARCHAR(4)),
    Nm_Mes_Ano_Abreviado = LEFT(DATENAME(MONTH, Dt_Referencia), 3) + '/' + RIGHT(Nr_Ano, 2),
    Nr_Mes_Ano = CAST(CAST(Nr_Ano AS VARCHAR(4)) + RIGHT('0' + CAST(Nr_Mes AS VARCHAR(2)), 2) AS INT)
 
 
ALTER TABLE dbo.Calendario ADD Nr_Quinzena INT, Ds_Semana VARCHAR(20), Ds_Quinzena VARCHAR(20), Ds_Bimestre VARCHAR(20), Ds_Trimestre VARCHAR(20), Ds_Semestre VARCHAR(20)
 
 
UPDATE dbo.Calendario
SET
    Nr_Quinzena = (CASE WHEN Nr_Dia <= 15 THEN 1 ELSE 2 END),
    Ds_Semana = CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + CAST(Nr_Semana AS VARCHAR(2)) + 'a Semana',
    Ds_Quinzena = CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + (CASE WHEN Nr_Dia <= 15 THEN '1a Quinzena' ELSE '2a Quinzena' END),
    Ds_Bimestre = CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + CAST(Nr_Bimestre AS VARCHAR(2)) + 'o Bimestre',
    Ds_Trimestre = CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + CAST(Nr_Trimestre AS VARCHAR(2)) + 'o Trimestre',
    Ds_Semestre = CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + CAST(Nr_Semestre AS VARCHAR(2)) + 'o Semestre'
 
 
CREATE CLUSTERED INDEX Idx01 ON dbo.Calendario(Dt_Referencia)

-- Tabela simplificada EM INGLÊS:
CREATE FUNCTION [dbo].[fncCalendar] (
    @StartDate DATETIME = '1970-01-01',
    @EndDate DATETIME = '2100-01-01',
    @FiscalMonthAdjustment SMALLINT = 0
)
RETURNS @Results TABLE (
    [DateKey] DATE NOT NULL,
    [Date] INT NOT NULL,
    [FiscalDateKey] DATE NOT NULL,
    [FiscalDate] INT NOT NULL,
    [SequentialNumber] AS (CASE WHEN DateKey < '1899-12-30' THEN DATEDIFF(DAY, '0001-01-01', DateKey) ELSE DATEDIFF(DAY, '1899-12-30', DateKey) END),
    [FiscalSequentialNumber] AS (CASE WHEN FiscalDateKey < '1899-12-30' THEN DATEDIFF(DAY, '0001-01-01', FiscalDateKey) ELSE DATEDIFF(DAY, '1899-12-30', FiscalDateKey) END),
    [DDMMYYYY] AS (FORMAT(DateKey, 'dd/MM/yyyy')),
    [MMDDYYYY] AS (FORMAT(DateKey, 'MM/dd/yyyy')),
    [FullDate] AS (FORMAT(DateKey, 'dddd, MMMM dd yyyy')),
    [FiscalYear] INT NOT NULL,
    [Year] INT NOT NULL,
    [YearName] AS (CONCAT('Calendar ', [FiscalYear])),
    [Semester] INT NOT NULL,
    [SemesterNumber] AS (CEILING(DATEDIFF(MONTH, '0001-01-01', FiscalDateKey) / 6.0) + 6),
    [SemesterName] AS (CONCAT('Semester ', [SemesterOfYear], ', ', [FiscalYear])),
    [SemesterOfYear] SMALLINT NOT NULL,
    [Quarter] INT NOT NULL,
    [QuarterNumber] AS (DATEDIFF(QUARTER, '0001-01-01', FiscalDateKey) + 4),
    [QuarterName] AS (CONCAT('Quarter ', [QuarterOfYear], ', ', [FiscalYear])),
    [QuarterOfYear] SMALLINT NOT NULL,
    [QuarterOfYearName] AS (CONCAT('Quarter ', [QuarterOfYear])),
    [QuarterOfSemester] SMALLINT NOT NULL,
    [QuarterOfSemesterName] AS (CONCAT('Quarter ', [QuarterOfSemester])),
    [Month] INT NOT NULL,
    [MonthNumber] AS (DATEDIFF(MONTH, '0001-01-01', FiscalDateKey) + 12),
    [MonthName] AS (FORMAT(DateKey, 'MMMM yyyy')),
    [MonthYear] AS (FORMAT(DateKey, 'MMM yyyy')),
    [MMYYYY] AS (FORMAT([DateKey], 'MMyyyy')),
    [MonthOfYear] SMALLINT NOT NULL,
    [MonthOfYearName] AS (CONCAT('Month ', [MonthOfYear])),
    [MonthOfSemester] SMALLINT NOT NULL,
    [MonthOfSemesterName] AS (CONCAT('Month ', [MonthOfSemester])),
    [MonthOfQuarter] INT NOT NULL,
    [MonthOfQuarterName] AS (CONCAT('Month ', [MonthOfQuarter])),
    [ShortMonthName] AS (FORMAT([DateKey], 'MMM')),
    [LongMonthName] AS (FORMAT([DateKey], 'MMMM')),
    [PortugueseMonthName] AS (FORMAT([DateKey], 'MMMM', 'pt-BR')),
    [SpanishMonthName] AS (FORMAT([DateKey], 'MMMM', 'es-es')),
    [IsWeekday] AS (CASE WHEN [DayOfWeek] BETWEEN 2 AND 6 THEN 1 ELSE 0 END),
    [DayOfYear] SMALLINT NOT NULL,
    [DayOfYearName] AS (CONCAT('Day ', [DayOfYear])),
    [DayOfSemester] INT NOT NULL,
    [DayOfSemesterName] AS (CONCAT('Day ', [DayOfSemester])),
    [DayOfQuarter] INT NOT NULL,
    [DayOfQuarterName] AS (CONCAT('Day ', [DayOfQuarter])),
    [DayOfMonth] SMALLINT NOT NULL,
    [DayOfMonthName] AS (CONCAT('Day ', [DayOfMonth])),
    [DayOfWeek] SMALLINT NOT NULL,
    [DayOfWeekName] AS (DATENAME(WEEKDAY, FiscalDateKey)),
    [DaySuffix] AS (CASE 
	WHEN [DayOfMonth] IN (11, 12, 13) THEN CAST([DayOfMonth] AS VARCHAR(2)) + 'th'
	WHEN RIGHT([DayOfMonth], 1) = 1 THEN CAST([DayOfMonth] AS VARCHAR(2)) + 'st'
	WHEN RIGHT([DayOfMonth], 1) = 2 THEN CAST([DayOfMonth] AS VARCHAR(2)) + 'nd'
	WHEN RIGHT([DayOfMonth], 1) = 3 THEN CAST([DayOfMonth] AS VARCHAR(2)) + 'rd'
	ELSE CAST([DayOfMonth] AS VARCHAR(2)) + 'th' 
    END),
    [IsLeapYear] AS CONVERT(BIT, (CASE
	WHEN [FiscalYear] % 4 <> 0 THEN 0
	WHEN [FiscalYear] % 100 <> 0 THEN 1
	WHEN [FiscalYear] % 400 <> 0 THEN 0
	ELSE 1
    END)),
    [FirstDayOfYear] DATE NULL,
    [LastDayOfYear] DATE NULL,
    [FirstDayOfSemester] DATE NULL,
    [LastDayOfSemester] DATE NULL,
    [FirstDayOfQuarter] DATE NULL,
    [LastDayOfQuarter] DATE NULL,
    [FirstDayOfMonth] AS (CONVERT(DATE, CONVERT(DATE, DATEADD(DAY, -([DayOfMonth] - 1), DateKey)))),
    [LastDayOfMonth] AS (CONVERT(DATE, CONVERT(DATE, DATEADD(DAY, -(DATEPART(DAY, (DATEADD(MONTH, 1, DateKey)))), DATEADD(MONTH, 1, DateKey)))))
)
AS
BEGIN

    -------------------------------------------------
    -- Insert data for DateKey and FiscalDateKey
    -------------------------------------------------
    
    -- DECLARE @StartDate DATETIME = '1970-01-01', @EndDate DATETIME = '2100-01-01', @FiscalMonthAdjustment SMALLINT = 0

    ;WITH generateRandomNumbers(i) AS (
        SELECT 0
        FROM        (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS x1(i)
        CROSS APPLY (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS x2(i)
        CROSS APPLY (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS x3(i)
    ),
    generateNumbers(i) AS (
        SELECT TOP (DATEDIFF(DAY, @StartDate, @EndDate)+1)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL))-1
        FROM generateRandomNumbers AS x1, generateRandomNumbers AS x2
    ),
    generateDates([date], [fiscalDate]) AS (
        SELECT 
            DATEADD(MONTH, @FiscalMonthAdjustment, DATEADD(DAY, i, @StartDate)) AS [date],
            DATEADD(DAY, i, @StartDate) AS fiscalDate
        FROM generateNumbers
    ),
    calendarData ( DateKey, FiscalDateKey, [Year], [FiscalYear], [SemesterOfYear], [QuarterOfYear], [MonthOfYear], [DayOfYear], [DayOfMonth], [DayOfWeek] ) 
    AS (
        SELECT
            generateDates.[date] AS [Date],
            generateDates.fiscalDate AS [FiscalDate],

            DATEPART(YEAR, generateDates.[date]) AS [Year],
            DATEPART(YEAR, generateDates.[fiscalDate]) AS [FiscalYear],
            CEILING(DATEPART(MONTH, generateDates.fiscalDate) * 1.0 / 6) AS [SemesterOfYear],
            DATEPART(QUARTER, generateDates.fiscalDate) AS [QuarterOfYear],
            DATEPART(MONTH, generateDates.fiscalDate) AS [MonthOfYear],
            DATEPART(DAYOFYEAR, generateDates.fiscalDate) AS [DayOfYear],
            DATEPART(DAY, generateDates.fiscalDate) AS [DayOfMonth],
            DATEPART(WEEKDAY, generateDates.fiscalDate) AS [DayOfWeek]
        FROM
            generateDates
    ),
    finalTable ( [DateKey], [FiscalDateKey], [Date], [FiscalDate], [Year], [FiscalYear], [SemesterOfYear], [QuarterOfYear], [MonthOfYear], [DayOfYear], [DayOfMonth], [DayOfWeek], [Semester], [Quarter], [QuarterOfSemester], [Month], [MonthOfSemester], [MonthOfQuarter], [DayOfSemester], [DayOfQuarter] )
    AS (
        SELECT
            DateKey,
            FiscalDateKey,
            CONVERT(INT, CONCAT([Year], FORMAT(DATEPART(MONTH, [FiscalDateKey]), '00'), FORMAT([DayOfMonth], '00'))) AS [Date],
            CONVERT(INT, CONCAT([FiscalYear], FORMAT(DATEPART(MONTH, [DateKey]), '00'), FORMAT([DayOfMonth], '00'))) AS [FiscalDate],
            [Year],
            [FiscalYear],
            [SemesterOfYear],
            [QuarterOfYear],
            [MonthOfYear],
            [DayOfYear],
            [DayOfMonth],
            [DayOfWeek],

            CONVERT(INT, CONCAT([FiscalYear], FORMAT([SemesterOfYear], '00'))) AS [Semester],
        
            CONVERT(INT, CONCAT([FiscalYear], FORMAT([QuarterOfYear], '00'))) AS [Quarter],
            (CASE WHEN [QuarterOfYear] IN (1, 3) THEN 1 ELSE 2 END) AS [QuarterOfSemester],
        	
            CONVERT(INT, CONCAT([FiscalYear], FORMAT([MonthOfYear], '00'))) AS [Month],
        
            (CASE 
                WHEN [MonthOfYear] < 7 THEN [MonthOfYear]
                ELSE [MonthOfYear] - 6
            END) AS [MonthOfSemester],

            (CASE 
                WHEN [MonthOfYear] IN (1, 4, 7, 10) THEN 1
                WHEN [MonthOfYear] IN (2, 5, 8, 11) THEN 2
                ELSE 3
            END) AS [MonthOfQuarter],

            (CASE 
                WHEN [MonthOfYear] < 7 THEN [DayOfYear] 
                ELSE [DayOfYear] - DATEPART(DAYOFYEAR, DATEFROMPARTS([FiscalYear], 6, 30)) 
            END) AS [DayOfSemester],

            (CASE 
                WHEN [MonthOfYear] BETWEEN 1 AND 3 THEN [DayOfYear]
                WHEN [MonthOfYear] BETWEEN 4 AND 6 THEN [DayOfYear] - DATEPART(DAYOFYEAR, DATEFROMPARTS([FiscalYear], 3, 31))
                WHEN [MonthOfYear] BETWEEN 7 AND 9 THEN [DayOfYear] - DATEPART(DAYOFYEAR, DATEFROMPARTS([FiscalYear], 6, 30))
                ELSE [DayOfYear] - DATEPART(DAYOFYEAR, DATEFROMPARTS([FiscalYear], 9, 30))
            END) AS [DayOfQuarter]
        FROM
            calendarData
        WHERE
            DATEPART(DAY, DateKey) = DATEPART(DAY, FiscalDateKey)
    )
    INSERT INTO @Results (
	[DateKey],
        [FiscalDateKey],
        [Date],
        [FiscalDate],
        [Year],
        [FiscalYear],
        [SemesterOfYear],
        [QuarterOfYear],
        [MonthOfYear],
        [DayOfYear],
        [DayOfMonth],
        [DayOfWeek],
        [Semester],
        [Quarter],
        [QuarterOfSemester],
        [Month],
        [MonthOfSemester],
        [MonthOfQuarter],
        [DayOfSemester],
        [DayOfQuarter]
    )
    SELECT 
        A.[DateKey],
        A.[FiscalDateKey],
        A.[Date],
        A.[FiscalDate],
        A.[Year],
        A.[FiscalYear],
        A.[SemesterOfYear],
        A.[QuarterOfYear],
        A.[MonthOfYear],
        A.[DayOfYear],
        A.[DayOfMonth],
        A.[DayOfWeek],
        A.[Semester],
        A.[Quarter],
        A.[QuarterOfSemester],
        A.[Month],
        A.[MonthOfSemester],
        A.[MonthOfQuarter],
        A.[DayOfSemester],
        A.[DayOfQuarter]
    FROM
        finalTable A
        
        
        
    UPDATE A
    SET
        A.FirstDayOfYear = B.FirstDayOfYear,
        A.LastDayOfYear = B.LastDayOfYear,
        A.FirstDayOfSemester = C.FirstDayOfSemester,
        A.LastDayOfSemester = C.LastDayOfSemester,
        A.FirstDayOfQuarter = D.FirstDayOfQuarter,
        A.LastDayOfQuarter = D.LastDayOfQuarter
    FROM
        @Results A
        JOIN (
            SELECT [FiscalYear], MIN(DateKey) AS FirstDayOfYear, MAX(DateKey) AS LastDayOfYear
            FROM @Results
            GROUP BY [FiscalYear]
        ) B ON B.[FiscalYear] = A.[FiscalYear]
        JOIN (
            SELECT Semester, MIN(DateKey) AS FirstDayOfSemester, MAX(DateKey) AS LastDayOfSemester
            FROM @Results
            GROUP BY Semester
        ) C ON C.Semester = A.Semester
        JOIN (
            SELECT [Quarter], MIN(DateKey) AS FirstDayOfQuarter, MAX(DateKey) AS LastDayOfQuarter
            FROM @Results
            GROUP BY [Quarter]
        ) D ON D.[Quarter] = A.[Quarter]


    DELETE @Results
    WHERE DATEPART(DAY, DateKey) <> DATEPART(DAY, FiscalDateKey)


    RETURN


END

-- Tabela completa, com feriados e dias úteis:
SET LANGUAGE 'English'

IF (OBJECT_ID('tempdb..#Datas') IS NOT NULL) DROP TABLE #Datas
CREATE TABLE #Datas (
    Dt_Inicial DATE,
    Dt_Final DATE
)

-- Altere o período que deseja gerar a tabela de calendário
INSERT INTO #Datas
VALUES ('1990-01-01', '2099-12-31')


---------------------------------------
-- Cria as tabelas de feriados
---------------------------------------

IF (OBJECT_ID('dbo.Feriados') IS NULL)
BEGIN
        
    -- DROP TABLE dbo.Feriados
    CREATE TABLE dbo.Feriados (
        Nr_Ano SMALLINT NOT NULL,
        Nr_Mes SMALLINT NOT NULL,
        Nr_Dia SMALLINT NOT NULL,
        Tp_Feriado CHAR(1) NULL,
        Ds_Feriado VARCHAR(100) NOT NULL,
        Sg_UF CHAR(2) NOT NULL
    )
        
    ALTER TABLE dbo.Feriados ADD CONSTRAINT [Pk_Feriados] PRIMARY KEY CLUSTERED  ([Nr_Ano], [Nr_Mes], [Nr_Dia], [Sg_UF]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
 
 
END
 
 
-- Apaga os dados se já tiverem sido populados
TRUNCATE TABLE dbo.Feriados
 
 
-------------------------------
-- Feriados nacionais
-------------------------------
 
INSERT INTO dbo.Feriados
SELECT 0, 1, 1, 1, 'Confraternização Universal', ''
UNION
SELECT 0, 4, 21, 1, 'Tiradentes', ''
UNION
SELECT 0, 5, 1, 1, 'Dia do Trabalhador', ''
UNION
SELECT 0, 9, 7, 1, 'Independência', ''
UNION
SELECT 0, 10, 12, 1, 'Nossa Senhora Aparecida', ''
UNION
SELECT 0, 11, 2, 1, 'Finados', ''
UNION
SELECT 0, 11, 15, 1, 'Proclamação da República', ''
UNION
SELECT 0, 12, 25, 1, 'Natal', ''
 
 
 
-------------------------------
-- Feriados estaduais
-------------------------------
 
-- Acre
INSERT INTO dbo.Feriados
SELECT 0, 1, 23, 2, 'Dia do evangélico', 'AC'
UNION
SELECT 0, 3, 8, 2, 'Alusivo ao Dia Internacional da Mulher', 'AC'
UNION
SELECT 0, 6, 15, 2, 'Aniversário do estado', 'AC'
UNION
SELECT 0, 9, 5, 2, 'Dia da Amazônia', 'AC'
UNION
SELECT 0, 11, 17, 2, 'Assinatura do Tratado de Petrópolis', 'AC'
 
-- Alagoas
INSERT INTO dbo.Feriados
SELECT 0, 6, 24, 2, 'São João', 'AL'
UNION
SELECT 0, 6, 29, 2, 'São Pedro', 'AL'
UNION
SELECT 0, 9, 16, 2, 'Emancipação política', 'AL'
UNION
SELECT 0, 11, 20, 2, 'Morte de Zumbi dos Palmares', 'AL'
 
-- Amapá
INSERT INTO dbo.Feriados
SELECT 0, 3, 19, 2, 'Dia de São José, santo padroeiro do Estado do Amapá', 'AP'
UNION
SELECT 0, 9, 13, 2, 'Criação do Território Federal (Data Magna do estado)', 'AP'
 
-- Amazonas
INSERT INTO dbo.Feriados
SELECT 0, 9, 5, 2, 'Elevação do Amazonas à categoria de província', 'AM'
UNION
SELECT 0, 11, 20, 2, 'Dia da Consciência Negra', 'AM'
 
-- Bahia
INSERT INTO dbo.Feriados
SELECT 0, 7, 2, 2, 'Independência da Bahia (Data magna do estado)', 'BA'
 
-- Ceará
INSERT INTO dbo.Feriados
SELECT 0, 3, 25, 2, 'Data magna do estado (data da abolição da escravidão no Ceará)', 'CE'
 
-- Distrito Federal
INSERT INTO dbo.Feriados
SELECT 0, 4, 21, 2, 'Fundação de Brasília', 'DF'
UNION
SELECT 0, 11, 30, 2, 'Dia do evangélico', 'DF'
 
-- Maranhão
INSERT INTO dbo.Feriados
SELECT 0, 7, 28, 2, 'Adesão do Maranhão à independência do Brasil', 'MA'
 
-- Mato Grosso
INSERT INTO dbo.Feriados
SELECT 0, 11, 20, 2, 'Dia da Consciência Negra', 'MT'
 
-- Mato Grosso do Sul
INSERT INTO dbo.Feriados
SELECT 0, 10, 11, 2, 'Criação do estado', 'MS'
 
-- Minas Gerais
INSERT INTO dbo.Feriados
SELECT 0, 4, 21, 2, 'Data magna do estado', 'MG'
 
-- Pará
INSERT INTO dbo.Feriados
SELECT 0, 8, 15, 2, 'Adesão do Grão-Pará à independência do Brasil (data magna)', 'PA'
 
-- Paraíba
INSERT INTO dbo.Feriados
SELECT 0, 7, 26, 2, 'Homenagem à memória do ex-presidente João Pessoa', 'PB'
UNION
SELECT 0, 8, 5, 2, 'Fundação do Estado em 1585', 'PB'
 
-- Paraná
INSERT INTO dbo.Feriados
SELECT 0, 12, 19, 2, 'Emancipação política (emancipação do Paraná)', 'PR'
 
-- Piauí
INSERT INTO dbo.Feriados
SELECT 0, 10, 19, 2, 'Dia do Piauí', 'PI'
 
-- Rio de Janeiro
INSERT INTO dbo.Feriados
SELECT 0, 4, 23, 2, 'Dia de São Jorge', 'RJ'
UNION
SELECT 0, 11, 20, 2, 'Dia da Consciência Negra', 'RJ'
 
-- Rio Grande do Norte
INSERT INTO dbo.Feriados
SELECT 0, 10, 3, 2, 'Mártires de Cunhaú e Uruaçu', 'RN'
 
-- Rio Grande do Sul
INSERT INTO dbo.Feriados
SELECT 0, 9, 20, 2, 'Proclamação da República Rio-Grandense', 'RS'
 
-- Rondônia
INSERT INTO dbo.Feriados
SELECT 0, 1, 4, 2, 'Criação do estado (data magna)', 'RO'
UNION
SELECT 0, 6, 18, 2, 'Dia do evangélico', 'RO'
 
-- Roraima
INSERT INTO dbo.Feriados
SELECT 0, 10, 5, 2, 'Criação do estado', 'RR'
 
-- Santa Catarina
INSERT INTO dbo.Feriados
SELECT 0, 10, 5, 2, 'Dia de Santa Catarina', 'SC'
 
-- São Paulo
INSERT INTO dbo.Feriados
SELECT 0, 7, 9, 2, 'Revolução Constitucionalista de 1932 (Data magna do estado)', 'SP'
 
-- Sergipe
INSERT INTO dbo.Feriados
SELECT 0, 3, 17, 2, 'Aniversário de Aracaju', 'SE'
UNION
SELECT 0, 6, 24, 2, 'São João', 'SE'
UNION
SELECT 0, 7, 8, 2, 'Autonomia política de Sergipe', 'SE'
UNION
SELECT 0, 12, 8, 2, 'Nossa Senhora da Conceição', 'SE'
 
-- Tocantins
INSERT INTO dbo.Feriados
SELECT 0, 10, 5, 2, 'Criação do estado', 'TO'
UNION
SELECT 0, 3, 18, 2, 'Autonomia do Estado (criação da Comarca do Norte)', 'TO'
UNION
SELECT 0, 9, 8, 2, 'Padroeira do Estado (Nossa Senhora da Natividade)', 'TO'
 
    
-------------------------------
-- Calcula os feriados móveis
-------------------------------
 
DECLARE
    @ano INT,
    @seculo INT,
    @G INT,
    @K INT,
    @I INT,
    @H INT,
    @J INT,
    @L INT,
    @MesDePascoa INT,
    @DiaDePascoa INT,
    @pascoa DATETIME 
 

DECLARE
    @Dt_Inicial DATETIME = (SELECT MIN(Dt_Inicial) FROM [#Datas]),
    @Dt_Final DATETIME = (SELECT MAX([Dt_Final]) FROM [#Datas])

 
WHILE(@Dt_Inicial <= @Dt_Final)
BEGIN
        
    SET @ano = YEAR(@Dt_Inicial)
 
    SET @seculo = @ano / 100 
    SET @G = @ano % 19
    SET @K = ( @seculo - 17 ) / 25
    SET @I = ( @seculo - CAST(@seculo / 4 AS int) - CAST(( @seculo - @K ) / 3 AS int) + 19 * @G + 15 ) % 30
    SET @H = @I - CAST(@I / 28 AS int) * ( 1 * -CAST(@I / 28 AS int) * CAST(29 / ( @I + 1 ) AS int) ) * CAST(( ( 21 - @G ) / 11 ) AS int)
    SET @J = ( @ano + CAST(@ano / 4 AS int) + @H + 2 - @seculo + CAST(@seculo / 4 AS int) ) % 7
    SET @L = @H - @J
    SET @MesDePascoa = 3 + CAST(( @L + 40 ) / 44 AS int)
    SET @DiaDePascoa = @L + 28 - 31 * CAST(( @MesDePascoa / 4 ) AS int)
    SET @pascoa = CAST(@MesDePascoa AS varchar(2)) + '-' + CAST(@DiaDePascoa AS varchar(2)) + '-' + CAST(@ano AS varchar(4))
 
        
    INSERT INTO dbo.Feriados
    SELECT YEAR(DATEADD(DAY , -2, @pascoa)), MONTH(DATEADD(DAY , -2, @pascoa)), DAY(DATEADD(DAY , -2, @pascoa)), 1, 'Paixão de Cristo', ''
        
    INSERT INTO dbo.Feriados
    SELECT YEAR(DATEADD(DAY , -48, @pascoa)), MONTH(DATEADD(DAY , -48, @pascoa)), DAY(DATEADD(DAY , -48, @pascoa)), 1, 'Carnaval', ''
        
    INSERT INTO dbo.Feriados
    SELECT YEAR(DATEADD(DAY , -47, @pascoa)), MONTH(DATEADD(DAY , -47, @pascoa)), DAY(DATEADD(DAY , -47, @pascoa)), 1, 'Carnaval', ''
        
    INSERT INTO dbo.Feriados
    SELECT YEAR(DATEADD(DAY , 60, @pascoa)), MONTH(DATEADD(DAY , 60, @pascoa)), DAY(DATEADD(DAY , 60, @pascoa)), 1, 'Corpus Christi', ''
        
 
    SET @Dt_Inicial = DATEADD(YEAR, 1, @Dt_Inicial)
        
 
END
GO


---------------------------------------
-- Cria as funções de dias úteis
---------------------------------------

IF (OBJECT_ID('dbo.fncDia_Util_Anterior') IS NOT NULL) DROP FUNCTION [dbo].[fncDia_Util_Anterior]
GO

CREATE FUNCTION [dbo].[fncDia_Util_Anterior] ( @Data_Dia DATETIME )
RETURNS DATETIME
AS
BEGIN
 
    WHILE (1 = 1)
    BEGIN

        SET @Data_Dia = @Data_Dia - (CASE DATEPART(WEEKDAY, @Data_Dia) WHEN 1 THEN 2 WHEN 7 THEN 1 ELSE 0 END)

        IF EXISTS ( SELECT TOP(1) Nr_Dia FROM dbo.Feriados WHERE Nr_Dia = DAY(@Data_Dia) AND Nr_Mes = MONTH(@Data_Dia) AND Tp_Feriado = '1'  AND ( Nr_Ano = 0 OR Nr_Ano = YEAR(@Data_Dia) ) )
            SET @Data_Dia = @Data_Dia - 1
        ELSE
            BREAK  

    END

    RETURN CAST(FLOOR(CAST(@Data_Dia AS FLOAT)) AS DATETIME)

END
GO


IF (OBJECT_ID('dbo.fncProximo_Dia_Util') IS NOT NULL) DROP FUNCTION [dbo].[fncProximo_Dia_Util]
GO

CREATE FUNCTION [dbo].[fncProximo_Dia_Util] ( @Data_Dia DATETIME )
RETURNS DATETIME
AS
BEGIN 

    WHILE (1 = 1)
    BEGIN

        SET @Data_Dia = @Data_Dia + (CASE DATEPART(WEEKDAY, @Data_Dia) WHEN 1 THEN 1 WHEN 7 THEN 2 ELSE 0 END)

        IF EXISTS ( SELECT TOP 1 Nr_Dia FROM dbo.Feriados WHERE Nr_Dia = DAY(@Data_Dia) AND Nr_Mes = MONTH(@Data_Dia) AND Tp_Feriado = '1' AND ( Nr_Ano = 0 OR Nr_Ano = YEAR(@Data_Dia) ) )
            SET @Data_Dia = @Data_Dia + 1
        ELSE
            BREAK  
    END

    RETURN CAST(FLOOR(CAST(@Data_Dia AS FLOAT)) AS DATETIME)

END
GO


IF (OBJECT_ID('dbo.fncDia_Util') IS NOT NULL) DROP FUNCTION [dbo].[fncDia_Util]
GO

CREATE FUNCTION [dbo].[fncDia_Util] ( @Data_Dia DATETIME )
RETURNS BIT
AS
BEGIN 

    DECLARE @retorno BIT

    IF ( DATEPART(WEEKDAY, @Data_Dia) IN ( 1, 7 ) )
        SET @retorno = 0	
    ELSE
    BEGIN

        IF EXISTS ( SELECT TOP(1) Nr_Dia FROM dbo.Feriados WHERE Nr_Dia = DAY(@Data_Dia) AND Nr_Mes = MONTH(@Data_Dia) AND Tp_Feriado = '1' AND ( Nr_Ano = 0 OR Nr_Ano = YEAR(@Data_Dia) ) )
            SET @retorno = 0
        ELSE
            SET @retorno = 1
        
    END
    
    RETURN @retorno

END
GO


IF (OBJECT_ID('dbo.fncQtde_Dias_Uteis_Mes') IS NOT NULL) DROP FUNCTION [dbo].[fncQtde_Dias_Uteis_Mes]
GO

CREATE FUNCTION dbo.fncQtde_Dias_Uteis_Mes (
    @Dt_Referencia DATETIME
)
RETURNS INT
AS BEGIN

    DECLARE @Retorno INT = 0

    SELECT
        @Retorno = COUNT(*)
    FROM
        dbo.Calendario
    WHERE
        Dt_Referencia < = CONVERT(DATE, @Dt_Referencia)
        AND YEAR(Dt_Referencia) = YEAR(@Dt_Referencia) 
        AND MONTH(Dt_Referencia) = MONTH(@Dt_Referencia) 
        AND Fl_Dia_Util = 1

    RETURN @Retorno

END
GO


IF (OBJECT_ID('dbo.fncQtde_Dias_Uteis_Ano') IS NOT NULL) DROP FUNCTION [dbo].[fncQtde_Dias_Uteis_Ano]
GO

CREATE FUNCTION dbo.fncQtde_Dias_Uteis_Ano (
    @Dt_Referencia DATETIME
)
RETURNS INT
AS BEGIN

    DECLARE @Retorno INT = 0

    SELECT
        @Retorno = COUNT(*)
    FROM
        dbo.Calendario
    WHERE
        Dt_Referencia < = CONVERT(DATE, @Dt_Referencia)
        AND YEAR(Dt_Referencia) = YEAR(@Dt_Referencia) 
        AND Fl_Dia_Util = 1

    RETURN @Retorno

END
GO


IF (OBJECT_ID('dbo.fncAdiciona_Dias_Uteis') IS NOT NULL) DROP FUNCTION [dbo].[fncAdiciona_Dias_Uteis]
GO

CREATE FUNCTION dbo.fncAdiciona_Dias_Uteis(
    @Dt_Referencia [datetime], 
    @Qt_Dias_Uteis [int]
)
RETURNS datetime
AS 
BEGIN


    -- DECLARE @Dt_Referencia DATETIME = '2015-05-02 09:56:57.203'
    
    DECLARE 
        @Data_Retorno DATE,
        @Retorno DATETIME,
        @Hora TIME = @Dt_Referencia,
        @Ranking INT


    DECLARE @Ranking_Dias_Uteis TABLE (
        Ranking INT,
        Dt_Referencia DATETIME
    )

    
    INSERT INTO @Ranking_Dias_Uteis	
    SELECT
        ROW_NUMBER() OVER(ORDER BY Dt_Referencia) AS Ranking,
        Dt_Referencia
    FROM 
        dbo.Calendario
    WHERE 
        Fl_Dia_Util = 1


    SELECT @Ranking = (SELECT Ranking FROM @Ranking_Dias_Uteis WHERE Dt_Referencia = CONVERT(DATE, @Dt_Referencia))


    IF (@Ranking IS NULL)
        SET @Ranking = (SELECT MIN(Ranking) FROM @Ranking_Dias_Uteis WHERE Dt_Referencia >= CONVERT(DATE, @Dt_Referencia))

    
    SELECT @Data_Retorno = Dt_Referencia
    FROM @Ranking_Dias_Uteis
    WHERE Ranking = @Ranking + @Qt_Dias_Uteis
    

    SET @Retorno = CONVERT(DATETIME, CONVERT(VARCHAR(10), @Data_Retorno, 112) + ' ' + CONVERT(VARCHAR(12), @Hora))
    RETURN @Retorno

END
GO


IF (OBJECT_ID('dbo.fncUltimo_Dia_Util') IS NOT NULL) DROP FUNCTION [dbo].[fncUltimo_Dia_Util]
GO

CREATE FUNCTION dbo.fncUltimo_Dia_Util(
    @Dt_Referencia DATETIME
)
RETURNS DATETIME
AS 
BEGIN

    DECLARE
        @Ano INT = YEAR(@Dt_Referencia),
        @Mes INT = MONTH(@Dt_Referencia),
        @Retorno DATETIME


    SELECT @Retorno = MAX(Dt_Referencia)
    FROM dbo.Calendario
    WHERE Nr_Ano = @Ano
    AND Nr_Mes = @Mes
    AND Fl_Dia_Util = 1

    RETURN @Retorno
    
END
GO



---------------------------------------
-- Cria a tabela de calendário
---------------------------------------

SET LANGUAGE 'Brazilian'


IF (OBJECT_ID('dbo.Calendario') IS NOT NULL) DROP TABLE dbo.Calendario
CREATE TABLE dbo.Calendario (
    Id_Data INT,
    Dt_Referencia DATE,
    Nr_Dia TINYINT,
    Nr_Mes TINYINT,
    Nr_Ano INT,

    Dt_Anterior DATE,
    Dt_Proximo_Dia DATE,
    Dt_Ultimo_Dia_Mes DATE,
    Dt_Primeiro_Dia_Mes DATE,

    Dt_Dia_Util_Anterior DATE,
    Dt_Proximo_Dia_Util DATE,
    Fl_Dia_Util BIT,
    Fl_Dia_Util_Incluindo_Sabado BIT,
    Fl_Feriado BIT,
    Fl_Fim_Semana AS ((CASE WHEN DATEPART(WEEKDAY, [Dt_Referencia]) BETWEEN 2 AND 6 THEN 0 ELSE 1 END)),
    Fl_Ano_Bissexto AS (CONVERT(BIT, (CASE
		WHEN DATEPART(YEAR, [Dt_Referencia]) % 4 <> 0 THEN 0
		WHEN DATEPART(YEAR, [Dt_Referencia]) % 100 <> 0 THEN 1
		WHEN DATEPART(YEAR, [Dt_Referencia]) % 400 <> 0 THEN 0
		ELSE 1
	END))),
    Nr_Dia_Semana AS (DATEPART(WEEKDAY, Dt_Referencia)),
    Ds_Dia_Semana AS (DATENAME(WEEKDAY, Dt_Referencia)),
    Nr_Semana INT,
    Nr_Semana_Mes INT,
    Nr_Dia_Ano INT,
    Qt_Dias_Uteis_Mes INT,
    Qt_Dias_Uteis_Ano INT,
    Fl_Ultimo_Dia_Mes BIT,
    Fl_Ultimo_Dia_Util_Mes BIT,
    Nr_Bimestre INT,
    Nr_Trimestre INT,
    Nr_Semestre INT,
    Nm_Mes AS (DATENAME(MONTH, Dt_Referencia)),
    Nm_Mes_Abreviado AS (LEFT(DATENAME(MONTH, Dt_Referencia), 3)),
    Nm_Mes_Ano AS (DATENAME(MONTH, Dt_Referencia) + ' ' + CAST(Nr_Ano AS VARCHAR(4))),
    Nm_Mes_Ano_Abreviado AS (LEFT(DATENAME(MONTH, Dt_Referencia), 3) + '/' + RIGHT(Nr_Ano, 2)),
    Nr_Mes_Ano AS (CAST(CAST(Nr_Ano AS VARCHAR(4)) + RIGHT('0' + CAST(Nr_Mes AS VARCHAR(2)), 2) AS INT)),
    Nr_Quinzena AS (CASE WHEN Nr_Dia <= 15 THEN 1 ELSE 2 END),
    Ds_Semana AS (CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + CAST(Nr_Semana AS VARCHAR(2)) + 'a Semana'),
    Ds_Quinzena AS (CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + (CASE WHEN Nr_Dia <= 15 THEN '1a Quinzena' ELSE '2a Quinzena' END)),
    Ds_Bimestre AS (CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + CAST(Nr_Bimestre AS VARCHAR(2)) + 'o Bimestre'),
    Ds_Trimestre AS (CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + CAST(Nr_Trimestre AS VARCHAR(2)) + 'o Trimestre'),
    Ds_Semestre AS (CAST(Nr_Ano AS VARCHAR(4)) + ' - ' + CAST(Nr_Semestre AS VARCHAR(2)) + 'o Semestre')
)


DECLARE
    @Dt_Inicial DATETIME = (SELECT MIN(Dt_Inicial) FROM [#Datas]),
    @Dt_Final DATETIME = (SELECT MAX([Dt_Final]) FROM [#Datas])

DECLARE @Dt_Primeira_Data DATE = @Dt_Inicial


;WITH generateRandomNumbers(i) AS (
    SELECT 0
    FROM        (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS x1(i)
    CROSS APPLY (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS x2(i)
    CROSS APPLY (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS x3(i)
),
generateNumbers(i) AS (
    SELECT TOP (DATEDIFF(DAY, @Dt_Inicial, @Dt_Final)+1)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL))-1
    FROM generateRandomNumbers AS x1, generateRandomNumbers AS x2
),
generateDates([date], [Fl_Dia_Util]) AS (
    SELECT 
        DATEADD(DAY, i, @Dt_Inicial) AS [date],
        dbo.fncDia_Util(DATEADD(DAY, i, @Dt_Inicial)) AS Fl_Dia_Util
    FROM generateNumbers
)
INSERT INTO dbo.[Calendario]
(
    [Id_Data],
    [Dt_Referencia],
    [Nr_Dia],
    [Nr_Mes],
    [Nr_Ano],

    [Dt_Anterior],
    [Dt_Proximo_Dia],
    [Dt_Ultimo_Dia_Mes],
    [Dt_Primeiro_Dia_Mes],

    [Dt_Dia_Util_Anterior],
    [Dt_Proximo_Dia_Util],
    [Fl_Dia_Util],
    [Fl_Dia_Util_Incluindo_Sabado],
    [Fl_Feriado],
    [Nr_Semana],
    [Nr_Semana_Mes],
    [Nr_Dia_Ano],
    [Fl_Ultimo_Dia_Mes],

    [Nr_Bimestre],
    [Nr_Trimestre],
    [Nr_Semestre],

    [Qt_Dias_Uteis_Mes],
    [Qt_Dias_Uteis_Ano],
    [Fl_Ultimo_Dia_Util_Mes]
)
SELECT
    DATEDIFF(DAY, @Dt_Primeira_Data, [date]) + 1 AS Id_Data,
    [date] AS Dt_Referencia, 
    DATEPART(DAY, [date]) AS Nr_Dia,
    DATEPART(MONTH, [date]) AS Nr_Mes,
    DATEPART(YEAR, [date]) AS Nr_Ano,

    DATEADD(DAY, -1, [date]) AS Dt_Anterior,
    DATEADD(DAY, 1, [date]) AS Dt_Proximo_Dia,
    EOMONTH([date]) AS Dt_Ultimo_Dia_Mes,
    DATEADD(DAY, -DAY([date]) + 1, [date]) AS Dt_Primeiro_Dia_Mes,

    dbo.fncDia_Util_Anterior(DATEADD(DAY, -1, [date])) AS Dt_Dia_Util_Anterior,
    dbo.fncProximo_Dia_Util(DATEADD(DAY, 1, [date])) AS Dt_Proximo_Dia_Util,

    [Fl_Dia_Util],
    (CASE WHEN DATEPART(WEEKDAY, [date]) = 1 OR EXISTS(SELECT TOP(1) Nr_Dia FROM dbo.Feriados WHERE Nr_Dia = DAY([date]) AND Nr_Mes = MONTH([date]) AND Tp_Feriado = '1' AND (Nr_Ano = 0 OR Nr_Ano = YEAR([date]))) THEN 0 ELSE 1 END) AS Fl_Dia_Util_Incluindo_Sabado,
    (CASE WHEN EXISTS(SELECT TOP(1) Nr_Dia FROM dbo.Feriados WHERE Nr_Dia = DAY([date]) AND Nr_Mes = MONTH([date]) AND Tp_Feriado = '1' AND (Nr_Ano = 0 OR Nr_Ano = YEAR([date]))) THEN 1 ELSE 0 END) AS Fl_Feriado,
        
    DATEPART(WEEK, [date]) AS Nr_Semana,
    DATEPART(WEEK, [date]) - DATEPART(WEEK, [date] - DATEPART(DAY, [date]) + 1) + 1 AS Nr_Semana_Mes,
    DATEPART(DAYOFYEAR, [date]) AS Nr_Dia_Ano,
    (CASE WHEN [date] = EOMONTH([date]) THEN 1 ELSE 0 END) AS [Fl_Ultimo_Dia_Mes],

    (CEILING((DATEPART(MONTH, [date]) * 1.0) / 2)) AS Nr_Bimestre,
    (CEILING((DATEPART(MONTH, [date]) * 1.0) / 3)) AS Nr_Trimestre,
    (CEILING((DATEPART(MONTH, [date]) * 1.0) / 6)) AS Nr_Semestre,

    0 AS [Qt_Dias_Uteis_Mes],
    0 AS [Qt_Dias_Uteis_Ano],
    0 AS [Fl_Ultimo_Dia_Util_Mes]
FROM
    [generateDates]

   

UPDATE [dbo].[Calendario]
SET
    [Qt_Dias_Uteis_Mes] = dbo.[fncQtde_Dias_Uteis_Mes]([Dt_Referencia]),
    [Qt_Dias_Uteis_Ano] = dbo.[fncQtde_Dias_Uteis_Ano]([Dt_Referencia]),
    [Fl_Ultimo_Dia_Util_Mes] = (CASE WHEN [Dt_Referencia] = dbo.[fncUltimo_Dia_Util]([Dt_Referencia]) THEN 1 ELSE 0 END)


CREATE CLUSTERED INDEX Idx01 ON dbo.Calendario(Dt_Referencia)

-- Fonte: https://dirceuresende.com/blog/sql-server-e-azure-sql-como-criar-uma-tabela-de-calendario-utilizando-sql-incluindo-feriados/