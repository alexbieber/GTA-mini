# Entrega da sprint competitiva — 14/10/2026

## Executar no Godot

Abra Godot 4.7.2, clique em Importar e selecione o project.godot na raiz deste repositório. Abra o projeto, aguarde a importação e pressione F5. A entrada já está configurada como res://scenes/competitive_main.tscn. Escolha Polícia ou Facção e depois Favela Royale ou Protege o Corre!. Ambos funcionam offline com um jogador local e nove bots.

test_match_rules.gd é um teste automatizado, não a cena de entrada. Para executar apenas esse teste: godot --headless --path . --script tests/test_match_rules.gd. Para visitar o mundo aberto arquivado, abra scenes/main.tscn e pressione F6 no editor.

## Arquivos, cenas e sistemas

- Entrada: project.godot, scenes/competitive_main.tscn e scripts/modes/competitive_game.gd; menu, configurações e placar em match_hud.gd.
- Mapas: scenes/maps/protege_o_corre.tscn (160 × 110 m), scenes/maps/favela_royale.tscn (220 × 220 m), resources/maps/*.tres e match_arena.gd; módulos MultiMesh, colisões simples, rotas A*, rampas e escadas.
- Regras: scripts/modes/match_rules.gd, match_manager.gd, match_config.gd e objective_state.gd; 5v5, objetivos, pontuação, respawn, encerramento, reinício e liberação de mapa.
- Royale: safe_zone_config.gd, safe_zone_controller.gd, loot_config.gd e recursos correspondentes; dez participantes, loot, zona dinâmica, dano externo e último sobrevivente.
- Combate: scripts/player.gd, combat_input.gd, weapon_data.gd, health_component.gd, hitscan.gd, cover_controller.gd, camera_rig.gd, shot_effects.gd e touch_controls.gd; ADS, munição/recarga, recoil, cobertura, melee e movimento tático.
- Apresentação: shaders/urban_character.gdshader, arena_lighting.gd e graphics_profile.gd; personagem urbano original com regata/jeans, LOW Compatibility e efeitos com pool.
- Locução: scripts/modes/announcer_manager.gd, bancos audio/announcer/*, VOICE_MANIFEST.json; eventos, fila, prioridade e locução exclusiva da equipe. Polícia usa legendas enquanto não houver gravações próprias.
- Verificação: tests/test_*.gd, benchmark_competitive.gd, measure_startup.gd, capture_modes.gd; relatórios, JSON e capturas em docs/.

O mundo aberto, veículos, aeronaves, missões e recursos originais permanecem arquivados e executáveis em main.tscn. A cena e os scripts de teste do locutor fornecidos pelo usuário foram preservados. As vinte gravações originais da Facção foram preservadas, com hashes conferidos; nenhum áudio policial foi sintetizado. Os commits sincronizados do fork foram mantidos.

## Evidência e limites

193 checks automatizados passaram, incluindo cena arquivada, regras, combate, integração dos dois modos, navegação, cobertura e retorno ao menu. Capturas reais de cinco telas foram inspecionadas. A revisão estática independente não identificou falha crítica de inicialização, spawn ou encerramento.

Amostras renderizadas de 30 segundos, 720p LOW Compatibility, Quadro 600/i7-3770: Corre 60,01 FPS médios, p95 17,30 ms e 48,8 MiB estáticos do motor; Royale 60,01 FPS, p95 17,18 ms e 51,9 MiB. Seis eliminações por bots em cada amostra. Memória estática não equivale a RAM total; detalhes, snapshots Windows e limites estão em [PERFORMANCE.md](PERFORMANCE.md). A sincronização de 60 Hz limita a interpretação desses FPS.

Faltam partida manual prolongada, touch em aparelho, escuta do áudio em dispositivo, perfis superiores, animações finais de armas/IK, navegação de bots em lajes/interiores e LOD/occlusion completos. A arte continua estilizada e parte dos acessórios usa geometria provisória. REA não disponibilizou captura nativa no Windows; os testes reais foram executados diretamente no Godot. Não há multiplayer funcional nem teste online. A preparação de autoridade/IDs/snapshots e o próximo gate estão em [MULTIPLAYER_PLAN.md](MULTIPLAYER_PLAN.md).

## Commits

| Etapa | Commit | Conteúdo |
|---|---|---|
| Combate inicial | e62fb66 | ADS, munição e movimento tático |
| Personagem | d9f0cf9 | Personagem original com regata e jeans |
| Sprint A | 2fb3fc7 | Arquivo do mundo aberto e menu leve |
| Sprint B | c071b4e | Arena 5v5 e combate real de bots |
| Sprint C | 14f66a1 | Preservação e isolamento das vozes |
| Sprint D | 7490d62 | Favela Royale, loot e zona |
| Snapshot sincronizado | 5344065 | Integra polimento E, testes, medições e plano F |
| Fechamento E | 14032c9 | Medição final e referências Godot |

Os snapshots sincronizados aa intermediários também foram preservados. O fechamento documental F registra a preparação e os critérios de validação; não anuncia partidas online.
