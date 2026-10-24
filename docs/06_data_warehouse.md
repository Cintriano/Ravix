# Ravix — Esquema do Data Warehouse

> Exportado do Notion (Projetos / Ravix / Modelagem dados e Backlog pipelines) em 24/10/2026.
> Fontes: https://app.notion.com/p/3deb044db6b1806cab2bcd549685da2f · https://app.notion.com/p/3dfb044db6b180f68a25dd09be7ba46f
>
> ⚠ Rascunho anterior às decisões DP-21, DP-30, DP-32 e DP-33 (ainda usa `uuid_usuario`, `compra_imediata`/`compra_credito` e `mes_exercicio`). O alinhamento está em aberto no DP-24 e na task E02-F03.

## Tabelas — Data Warehouse

Banco de dados local em Postgre, integrado por pipelines em python, arquitetura voltada a o espetro analítico, para gerar painéis de analises descritivas e preditivas.

### dim_usuario

- uuid_usuario (PK)
- nome_usuario
- email_usuario
- data_criacao_usuario

### dim_data

- data (PK)
- nome_mes
- numero_mes
- ano_mes
- ano
- dia
- dia_semana
- dia_utilZ
- trimestre
- quadrimestre
- semestre

### dim_horario

- uuid_horario (PK)
- horario
- hora
- minuto
- turno (manhã, tarde, noite, madrugada)

### dim_categoria

- id_categoria (PK)
- nome_categoria

### dim_subcategoria

- id_subcategoria (PK)
- id_categoria (FK)
- nome_subcategoria

### ft_compra_imediata

- uuid_compra_imediata (PK)
- uuid_usuario
- data
- id_categoria
- id_subcategoria
- valor
- descricao
- tipo_pagamento

### ft_compra_credito

- uuid_compra_credito (PK)
- uuid_usuario
- data
- id_categoria
- id_subcategoria
- valor_total
- valor_parcela
- mes_exercicio
- quant_parcela

---

## Backlog pipelines

Airflow
