# Aura Shift: Six Seven

Repositório de planejamento de **Aura Shift: Six Seven**, um jogo incremental mobile de tendência centrado em farmar Aura por Ciclos Six-Seven. O primeiro lançamento é o MVP Android v1.0 na Google Play; uma versão para iOS poderá vir depois com a mesma base Flutter.

## Fase atual

O repositório agora contém a fundação executável do MVP em Flutter/Flame. O
domínio econômico (`arith-v1`), Ciclo Six-Seven, produção passiva/offline,
Loja, Árvore de Aura, Coleção, Ascensão, save local, Backup Manual e os oito
catálogos de localização estão implementados e possuem análise/testes locais.
As 18 Aparências equipáveis também são compostas na arena conforme slot, nível e
Movimento Reduzido; o catálogo revisado usa humor sistêmico sem alterar a economia.

Os assets visuais, sonoros, de marca e fontes foram aprovados e incorporados ao
runtime por manifests derivados, preservando os candidatos técnicos e seus
hashes. Ainda dependem de aparelho ou configuração externa antes de uma
publicação:

- teste em aparelho de loops, latência, retomada, ícone adaptativo e splash;
- IDs/configurações de Google Mobile Ads, UMP e Play Age Signals;
- configuração Firebase para Analytics opt-in e Crashlytics por ocorrência;
- dispositivo e credenciais de assinatura para validar a experiência e o AAB
  de release.

Para executar localmente:

```sh
flutter pub get
flutter test
flutter run
```

- o conceito, o escopo do MVP e os sistemas centrais estão aprovados;
- a economia possui parâmetros candidatos e contratos exatos prontos para simulação;
- `balance-v0.1` ainda não está aprovado como balanceamento final: precisa passar integralmente por `balance-gate-v1` quando a fase de simulação for autorizada;
- P01–P11 possuem artefatos documentais auditados: título/voz, 42 slots, UX/UI, arte, motion, áudio, acessibilidade, copy e oito catálogos de 261 strings;
- o estado `APPROVED` do pacote histórico refere-se ao planejamento registrado
  em `docs/USER-APPROVAL-PACKET.md`, não à aprovação dos assets produzidos;
- candidatos reproduzíveis de arte, marca, fontes e áudio foram gerados com
  manifests, hashes, fontes editáveis/procedurais, proveniência e revisão
  automática; a aprovação humana é registrada sem alterar essa evidência e os
  derivados aprovados são os contratos consumidos pelo runtime;
- políticas de plataforma, privacidade e anúncios devem ser verificadas antes da integração dos SDKs e novamente perto da publicação.

## Comece por aqui

1. [Glossário canônico](CONTEXT.md)
2. [Concept Design](docs/GAME-CONCEPT.md)
3. [Estratégia de Produto](docs/PRODUCT-STRATEGY.md)
4. [Escopo congelado do MVP](docs/MVP-SCOPE.md)
5. [Requisitos](docs/REQUIREMENTS.md)
6. [Roadmap do planejamento ao desenvolvimento](docs/PLANNING-TO-DEVELOPMENT-ROADMAP.md)

## Contratos versionados

| Contrato | Papel | Estado |
| --- | --- | --- |
| `balance-v0.1` | parâmetros econômicos candidatos | pronto para simulação, ainda não validado |
| `arith-v1` | aritmética inteira exata e ordem transacional | aprovado para planejamento e simulação |
| `number-format-v1` | apresentação de inteiros, taxas e grandes magnitudes | aprovado |
| `balance-gate-v1` | critérios binários de aceitação da economia | aprovado |

## Índice por frente

### Experiência e conteúdo

- [Direção de UX](docs/UX-DESIGN.md)
- [Arquitetura de UX e wireframes](docs/UX-WIREFRAMES.md)
- [Sistema visual de UI](docs/UI-DESIGN-SYSTEM.md)
- [Onboarding e primeira sessão](docs/ONBOARDING.md)
- [Direção de arte](docs/ART-DIRECTION.md)
- [Manifesto de assets visuais](docs/ASSET-MANIFEST.md)
- [Pipeline multiagente de produção](docs/ASSET-PRODUCTION-PIPELINE.md)
- [Estado do pacote produzido](docs/ASSET-PRODUCTION-STATUS.md)
- [Bíblia de motion, VFX e haptics](docs/MOTION-VFX-BIBLE.md)
- [Direção de áudio](docs/AUDIO-DIRECTION.md)
- [Inventário de áudio](docs/AUDIO-INVENTORY.md)
- [Plano de design cultural e nomenclatura](docs/CONTENT-DESIGN-PLAN.md)
- [Dossiê cultural](docs/CULTURAL-RESEARCH-DOSSIER.md)
- [Guia de marca e voz](docs/BRAND-VOICE-GUIDE.md)
- [Estrutura do catálogo](docs/CONTENT-CATALOG.md)
- [Topologia da Árvore de Aura](docs/AURA-TREE-DESIGN.md)
- [Conquistas](docs/ACHIEVEMENTS.md)
- [Acessibilidade](docs/ACCESSIBILITY.md)
- [Localização](docs/LOCALIZATION-PLAN.md)
- [Copy deck canônico](docs/COPY-DECK.md)
- [Glossário e memória de tradução](docs/LOCALIZATION-GLOSSARY.md)
- [Catálogos dos oito idiomas](localization)
- [Auditoria P01–P11](docs/PLANNING-AUDIT.md)
- [Pacote de aprovação do usuário](docs/USER-APPROVAL-PACKET.md)

### Economia e progressão

- [Design de economia](docs/ECONOMY-DESIGN.md)
- [Parâmetros de balanceamento](docs/BALANCE-PARAMETERS.md)
- [Cadência e plano de balanceamento](docs/PACING-AND-BALANCE.md)
- [Plano de simulação](docs/ECONOMY-SIMULATION-PLAN.md)
- [Gate de aceitação](docs/BALANCE-ACCEPTANCE-CRITERIA.md)
- [Aritmética econômica exata](docs/ECONOMIC-ARITHMETIC.md)
- [Exibição de números](docs/NUMBER-FORMATTING.md)

### Produto, tecnologia e operação

- [Arquitetura técnica planejada](docs/TECHNICAL-ARCHITECTURE.md)
- [Avaliação de tecnologia](docs/TECHNOLOGY-EVALUATION.md)
- [Monetização](docs/MONETIZATION-DESIGN.md)
- [Privacidade e proteção etária](docs/PRIVACY-AND-YOUTH-SAFETY.md)
- [Analytics](docs/ANALYTICS-PLAN.md)
- [Relatórios de falha](docs/CRASH-REPORTING-PLAN.md)
- [Salvamento e backup manual](docs/SAVE-DATA-DESIGN.md)
- [Segurança e integridade](docs/SECURITY-AND-INTEGRITY.md)
- [Plano de lançamento na Google Play](docs/GOOGLE-PLAY-LAUNCH-PLAN.md)
- [Equipe e produção](docs/TEAM-AND-PRODUCTION.md)
- [Pipeline de revisão multiagente](docs/AGENT-REVIEW-PIPELINE.md)
- [Roadmap do planejamento ao desenvolvimento](docs/PLANNING-TO-DEVELOPMENT-ROADMAP.md)

## Decisões arquiteturais

As decisões difíceis de reverter e seus trade-offs ficam em [`docs/adr`](docs/adr). As ADRs registram, entre outros pontos, Flutter com Flame, salvamento local sem conta, aritmética inteira exata, Ascensão, escopo congelado e espelhamento econômico dos ramos.

## Regra documental

`CONTEXT.md` é somente glossário. Comportamento normativo pertence aos requisitos e documentos de design; justificativas arquiteturais duráveis pertencem às ADRs. Mudanças econômicas devem criar uma nova versão identificada e atualizar conjuntamente fórmulas, fixtures, requisitos e critérios de aceitação.
