-- Criando a base de testes

-------------------------------------
-- Cria a tabela com dados de teste
-------------------------------------

DROP TABLE IF EXISTS #Hierarquia_Vendas
CREATE TABLE #Hierarquia_Vendas (
    Cd_Vendedor INT NOT NULL,
    Cd_Superior INT NULL
)

INSERT INTO #Hierarquia_Vendas
VALUES 
    ( 301, NULL ),
    ( 209, 301 ),
    ( 576, 301 ),
    ( 111, 209 ),
    ( 112, 209 ),
    ( 123, 576 ),
    ( 444, 576 )


DROP TABLE IF EXISTS #Vendas
CREATE TABLE #Vendas (
    Cd_Vendedor INT NOT NULL,
    Venda NUMERIC(18, 2) NOT NULL
)

INSERT INTO #Vendas
VALUES
    (301, 25),
    (209, 30),
    (111, 80),
    (112, 70),
    (576, 50),
    (123, 100),
    (444, 120)

-- Select:
--------------------------------------------------------
-- Cria a tabela com dados de teste
--------------------------------------------------------

DROP TABLE IF EXISTS #Hierarquia_Vendas
CREATE TABLE #Hierarquia_Vendas (
    Cd_Vendedor INT NOT NULL,
    Cd_Superior INT NULL
)

INSERT INTO #Hierarquia_Vendas
VALUES 
    ( 301, NULL ),
    ( 209, 301 ),
    ( 576, 301 ),
    ( 111, 209 ),
    ( 112, 209 ),
    ( 123, 576 ),
    ( 444, 576 )


DROP TABLE IF EXISTS #Vendas
CREATE TABLE #Vendas (
    Cd_Vendedor INT NOT NULL,
    Venda NUMERIC(18, 2) NOT NULL
)

INSERT INTO #Vendas
VALUES
    (301, 25),
    (209, 30),
    (111, 80),
    (112, 70),
    (576, 50),
    (123, 100),
    (444, 120)


--------------------------------------------------------
-- Cria o nível de profundidade e a string de hierarquia
--------------------------------------------------------

DROP TABLE IF EXISTS #Base;

-- Vou utilizar essa CTE resursiva para gerar o nível de profundidade e a string da hierarquia
;WITH cte AS (

    -- Nivel 1
    SELECT 
        1 AS Nivel,
        CONVERT(VARCHAR(MAX), CONCAT('', [Cd_Vendedor])) AS Hierarquia,
        [Cd_Superior],
        [Cd_Vendedor]
    FROM
        [#Hierarquia_Vendas]
    WHERE
        [Cd_Superior] IS NULL

    UNION ALL

    -- Nivel 2->N
    SELECT 
        B.[Nivel] + 1 AS Nivel,
        CONVERT(VARCHAR(MAX), CONCAT(B.[Hierarquia], '-', A.[Cd_Vendedor])) AS Hierarquia,
        A.[Cd_Superior],
        A.[Cd_Vendedor]
    FROM
        [#Hierarquia_Vendas] A
        JOIN [cte] B ON [A].[Cd_Superior] = [B].[Cd_Vendedor]
        
)
SELECT
    A.[Nivel],
    A.[Cd_Vendedor],
    A.[Cd_Superior],
    A.[Hierarquia],
    ISNULL([B].[Venda], 0) AS Venda,
    
    -- Coluna que vai guardar a venda da equipe
    CAST(NULL AS NUMERIC(18, 2)) AS Venda_Equipe,
    
    -- Coluna utilizada para ordenar os resultados
    ROW_NUMBER() OVER(ORDER BY ISNULL(A.[Hierarquia], -1)) AS Ordem
INTO
    #Base
FROM
    cte AS A
    LEFT JOIN [#Vendas] B ON [A].[Cd_Vendedor] = [B].[Cd_Vendedor]
    


--------------------------------------------------------
-- Calcula a venda por equipe de forma agregada
--------------------------------------------------------

DECLARE
    @MenorNivel INT = 1,
    @NivelAtual INT = (SELECT MAX(Nivel) FROM [#Base])

-- Calcula do maior do nível para o menor
WHILE(@NivelAtual >= @MenorNivel)
BEGIN
    

    -- Atualiza a coluna "Venda_Equipe" com a soma das vendas do nível acima para o mesmo superior
    UPDATE A
    SET
        A.[Venda_Equipe] = ISNULL(A.[Venda], 0) + ISNULL(B.[Venda_Equipe], 0)
    FROM
        [#Base] A
        LEFT JOIN (
            SELECT 
                ISNULL([Cd_Superior], -1) AS Cd_Superior,
                SUM(ISNULL([Venda_Equipe], 0)) AS Venda_Equipe
            FROM
                [#Base]
            WHERE
                [Nivel] = @NivelAtual + 1
            GROUP BY
                ISNULL([Cd_Superior], -1)
        ) B ON A.[Cd_Vendedor] = B.[Cd_Superior]
    WHERE
        A.[Nivel] = @NivelAtual


    SET @NivelAtual -= 1 -- Vai reduzindo o nível até acabar
    

END


--------------------------------------------------------
-- Executa a consulta final
--------------------------------------------------------

-- Opção 1: Nova coluna com a venda da equipe
SELECT * FROM [#Base]


-- Opção 2: Novas linhas com a venda da equipe
;WITH cteFinal 
AS (
    SELECT
        [Nivel],
        [Hierarquia],
        [Venda],
        'Venda Direta' AS Agrupador,
        [Ordem]
    FROM 
        [#Base]

    UNION ALL

    SELECT 
        [Nivel],
        [Hierarquia],
        [Venda_Equipe],
        'Total Venda Equipe' AS Agrupador,
        [Ordem]
    FROM 
        [#Base]
)
SELECT 
    [Nivel],
    [Hierarquia],
    [Venda],
    [Agrupador]
FROM
    [cteFinal]
ORDER BY
    [Ordem],
    IIF(Agrupador = 'Venda Direta', 1, 2)

-- Fonte: https://dirceuresende.com/blog/sql-server-e-azure-sql-desafio-para-agrupar-dados-utilizando-hierarquias/    