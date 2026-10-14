# Roadmap — OPERAÇÃO CAOS

Cada etapa deve ter diff e commit próprios, testes e atualização da matriz. Esta entrega cobre a primeira etapa e a fundação de perfis gráficos. Não declara paridade com GTA V.

| Etapa | Entrega | Gate de aceitação | Estado |
|---|---|---|---|
| 0 Auditoria | Fontes, evidências REA, matriz A–J, limites | Nenhuma descrição confundida com gameplay observado | Documentada; gameplay da referência ainda limitado |
| 1 Personagem/câmera | Salto com tolerância, touch RUN/JUMP, colisão de câmera próxima, perfis gráficos | Testes físicos, modos carro/avião e inicialização sem regressão | Implementado; resultados em TEST_RESULTS.md |
| 2 Combate/cobertura | HealthComponent, carregadores, recarga, ADS, abrigo e percepção sonora | Dano/munição/LOS, saída de abrigo válida, manual de animação | Pendente |
| 3 Veículos/física | Perfis arcade, saída segura, eventos de impacto e reparo | Circuito, colisões e entrada/saída; manter avião | Pendente |
| 4 NPCs/trânsito | Navegação completa, recuperação de bloqueio, percepção e IA escalonada | Tráfego por 10 minutos, NPC contorna paredes | Pendente |
| 5 Polícia | Witness/CrimeEvent, busca por última posição, dispatch e bloqueios | Ocultação real, escalada limitada, prisão sem atravessar parede | Pendente |
| 6 Facções/territórios | Relações, reputação, zonas e influência persistente | Hostilidade e captura em testes determinísticos | Pendente |
| 7 Missões/progressão | Resources de missão, objetivos, checkpoint, fail/retry e eventos absurdos | Entrega original, recompensa única, falha não conclui | Pendente |
| 8 HUD/áudio/save | Retículo, inventário, pausa, mapa, mixagem, save versionado | Round-trip e corrupção; controle de voz/volume | Pendente |
| 9 Integração/otimização | Chunks, pooling, LOD, densidade por perfil, benchmark | 30 FPS/720p na máquina alvo e orçamento medido | Pendente |

## Ordem de trabalho

Usar os IDs da matriz para abrir tarefas pequenas. Antes de cada mudança, reproduzir o problema, executar testes relevantes e registrar desempenho quando houver impacto. Saúde/dano precede IA armada. Percepção precede dispatch. IDs persistentes precedem streaming e save. Facções precedem disputas e eventos emergentes. Manter a missão atual jogável durante extração do MissionManager.

Próxima entrega concreta: corrigir progressão após respawn e criar HealthComponent sem alterar direção, polícia ou geração de cidade. Depois implementar carregador/recarga antes de cobertura.

## Orçamento de máquinas antigas

LOW é padrão e desliga SDFGI, SSR, SSIL, SSAO, glow e sombras do sol. F6 alterna perfis, sem persistência nesta etapa. Shadow atlas reduzido de 8192 para 2048. Isso reduz configuração de custo, mas não prova ganho de FPS/RAM. Próximos passos: Compatibility com testes visuais, resolução/render scale, teto de luzes e NPCs, texturas menores, distância de instâncias e IA em frequências distintas.

Metas iniciais a validar: 720p/30 FPS, máquina com 4 GB RAM e GPU integrada, processo abaixo de 1,5 GB após estabilização. São metas, não medições. Registrar hardware, renderer, FPS mediano/p95 de frame time, memória e percurso antes de prometer suporte.
