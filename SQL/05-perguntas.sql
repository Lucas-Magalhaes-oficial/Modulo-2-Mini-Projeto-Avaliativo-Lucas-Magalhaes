-- =====================================================================================
--  ARQUIVO 5:  AS CINCO PERGUNTAS DE NEGOCIO
--  Case: Pata Amiga  |  PostgreSQL 16
-- =====================================================================================

-- =====================================================================================
--  P1 - ONDE ESTA O GARGALO DA ENTREGA?
-- =====================================================================================
SELECT l.porte AS porte,
       ROUND(AVG(f.dias_integracao_separacao), 1) AS media_integracao_separacao,
       ROUND(AVG(f.dias_separacao_nota), 1)        AS media_separacao_nota,
       ROUND(AVG(f.dias_nota_despacho), 1)         AS media_nota_despacho,
       ROUND(AVG(f.dias_despacho_entrega), 1)      AS media_despacho_entrega,
       ROUND(AVG(f.dias_total_ate_entrega), 1)     AS media_total_ate_entrega
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
GROUP BY l.porte
UNION ALL
SELECT 'REDE (todos os portes)',
       ROUND(AVG(f.dias_integracao_separacao), 1),
       ROUND(AVG(f.dias_separacao_nota), 1),
       ROUND(AVG(f.dias_nota_despacho), 1),
       ROUND(AVG(f.dias_despacho_entrega), 1),
       ROUND(AVG(f.dias_total_ate_entrega), 1)
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
ORDER BY porte;

-- =====================================================================================
--  P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================
SELECT c.nome_categoria,
       ROUND(SUM(f.vl_liquido)) AS faturamento,
       ROUND(100.0 * SUM(f.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total
FROM fato_pedido f
JOIN dim_categoria c ON c.sk_categoria = f.sk_categoria
GROUP BY c.nome_categoria
ORDER BY faturamento DESC;

-- =====================================================================================
--  P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================
SELECT canal_pedido,
       ROUND(AVG(CASE WHEN houve_desconto = 'Sim' THEN vl_liquido END), 2) AS ticket_medio_com_desconto,
       ROUND(AVG(CASE WHEN houve_desconto = 'Nao' THEN vl_liquido END), 2) AS ticket_medio_sem_desconto,
       ROUND(100.0 * SUM(vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_faturamento
FROM fato_pedido
GROUP BY canal_pedido
ORDER BY canal_pedido;

-- =====================================================================================
--  P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================
SELECT pr.nome_praca,
       ROUND(SUM(f.vl_liquido * b.fator_publico)) AS faturamento_rateado,
       ROUND(100.0 * SUM(f.vl_liquido * b.fator_publico) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
JOIN bridge_loja_praca b ON b.cod_loja = l.cod_loja
JOIN dim_praca pr ON pr.sk_praca = b.sk_praca
GROUP BY pr.nome_praca
ORDER BY faturamento_rateado DESC;

-- =====================================================================================
--  P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================

-- (a) Ranking de lojas por itens vendidos por mil habitantes, cruzado com o tempo medio de entrega
SELECT l.nome_loja,
       l.porte,
       SUM(f.qt_itens) AS itens_vendidos,
       l.populacao_cidade,
       ROUND(1000.0 * SUM(f.qt_itens) / l.populacao_cidade, 2) AS itens_por_mil_habitantes,
       ROUND(AVG(f.dias_total_ate_entrega), 1) AS tempo_medio_entrega
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE l.sk_loja <> -1
GROUP BY l.nome_loja, l.porte, l.populacao_cidade
ORDER BY itens_por_mil_habitantes DESC;

-- (b) Faturamento por faixa de franquia ATUAL (foto de hoje, nao a da data do pedido)
SELECT l.faixa_franquia,
       ROUND(SUM(f.vl_liquido)) AS faturamento,
       ROUND(100.0 * SUM(f.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
GROUP BY l.faixa_franquia
ORDER BY faturamento DESC;

-- (c) O que ficou de fora
SELECT 'pedidos sem loja identificada' AS o_que_ficou_de_fora, COUNT(*) AS quantidade FROM fato_pedido WHERE sk_loja = -1
UNION ALL SELECT 'entregas ainda nao concluidas', COUNT(*) FROM fato_pedido WHERE sk_tempo_entrega = -1
UNION ALL SELECT 'pedidos com itens em branco (NULL)', COUNT(*) FROM fato_pedido WHERE qt_itens IS NULL
UNION ALL SELECT 'pedidos com valor em branco (NULL)', COUNT(*) FROM fato_pedido WHERE vl_liquido IS NULL;