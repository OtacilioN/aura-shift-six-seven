# Conquistas do Google Play Games

Este diretório contém o catálogo inicial de 26 conquistas do Aura Shift: SixSeven!, totalizando 935 pontos e reservando 1.065 pontos do limite de 2.000 para expansões.

## Arquivos

- `AchievementsMetadata.csv`: metadados no idioma padrão do projeto Play Games, inglês dos Estados Unidos (`en-US`).
- `AchievementsLocalizations.csv`: nomes e descrições adicionais em português do Brasil (`pt-BR`).
- `AchievementsIconsMappings.csv`: mapeamento entre nomes e ícones com o nome atualmente solicitado pela interface do Play Console.
- `AchievementsIconMappings.csv`: cópia compatível com a grafia singular presente em parte da documentação oficial; não é incluída no ZIP.
- `icons/`: 26 PNGs únicos, transparentes e com 512 × 512 pixels.
- `achievement-ids.template.json`: chaves internas estáveis aguardando os IDs gerados pelo Console.
- `achievement-ids.generated.json`: IDs reais atribuídos pelo projeto Play Games `293539263998`.
- `aura-shift-achievements-import.zip`: arquivo plano pronto para importação em lote.

O ZIP usa os nomes oficiais, não contém subdiretórios e inclui apenas os três CSVs aceitos e os 26 PNGs.

## Substituições validadas contra o domínio

O jogo não possui personagens jogáveis desbloqueáveis. Para manter intenção, tipo, dificuldade e pontos:

- `Elenco de Respeito` usa o marco intermediário de três Transformações de Aura.
- `Todo Mundo Tem Aura` exige as cinco Transformações originais congeladas em `FORM-01` a `FORM-05`.

`Forty Two` corresponde à técnica persistida `TECH-06`; `Aura Máxima` corresponde ao estado visual `FORM-05`. O catálogo original de itens congela os 18 IDs não secretos definidos em `AchievementCatalog.originalCatalogItemIds`.

## Regeneração e validação

Execute:

```sh
python3 tools/achievements/generate_assets.py
```

Antes de importar, valide que:

- há 26 linhas em cada CSV;
- a soma é 935 pontos;
- cada PNG mede 512 × 512 e tem canal alfa;
- o ZIP possui 29 arquivos na raiz e nenhum diretório;
- nomes e descrições do metadata não contêm vírgulas.

Os IDs externos nunca são inventados. Depois da importação, copie os IDs reais para a configuração central do app e para uma cópia do template.
