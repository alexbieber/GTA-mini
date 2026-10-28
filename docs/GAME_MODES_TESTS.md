# Testes dos modos e mapas — 14/10/2026

Godot 4.7.2.stable.official.ed1daf0bf em Windows. Executável: C:/Users/User/Downloads/Godot_v4.7.2-stable_win64_console.exe. Importação de scripts/mapas/OGG e inicialização da nova cena concluídas. Build-tools Android ausente; export mobile não testado.

## Automatizados

| Script (`--headless --path . --script tests/<arquivo>`) | Checks | Falhas | Cobertura |
|---|---:|---:|---|
| test_stage_one.gd | 24 | 0 | Salto, coyote/buffer, touch, câmera, perfis |
| test_combat.gd | 40 | 0 | Carregadores, recarga/cancelamento, recoil/ADS, cápsula, slide/tactical, pool |
| test_cover.gd | 10 | 0 | Cobertura elegível, clearance, lateral, crouch/ADS, saída |
| test_lightweight_menu.gd | 11 | 0 | Menu sem mapa/modelo/cidade, equipe, configurações, unload |
| test_match_rules.gd | 51 | 0 | Objetivos, score, vitória/empate, respawn, zona, multikills/prioridade, banco por equipe/OGG |
| test_modes_integration.gd | 36 | 0 | Cena real 5v5/Royale, tiros/melee, LOS inclusive agachado, 5 capturas/resultados, loot, restart/unload |
| test_map_navigation.gd | 7 | 0 | Spawns conectados, rampa, escada física, 150 zonas válidas, materiais |
| test_game_integration.gd | 14 | 0 | Mundo aberto arquivado, veículo, procura, missão/respawn e F6 |
| **Total** | **193** | **0** | Saídas 0 |

Suíte rodada após alterações. A primeira execução paralela do teste de áudio encerrou antes de o mixer liberar playback OGG, gerando aviso/erro de recursos na saída apesar dos checks passarem. O teste foi corrigido para permitir um bloco real de reprodução e liberação; execução final desse script passou sem aviso/erro. Uma falha anterior de tiro revelou raycast de cano terminando exatamente na superfície de cápsula vista por outro ângulo; agora avança 0,25 m para dentro do alvo, conservando prioridade de paredes. Escala de personagem, guarda de callbacks após unload e movimento lateral de cobertura também foram corrigidos por evidência de testes/capturas.

## Renderizados

tests/capture_modes.gd executado com Compatibility, Quadro 600, 720p LOW, AudioDriver Dummy. Capturas de menu/configurações/Corre/Favela/resultados salvas e inspecionadas. Tela de resultado na captura foi acionada pelo script para revisar layout; vitória real também é verificada pelo teste de integração. Não são testes manuais. OGG carregado e iniciado em AudioStreamPlayer; não se declarou escuta humana ou validação WASAPI.

tests/benchmark_competitive.gd: uma amostra real de 30 s por modo, bots autônomos, seis eliminações em cada amostra, cerca de 60 FPS; p95 17,30/17,18 ms. Memória/draw calls e limites em PERFORMANCE.md, JSON em measurements/. tests/measure_startup.gd comparou carga da cena arquivada com menu novo; sem inferência de FPS por headless.

REA foi consultado anteriormente para a referência e encontrou endpoint CDP indisponível. Também foi chamado capture_process_scenario para Godot/test_modes_integration.gd: o provedor retornou capability_unavailable/unsupported_provider, pois o adaptador Windows não consegue verificar cleanup de descendentes em PTY; retryable=false. O próprio provedor informa que reinstalar backend não resolve. Nenhuma captura REA de execução foi alegada. Testes e renderização nativa foram executados pelas ferramentas de shell e Godot/RenderingServer. Vídeo externo não foi reproduzido nem usado como prova visual.

## Pendências reais

Gameplay manual completo de 10 minutos, touch em aparelho, áudio em dispositivo, transcrição exata das 20 falas, perfis MEDIUM/HIGH sob GPU real, combate em lajes/interiores, animações de arma/IK, bake de occlusion/LOD e multiplayer entre instâncias. Nenhum teste online realizado. Bases/bots/objetivos são originais; nenhuma gravação policial sintetizada.
