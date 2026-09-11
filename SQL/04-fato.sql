-- =====================================================================================
--  ARQUIVO 4:  CONSTRUIR A FATO (fato_pedido)
--  Case: Pata Amiga  |  PostgreSQL 16
-- =====================================================================================
--  Rode depois de: 01, 02 e 03
-- =====================================================================================

INSERT INTO fato_pedido (
    numero_pedido, sk_tempo_pedido, sk_tempo_entrega, sk_loja, sk_categoria,
    houve_desconto, canal_pedido, dt_pedido, qt_itens, vl_liquido,
    dias_integracao_separacao, dias_separacao_nota, dias_nota_despacho,
    dias_despacho_entrega, dias_total_ate_entrega
)
SELECT
    sp."NumeroPedido",
    TO_CHAR(TO_TIMESTAMP(sp."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM'), 'YYYYMMDD')::int,
    CASE WHEN sp."DtEntregaCliente" = '' THEN -1
         ELSE TO_CHAR(sp."DtEntregaCliente"::date, 'YYYYMMDD')::int END,
    COALESCE(dl_cod.sk_loja, dl_nome.sk_loja, -1),
    COALESCE(dc.sk_categoria, -1),
    CASE
        WHEN UPPER(TRIM(sp."HouveDesconto")) IN ('S','SIM','1','X','TRUE','V') THEN 'Sim'
        WHEN UPPER(TRIM(sp."HouveDesconto")) IN ('N','NAO','0','FALSE','F')    THEN 'Nao'
        ELSE 'Nao Informado'
    END,
    CASE
        WHEN UPPER(sp."CanalPedido") LIKE '%WHATS%' THEN 'WhatsApp'
        WHEN UPPER(sp."CanalPedido") LIKE '%APP%'   THEN 'App'
        WHEN UPPER(sp."CanalPedido") LIKE '%SITE%'  THEN 'Site'
        WHEN UPPER(sp."CanalPedido") LIKE '%LOJA%'  THEN 'Loja Fisica'
        WHEN UPPER(sp."CanalPedido") LIKE '%TEL%'   THEN 'Telefone'
        ELSE 'Nao Informado'
    END,
    TO_TIMESTAMP(sp."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM'),
    CASE WHEN TRIM(sp."QTD.Itens") IN ('','-') THEN NULL
         ELSE CAST(sp."QTD.Itens" AS INTEGER) END,
    CASE WHEN TRIM(REPLACE(sp."ValorLiquidoPedido(R$)",'R$','')) IN ('','-') THEN NULL
         WHEN sp."ValorLiquidoPedido(R$)" LIKE '%,%'
             THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(sp."ValorLiquidoPedido(R$)",'R$',''),' ',''),'.',''),',','.')
                  AS DECIMAL(15,2))
         ELSE CAST(REPLACE(REPLACE(sp."ValorLiquidoPedido(R$)",'R$',''),' ','') AS DECIMAL(15,2))
    END,
    CASE WHEN sp."Dt Separacao Estoque" = '' THEN NULL
         ELSE sp."Dt Separacao Estoque"::date - TO_TIMESTAMP(sp."DtHoraIntegracaoERP",'MM/DD/YYYY HH12:MI AM')::date END,
    CASE WHEN sp."Dt Separacao Estoque" = '' OR sp."DtNotaFiscal" = '' THEN NULL
         ELSE sp."DtNotaFiscal"::date - sp."Dt Separacao Estoque"::date END,
    CASE WHEN sp."DtNotaFiscal" = '' OR sp."Dt_Despacho_Transportadora" = '' THEN NULL
         ELSE sp."Dt_Despacho_Transportadora"::date - sp."DtNotaFiscal"::date END,
    CASE WHEN sp."Dt_Despacho_Transportadora" = '' OR sp."DtEntregaCliente" = '' THEN NULL
         ELSE sp."DtEntregaCliente"::date - sp."Dt_Despacho_Transportadora"::date END,
    CASE WHEN sp."DtEntregaCliente" = '' THEN NULL
         ELSE sp."DtEntregaCliente"::date - TO_TIMESTAMP(sp."DtHoraIntegracaoERP",'MM/DD/YYYY HH12:MI AM')::date END

FROM stg_pedido sp

LEFT JOIN dim_loja dl_cod
    ON dl_cod.cod_loja = TRIM(sp."Cod Loja") AND TRIM(sp."Cod Loja") <> ''

LEFT JOIN dim_loja dl_nome
    ON dl_nome.chave_loja =
        CASE
            WHEN TRANSLATE(UPPER(TRIM(REPLACE(REPLACE(sp."Loja-Nome",'/SC',''),'  ',' '))),
                 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç','AAAAEEIOOOUUCAAAAEEIOOOUUC') = 'PATA AMIGA BLUMENAL CENTRO'
                THEN 'PATA AMIGA BLUMENAU CENTRO'
            WHEN TRANSLATE(UPPER(TRIM(REPLACE(REPLACE(sp."Loja-Nome",'/SC',''),'  ',' '))),
                 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç','AAAAEEIOOOUUCAAAAEEIOOOUUC') = 'PATA AMIGA FLORIPA NORTE'
                THEN 'PATA AMIGA FLORIANOPOLIS NORTE'
            WHEN TRANSLATE(UPPER(TRIM(REPLACE(REPLACE(sp."Loja-Nome",'/SC',''),'  ',' '))),
                 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç','AAAAEEIOOOUUCAAAAEEIOOOUUC') = 'PATA AMIGA JGUA DO SUL'
                THEN 'PATA AMIGA JARAGUA DO SUL'
            ELSE TRANSLATE(UPPER(TRIM(REPLACE(REPLACE(sp."Loja-Nome",'/SC',''),'  ',' '))),
                 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç','AAAAEEIOOOUUCAAAAEEIOOOUUC')
        END

LEFT JOIN dim_categoria dc
    ON dc.categoria_origem = sp."CategoriaProduto";