# Pata Amiga — Modelo Dimensional de Pedidos e Entregas

Mini-Projeto Avaliativo · Módulo 2 · Semana 7

## Sumário

1. [Contextualização](#1-contextualização)
2. [O desafio](#2-o-desafio)
3. [Diagnóstico da origem](#3-diagnóstico-da-origem)
4. [Decisões de tratamento](#4-decisões-de-tratamento)
5. [Modelo dimensional](#5-modelo-dimensional)
6. [Como reproduzir o banco do zero](#6-como-reproduzir-o-banco-do-zero)
7. [As cinco respostas de negócio](#7-as-cinco-respostas-de-negócio)
8. [O que os dados não permitem afirmar](#8-o-que-os-dados-não-permitem-afirmar)
9. [Vídeo](#9-vídeo)

## 1. Contextualização

A Pata Amiga é uma rede catarinense de pet shops com 32 lojas. Desde setembro de
2023 a operação de pedidos roda em app, site, telefone, WhatsApp e loja física.
Em sete meses foram 4.044 pedidos, registrados em três sistemas que não
conversam entre si: a plataforma de e-commerce, o cadastro de lojas da
franquia e a planilha de praças de atendimento. Este projeto organiza esses
dados em um modelo dimensional para responder cinco perguntas de negócio da
diretoria.

## 2. O desafio

Construir a área de staging → dimensões → fato em PostgreSQL a partir de três
tabelas de origem não tratadas, e responder cinco perguntas de negócio que
hoje não são respondíveis por causa da qualidade e da falta de integração dos
dados.

## 3. Diagnóstico da origem

Foram recebidas três tabelas na área de staging (`stg_pedido`, `stg_loja`,
`stg_loja_praca`), todas com colunas em texto (VARCHAR), sem `UPDATE` ou
`ALTER` permitidos — todo o tratamento acontece na carga das dimensões e da
fato.

**stg_pedido (4.044 linhas)** — é a tabela com mais problemas:
- O nome da loja (`Loja-Nome`) aparece em **128 grafias diferentes** para as
  mesmas 32 lojas: com acento, sem acento, em caixa alta, com erro de
  digitação e com "/SC" sobrando no fim.
- A categoria de produto (`CategoriaProduto`) aparece em **37 grafias**
  diferentes para o que deveriam ser só 7 categorias padronizadas (ex:
  "Racao", "RACAO", "Ração" contam como três grafias distintas).
- **1.575 pedidos (~39%)** vieram sem `Cod Loja` preenchido — a loja só pode
  ser identificada pelo nome nesses casos.
- **3 pedidos** vieram sem `Loja-Nome` também, ou seja, sem nenhuma forma de
  identificar a loja.
- O campo de desconto (`HouveDesconto`) tem **17 grafias** diferentes para
  indicar sim/não (`S`, `SIM`, `1`, `X`, `TRUE`, `V`, etc.).
- O canal do pedido (`CanalPedido`) tem **20 grafias** diferentes, incluindo
  o caso de "WhatsApp" conter a substring "App" — o que exige cuidado na
  ordem de verificação.
- A data do pedido (`DtHoraPedido`) vem em formato americano
  (`MM/DD/YYYY HH12:MI AM`), enquanto os quatro marcos do processo de entrega
  vêm em formato ISO (`AAAAMMDD`) — dois formatos de data convivendo na
  mesma tabela.
- Os quatro marcos de processo (Separação, Nota Fiscal, Despacho, Entrega)
  têm, respectivamente, **1.077 / 1.338 / 1.665 / 1.953** registros em
  branco — o que não é erro, e sim processo ainda em aberto (pedido não
  chegou àquela etapa até o fim da janela de dados).
- Valores em reais (`ValorLiquidoPedido(R$)`) convivem em formatos
  inconsistentes: `"R$ 1.850,00"`, `"1850.00"`, `"1.200"`, `"-"` e vazio na
  mesma coluna.

**stg_loja (32 linhas)** — cadastro mais limpo, mas com:
- Nomes de loja em grafias variadas (acento, caixa, abreviação), que
  precisam ser padronizados antes de servirem de chave de cruzamento.
- A `FaixaFranquia` é uma "foto do presente": reflete a classificação atual
  da loja, não a que valia na data de cada pedido histórico — uma limitação
  que impacta a pergunta 5.

**stg_loja_praca (48 linhas)** — tabela ponte loja × praça de atendimento:
- Uma mesma loja pode atender mais de uma praça, com um percentual de
  público (`PercentualPublico`) que precisa somar 1,00 por loja.
- O campo `DomiciliosComPet` vem com ponto de milhar (ex: `"148.000"`
  significa 148 mil, não 148 vírgula zero).

### Resumo dos números

| Item | Contagem |
|---|---|
| Grafias distintas de nome de loja | 128 |
| Grafias distintas de categoria | 37 |
| Grafias distintas de CanalPedido | 20 |
| Grafias distintas de HouveDesconto | 17 |
| Pedidos sem `Cod Loja` preenchido | 1.575 (~39%) |
| Pedidos sem `Loja-Nome` preenchido | 3 |
| Marcos em branco — Separação | 1.077 |
| Marcos em branco — Nota Fiscal | 1.338 |
| Marcos em branco — Despacho | 1.665 |
| Marcos em branco — Entrega | 1.953 |

## 6. Como reproduzir o banco do zero

Conectado como `postgres`, rode os scripts na ordem:

```bash
psql -U postgres -d postgres -f sql/01-carga-staging.sql
psql -U postgres -d dw_pata_amiga -f sql/02-dimensoes-prontas.sql
psql -U postgres -d dw_pata_amiga -f sql/03-dimensoes.sql
psql -U postgres -d dw_pata_amiga -f sql/04-fato.sql
```

No pgAdmin: crie o banco `dw_pata_amiga` primeiro, depois rode cada arquivo
numa Query Tool conectada a ele (sem as linhas `DROP DATABASE`,
`CREATE DATABASE` e `\c`, que são comandos exclusivos do terminal `psql`).