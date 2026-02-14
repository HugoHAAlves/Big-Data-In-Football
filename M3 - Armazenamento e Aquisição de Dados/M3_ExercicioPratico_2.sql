USE golos;

/*EXPLORAÇÃO*/
SHOW TABLES;

SELECT * FROM equipa LIMIT 100;
SELECT COUNT(*) FROM equipa;
SELECT * FROM jogador LIMIT 100;
SELECT COUNT(*) FROM jogador;
SELECT * FROM jogo LIMIT 100;
SELECT COUNT(*) FROM jogo;
-- Apesar de a tabela se chamar "jogo", parece ter granularidade ao nível dos golos dentro de cada jogo

/*
NOTA: Para garantir resultados mais seguros, iremos tendencialmente optar por contar os valores distintos dos IDs relevantes
ao invés de contar apenas as linhas (COUNT(*)).
*/

/* ====================================================================== 
1. Quantos jogos aconteceram na época 2020/2021?
====================================================================== */
-- Vamos confirmar que só temos dados de uma época nesta tabela
SELECT DISTINCT(Epoca) FROM jogo;

-- Assim sendo, basta fazer uma seleção dos ID's de jogo únicos.
-- O filtro da época é acrescentado para segurança futura, caso venham a ser acrescentadas novas épocas na tabela
SELECT COUNT(DISTINCT(ID_Jogo))
FROM jogo
WHERE Epoca = '2020';

-- RESPOSTA: Houve 269 jogos (registados) na época 2020/2021.


/* ====================================================================== 
2. Quantos golos foram marcados?
====================================================================== */
-- Mesma lógica da pergunta anterior
SELECT COUNT(DISTINCT(ID_Golo))
FROM jogo;
-- WHERE Epoca = '2020'; # descomentar se a intenção for saber os golos marcados nesta época (neste caso não faz diferença)

-- RESPOSTA: Foram marcados 703 golos.


/* ====================================================================== 
3. Qual/quais o(s) jogador(es) com mais golos e com quantos golos?
====================================================================== */
-- Para responder a esta questão, começamos por criar uma CTE com os golos marcados por jogador.
-- Depois, no SELECT final, filtramos apenas pelos jogadores que marcaram o número máximo de golos marcados por um único jogador.
WITH golos_por_jogador AS (
    SELECT 
        j.Nome_Jogador,
        COUNT(DISTINCT(g.ID_Golo)) AS Numero_Golos
	FROM jogador AS j
    JOIN jogo AS g -- (inner join)
        ON j.ID_Jogador = g.ID_Jogador
    GROUP BY j.ID_Jogador
)
SELECT
	Nome_Jogador,
    Numero_Golos
FROM golos_por_jogador
WHERE Numero_Golos = (
    SELECT MAX(Numero_Golos)
    FROM golos_por_jogador
);

-- RESPOSTA: Os melhores marcadores foram Seferovic e Pedro Gonçalves (Pote), ambos com 21 golos.


/* ====================================================================== 
4. Qual/Quais o(s) jogador(es) mais alto(s) da 1ªLiga? 
====================================================================== */
-- A partir da tabela jogador, podemos selecionar o nome e a altura dos jogadores cuja altura seja máxima.
SELECT
	Nome_Jogador,
    Altura
FROM jogador
WHERE Altura = (
    SELECT MAX(Altura)
    FROM jogador
);

-- RESPOSTA: Os jogadores mais altos da 1ª Liga são Abdoulaye Ba, Abdel Medioub, Edwin Banguera, e Magrão, com 1.97m.


/* ====================================================================== 
5. Qual a equipa que marcou mais golos? 
====================================================================== */
-- Podemos aplicar a mesma lógica que para os jogadores (ex.3), usando desta vez a informação da tabela "equipa"
WITH golos_por_equipa AS (
    SELECT 
        e.Nome_Equipa,
        COUNT(DISTINCT(g.ID_Golo)) AS Numero_Golos
    FROM equipa AS e
    JOIN jogo AS g
        ON e.ID_Equipa = g.ID_Equipa
    GROUP BY e.ID_Equipa
)
SELECT
	Nome_Equipa,
    Numero_Golos
FROM golos_por_equipa
WHERE Numero_Golos = (
    SELECT MAX(Numero_Golos)
    FROM golos_por_equipa
);

-- RESPOSTA: A equipa com mais golos marcados (69) foi o FC Porto.


/* ====================================================================== 
6. Em qual das partes foram marcados mais golos?
====================================================================== */
-- Neste caso em concreto, podemos simplesmente contar os golos marcados em cada parte e retornar ambos os valores.
SELECT
	ID_Parte AS Parte,
    COUNT(DISTINCT(ID_Golo)) AS Numero_Golos
FROM jogo
GROUP BY ID_Parte;

-- RESPOSTA: Foram marcados mais golos (360) na segunda parte dos jogos.


/* ====================================================================== 
7. Selecione o número de marcadores com nacionalidade espanhola. 
====================================================================== */
-- Através da análise inicial da tabela na parte de exploração, pudemos verificar que a nacionalidade dos jogadores
-- (e a sua posição) se encontra escrita em inglês.
SELECT COUNT(DISTINCT(g.ID_Jogador)) AS Jogadores_Espanhois
FROM jogo AS g
JOIN jogador AS j
	ON g.ID_Jogador = j.ID_jogador
WHERE j.Nacionalidade = 'Spain';

-- RESPOSTA: Houve 8 marcadores espanhóis.


/* ====================================================================== 
8. Quantos golos fora teve o Santa Clara?
====================================================================== */
-- Aqui, temos de considerar uma segunda condição ao fazer o join. Não só o ID da equipa que marcou tem de ser associado ao correspondente
-- na tabela "equipa", como esse mesmo ID tem de ser o mesmo da equipa visitante, de modo a filtrar os golos apenas pelos que foram marcados
-- pela equipa visitante. O operador WHERE permite obter dados apenas para o Santa Clara (poderíamos também usar o HAVING depois do GROUP BY).
SELECT 
	e.Nome_Equipa,
	COUNT(DISTINCT(g.ID_Golo)) AS Numero_Golos
FROM equipa AS e
JOIN jogo AS g
	ON e.ID_Equipa = g.ID_Equipa AND
    g.ID_Equipa = g.ID_Equipa_Visitante
WHERE e.Nome_Equipa = 'Santa Clara'
GROUP BY e.ID_Equipa;

-- RESPOSTA: O Santa Clara marcou 14 golos a jogar fora de casa.


/* ====================================================================== 
9. Qual a idade do jogador mais velho a marcar golo de penalidade? 
====================================================================== */
-- Para variar um pouco a abordagem, ao invés de criar uma CTE, vamos agora utilizar uma subquery (criada já dentro do SELECT)
-- para devolver o nome e idade de todos os jogadores que marcaram grandes penalidades. Vamos também captar o máximo
-- dessas idades numa coluna auxiliar (que terá o nome de "Mais_Velho") e usar esse valor para filtrar o resultado final,
-- mostrando apenas o(s) jogador(es) mais velho(s) a marcar desta forma.
-- Esta abordagem dará um resultado semelhante ao que teríamos se utilizássemos uma lógica semelhante às dos exercícios anteriores
-- com CTEs, e a performance também será a mesma. Poderíamos confirmar isto mesmo incluindo o comando EXPLAIN antes de cada opção
-- (CTE vs subquery) e validar que o plano de execução seria exatamente igual. Por isso, nos restantes exercícios vamos voltar
-- ao uso de CTEs, que habitualmente são de mais fácil leitura e interpretação.
SELECT
	Nome_Jogador,
    Idade
FROM (
	SELECT
		j.Nome_Jogador,
		j.Idade,
        MAX(j.IDADE) OVER() AS Mais_Velho
	FROM jogador AS j
	JOIN jogo AS g
		ON j.ID_Jogador = g.ID_Jogador
		AND g.Penalti = 1
) AS Marcadores_Penaltis
WHERE Idade = Mais_Velho;

-- RESPOSTA: O jogador mais velho a marcar de grande penalidade (Ukra), tinha 33 anos.


/* ====================================================================== 
10. Qual o minuto onde foram marcados mais golos?
====================================================================== */
-- Podemos agrupar os golos pela coluna "Minuto" para ver aquele(s) em que foram marcados mais golos.
-- Será utilizada uma lógica semelhante às dos exercícios 3 e 5, com uma CTE no início para captar os golos por minuto.
WITH golos_por_minuto AS (
	SELECT
		Minuto,
		COUNT(DISTINCT(ID_Golo)) AS Numero_Golos
	FROM jogo
    GROUP BY Minuto
)
SELECT
	Minuto,
    Numero_Golos
FROM golos_por_minuto
WHERE Numero_Golos = (
    SELECT MAX(Numero_Golos)
    FROM golos_por_minuto
);

-- RESPOSTA: O minuto 77 foi aquele em que foram marcados mais golos (15).


/* ====================================================================== 
11. Foram marcados mais golos de pé esquerdo ou de pé direito? 
====================================================================== */
-- Vamos somar as colunas binárias "Pe_Direito" e "Pe_Esquerdo" para responder a esta pergunta.
-- Eventualmente, poderia ser mais seguro contar os IDs distintos dos golos marcados com cada pé. Contudo, como nesta fase
-- já estamos relativamente seguros que a tabela está bem trabalhada e cada linha é um golo (sem duplicados), vamos recorrer
-- à função SUM() para diversificar a abordagem.

-- Vamos só confirmar que não existem valores estranhos em que um golo tenha sido marcado com os dois pés.
SELECT * FROM jogo WHERE Pe_Direito = 1 AND Pe_Esquerdo = 1;

-- Ótimo, podemos avançar.
SELECT COUNT(DISTINCT ID_Golo) FROM jogo; -- 703 linhas
SELECT COUNT(*) FROM jogo; -- 703 linhas, logo cada linha é um golo (ID_Golo) único

SELECT
	SUM(Pe_Direito) AS Golos_Pé_Direito,
    SUM(Pe_Esquerdo) AS Golos_Pé_Esquerdo
FROM jogo;

-- Se preferirmos, ainda assim, contar IDs únicos (o resultado será o mesmo)
SELECT
	'Golos de Pé Direito' AS Tipo,
    COUNT(DISTINCT(ID_Golo)) AS Numero_Golos
FROM jogo
WHERE Pe_Direito = 1

UNION

SELECT
	'Golos de Pé Esquerdo' AS Tipo,
    COUNT(DISTINCT(ID_Golo)) AS Numero_Golos
FROM jogo
WHERE Pe_Esquerdo = 1;

-- RESPOSTA: Foram marcados mais golos com o pé direito (370) do que com o pé esquerdo (204).


/* ====================================================================== 
12. Qual a posição mais propensa a marcar golos?
====================================================================== */
-- A lógica será exatamente a mesma que a aplicada no ex.5 para determinar os jogadores com mais golos.
-- Agora, em vez de usarmos o nome do jogador, vamos usar a sua posição.
WITH golos_por_posicao AS (
    SELECT 
        j.Posicao,
        COUNT(DISTINCT(g.ID_Golo)) AS Numero_Golos
    FROM jogador AS j
    JOIN jogo AS g
        ON j.ID_Jogador = g.ID_Jogador
    GROUP BY j.Posicao
)
SELECT
	Posicao,
    Numero_Golos
FROM golos_por_posicao
WHERE Numero_Golos = (
    SELECT MAX(Numero_Golos)
    FROM golos_por_posicao
);

-- RESPOSTA: Sem surpresas, os avançados (forwards) foram aqueles que marcaram mais golos (364).


/* ====================================================================== 
13. Quantos jogadores distintos marcaram golo pelo Paços de Ferreira?
====================================================================== */
-- Vamos filtrar apenas pelos golos marcados pelo Paços de Ferreira.
-- Depois, no SELECT, contamos os ID_Jogador distintos para chegar à resposta.
SELECT COUNT(DISTINCT(g.ID_Jogador)) AS Numero_Jogadores
FROM jogo AS g
JOIN equipa AS e
	ON g.ID_Equipa = e.Id_Equipa
WHERE e.Nome_Equipa = 'Paços de Ferreira';

-- RESPOSTA: Houve 11 jogadores diferentes que marcaram pelo Paços de Ferreira nesta época.


/* ========================================================================================= 
14. Selecione o nome, posição, equipa e número de golos de cada atleta, ordenado por equipa?
========================================================================================= */
-- O ponto de partida desta query será utilizar a tabela "jogo" para obter o número de golos marcados por jogador e por equipa.
-- É importante ter em consideração que um jogador que tenha marcado por 2 equipas nesta época vai aparecer duas vezes, contando os
-- golos por cada uma das equipas. Depois, será apenas necessário fazer um JOIN com as outras duas tabelas para devolver os nomes
-- dos jogadores e equipas, aplicando o ORDER BY para ordenar por equipa (por definição, será apresentado por ordem alfabética crescente).
WITH golos AS (
	SELECT
		ID_Jogador,
        ID_Equipa,
        COUNT(DISTINCT(ID_Golo)) AS Numero_Golos
	FROM jogo
    GROUP BY ID_Jogador, ID_Equipa
)
SELECT
	j.Nome_Jogador,
    j.Posicao,
    e.Nome_Equipa,
    g.Numero_Golos
FROM golos AS g
JOIN jogador AS j
	ON g.ID_Jogador = j.ID_Jogador
JOIN equipa AS e
	ON g.ID_Equipa = e.ID_Equipa
ORDER BY e.Nome_Equipa;