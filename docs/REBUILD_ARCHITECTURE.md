# Arquitetura da reconstrução FPS

Checkpoint antes das alterações estruturais: `3e5f1a4`. Ele inclui o FPS em implementação e as configurações do editor já presentes. Nenhum histórico sincronizado foi reescrito. O mundo aberto continua em `scenes/main.tscn`, fora da entrada `scenes/competitive_main.tscn`.

## Módulos e autoridade

| Módulo lógico | Implementação reaproveitada ou nova | Responsabilidade |
|---|---|---|
| Core/GameManager | scripts/modes/competitive_game.gd | Composição, entrada e ciclo de cenas |
| Player/PlayerController | scripts/player.gd, locomotion.gd, camera_rig.gd | Cápsula física, movimentação, FPS/terceira pessoa |
| Combat/WeaponSystem | scripts/combat/weapon_system.gd, weapon_data.gd, arsenal.gd | Um caminho de tiro local/remoto; recursos de balanceamento |
| Combat/DamageSystem | scripts/health_component.gd, hitscan.gd | Vida/armadura/regen e obstrução física |
| AI/BotController/TeamBehavior | scripts/ai/*, modes/match_bot.gd | FSM, percepção e navegação; objetivos da autoridade |
| GameModes/BattleRoyale/CaptureTheFlag | scripts/modes/match_rules.gd, match_manager.gd, objective_state.gd, safe_zone_* | Dados por IDs; regras separadas de Nodes |
| Maps/FavelaBR/Favela5v5 | scenes/maps/*.tscn, resources/maps/*.tres, match_arena.gd | Apenas mapa escolhido; geometria e colisões originais |
| Audio/VoiceManager | scripts/modes/announcer_manager.gd, audio/announcer/* | Eventos, bancos por equipe, fila/prioridade/cooldown |
| Network/MultiplayerManager | scripts/network/* | ENet, lobby, intenções e snapshots; servidor valida gameplay |
| UI/MainMenu/HUD | scripts/modes/match_hud.gd, tactical_overlay.gd, combat_reticle.gd | Configurações, feedback e placar |
| Optimization/GraphicsProfiles | graphics_profile.gd, arena_lighting.gd, shot_effects.gd | Compatibility, LOW, instâncias e pool limitado |

Os caminhos legados são conservados para evitar quebrar referências e a cena arquivada. A divisão acima representa responsabilidades reais, não pastas vazias ou wrappers de nomes. A física continua no motor Godot; não se usa um segundo simulador. Resources configuram armas e perfil tático. MatchRules valida objetivos e resultado, sem acessar HUD. MatchManager adapta regras para atores/mapa; WeaponSystem serve os disparos locais e remotos. Interfaces usam sinais de eventos.

Cliente LAN envia intenções e olhar, nunca vida, munição, score ou posição escolhida. O servidor executa a física e o mesmo sistema de combate, valida cadência, distância, equipe, vida e bandeiras. A implementação e a cobertura entre processos serão registradas em LAN_MULTIPLAYER.md; arquitetura por si só não certifica partida online.

Navegação gera uma malha leve a partir das células transitáveis e sincroniza NavigationAgent3D; A* existente serve como fallback inicial. Percepção/decisão usa intervalos. Não há modelo de IA externo. Mapas, materiais, arma visual e HUD permanecem próprios; screenshots de referência ficam em docs/evidence com .gdignore e não são assets do jogo.

## Limites e isolamento

Não é uma reprodução byte a byte nem afirma equivalência com o executável Steam não observado. Compatibilidade da cena arquivada é testada separadamente. Não mover ou apagar vozes originais; conferir hashes. Evitar novos eventos de voz não revisados semanticamente. LAN e persistência precisam de resultados executados antes de receber status IMPLEMENTADO. Serviços de internet, matchmaking público, anti-cheat robusto e servidor dedicado persistente são escopos futuros.
