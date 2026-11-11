# Ravix — Documentação

Documentação do projeto trazida do Notion (Projetos / Ravix), exportada pela última vez em 08/11/2026, mais a identidade visual do repositório CAPRA. O Notion continua sendo a fonte das decisões; estes arquivos são uma cópia de referência.

| Arquivo | Conteúdo | Página no Notion |
| --- | --- | --- |
| [01_visao_geral_e_arquitetura.md](01_visao_geral_e_arquitetura.md) | Objetivo, nome, ambiente, arquitetura em camadas, princípios, integração Pluggy (sandbox e testes com dados reais) | [Ravix](https://app.notion.com/p/3fdb044db6b182bd870201140670d798) |
| [02_backlog.md](02_backlog.md) | Épicos E01–E04, features e tasks por versão, carga de categorias | [Backlog app](https://app.notion.com/p/3dfb044db6b180628983e3c499af7208) |
| [03_modelo_de_dados.md](03_modelo_de_dados.md) | Convenções, DDL e consultas da v1 e do schema 2 (v2), regras e migração 1 → 2 | [modelagem banco](https://app.notion.com/p/3dfb044db6b1802a803bcebfcef7233f) |
| [04_plano_desenvolvimento_v1.md](04_plano_desenvolvimento_v1.md) | Módulos M0–M7, estratégia de testes, critérios de pronto | [Plano de desenvolvimento — v1](https://app.notion.com/p/401b044db6b1812db9bbc1917c0f7835) |
| [05_decisoes.md](05_decisoes.md) | Quadro de decisões DP-1 a DP-39, com contexto e deliberação de cada card | [Decisões pendentes](https://app.notion.com/p/3f3b044db6b1811fbe7ddbcd95000cfc) |
| [06_data_warehouse.md](06_data_warehouse.md) | Rascunho das dimensões e fatos do DW e backlog de pipelines | [Modelagem dados](https://app.notion.com/p/3deb044db6b1806cab2bcd549685da2f) · [Backlog pipelines](https://app.notion.com/p/3dfb044db6b180f68a25dd09be7ba46f) |
| [07_dw_apolo.md](07_dw_apolo.md) | Projeto irmão DW_APOLO: esquemas bronze/silver/gold, usuários, pipelines | [DW_APOLO](https://app.notion.com/p/3e0b044db6b180289f2bfe7947ac7966) |
| [identidade_visual/](identidade_visual/README.md) | Marca Ravix: identidade v2 em `v2/` (manual, tokens, logos, ícones, fontes, tema Flutter); a CAPRA anterior fica como histórico | [github.com/Cintriano/Capra](https://github.com/Cintriano/Capra) |

## Estado em 08/11/2026

- **Status:** v1 concluída em 24/10/2026 (M0 a M7). v2 implementada em 08/11/2026, com merge na `main`, e instalada no aparelho. Identidade visual v2 aplicada (DP-39).
- **v1:** só local (SQLite), aba à vista, formulário, tags e bloqueio pelo PIN do aparelho.
- **v2:** ainda só local. Schema 2 com a migração 1 → 2 e backup antes de migrar; renda por vigência e cartões (com arquivar e reativar) na Configuração; compra no cartão, pagamento de fatura, estorno e recorrências (à vista previstas com Registrar; no cartão, lançadas sozinhas); abas Macro (inicial), Faturada e À vista; gasto por categoria e visão por tag.
- **11/11/2026:** revisão completa e correções (consumo do limite por fatura, recorrências, Macro, migração) e botão Quitar vencidas na aba Faturada (E01-F14-T04 e T05).
- **Falta na v2:** só as validações de uso no aparelho (E01-F14).
- **Decisões em aberto:** 9 de 39, todas da v3 ou sem versão.
