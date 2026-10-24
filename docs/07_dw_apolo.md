# DW_APOLO

> Exportado do Notion (Projetos / DW_APOLO) em 24/10/2026. Projeto irmão do Ravix, com status **Pausado**; recebe os dados do app pelos pipelines.
> Fonte: https://app.notion.com/p/3e0b044db6b180289f2bfe7947ac7966

## Descrição

O objetivo é centralizar dados diversos em um banco de dados, para o fim de criar visões analiticas. O escopo considera tabelas manuais, aplicações etc, todo o fluxo de entrada será por meio de pipelines padronizados.

## Data marts

Avaliar a criação de data marts por contexto, visão a escalabilidade.

## Usuários

### Usr Administrador

usuário apenas para configuração do sistema.

### Usr de serviço

deverá existir um usuário para cada pipeline que escreve ou ler o DW, apenas com as permissões necessárias, melhorando a segurança e a clareza dos logs, já que será possível rastrear quem está em execução.

## Esquemas

Descrição dos tipos de esquema

### Esq Logs

Nome: `ESQ_LOGS`

Registro de todas as entradas de dados em todos os esquemas do DW.

### Esq Bronze

Nome: `ESQ_BRONZE`

Camada de chegada dos dados brutos, no seu formato original, para garantir a persistência da informação.

#### Nomenclatura de tabelas

nomenclatura de tabela: `tbl_app_ravix_usuarios`

Arquitetura da nomenclatura:

- **tbl**: prefixo padrão.
- **app_ravix**: identificação da origem.
- **usuarios**: identificação da entidade.

### Esq Silver

Nome: `ESQ_SILVER`

Camada de transformação dos dados para criar as dimenssões.

#### Nomenclatura de tabelas

nomenclatura de tabela: `dim_usuarios`

Arquitetura da nomenclatura:

- **dim**: prefixo padrão.
- **nome da dimenssão**: identificação da origem.

### Esq Gold

Criação das tabelas fato.

#### Nomenclatura de tabelas

nomenclatura de tabela: `ft_consumo`

Arquitetura da nomenclatura:

- **ft**: prefixo padrão.
- **nome do fato**: identificação da origem.

### Tabelas

## Pipelines

Implementadas em python, elas serão responsáveis em tratar os dados de diferentes fontes e inseri-la no DW, a orquestração de execução será por meio do **Airflow**.

A arquitetura será completamente independente de qualquer aplicação ou contexto, sendo um repositório próprio com as dags agrupadas por contexto.

### Arquitetura de código

Todo o código será criado condicionado a funções, mantendo a modularidade e manutenção facilitada.

Tipagem

- Variáveis.
- Parâmetros de funções.
- Retornos de funções.

Pacotes

Funções de uso genérico que podem ser reaproveitadas em varias dags distintas, agrupadas em arquivos.

### Foco

- Escalável.
- Estável.
- Modular.
