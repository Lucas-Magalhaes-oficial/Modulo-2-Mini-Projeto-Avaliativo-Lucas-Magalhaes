INSERT INTO dim_categoria (sk_categoria, categoria_origem, nome_categoria, grupo_categoria)
VALUES (-1, 'Nao Informado', 'Nao Informado', 'Nao Informado');

INSERT INTO dim_categoria (categoria_origem, nome_categoria, grupo_categoria)
SELECT DISTINCT
    "CategoriaProduto",
    CASE
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%MED%'   THEN 'Medicamento'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%PETISC%' THEN 'Petisco'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%RA%'     THEN 'Racao'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%HIG%'    THEN 'Higiene'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%BRINQ%'  THEN 'Brinquedo'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%ACESS%'  THEN 'Acessorio'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%SERV%'   THEN 'Servico'
        ELSE 'Nao Informado'
    END,
    CASE
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%MED%'   THEN 'Saude e Higiene'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%PETISC%' THEN 'Alimentacao'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%RA%'     THEN 'Alimentacao'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%HIG%'    THEN 'Saude e Higiene'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%BRINQ%'  THEN 'Bem-estar'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%ACESS%'  THEN 'Bem-estar'
        WHEN TRANSLATE(UPPER("CategoriaProduto"), 'ÁÀÂÃÉÈÊÍÓÔÕÚÇ', 'AAAAEEIOOOUC') LIKE '%SERV%'   THEN 'Bem-estar'
        ELSE 'Nao Informado'
    END
FROM stg_pedido;

-- ---------------------------------------------------------------------------
-- DIM_PRACA  ->  grao: uma praca de atendimento
-- DomiciliosComPet vem com ponto de milhar ('148.000' = 148 mil)
-- ---------------------------------------------------------------------------
INSERT INTO dim_praca (sk_praca, cod_praca, nome_praca, regional, domicilios_com_pet)
VALUES (-1, 'N/I', 'Nao Informado', 'Nao Informado', NULL);

INSERT INTO dim_praca (cod_praca, nome_praca, regional, domicilios_com_pet)
SELECT DISTINCT
    "CodPraca",
    "NomePraca",
    "Regional",
    CAST(REPLACE("DomiciliosComPet", '.', '') AS INTEGER)
FROM stg_loja_praca;

-- ---------------------------------------------------------------------------
-- BRIDGE_LOJA_PRACA  ->  grao: uma loja x uma praca
-- Ligada pelo COD da loja, e nao pela sk_loja
-- ---------------------------------------------------------------------------
INSERT INTO bridge_loja_praca (cod_loja, sk_praca, fator_publico)
SELECT
    sp."CodLoja",
    dp.sk_praca,
    CAST(sp."PercentualPublico" AS DECIMAL(6,4))
FROM stg_loja_praca sp
JOIN dim_praca dp ON dp.cod_praca = sp."CodPraca";