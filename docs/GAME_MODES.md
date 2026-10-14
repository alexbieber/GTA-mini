# Arquitetura dos modos — direção atual

Entrada leve: competitive_main.tscn → competitive_game.gd. Ela instancia MatchHUD, CameraRig, TouchControls, ShotEffects, ArenaLighting e MatchManager; adia Player/mapa até seleção. Não instancia City, NPCs civis, trânsito, aeronaves, carros ou HDRIs. main.tscn/game.gd permanecem arquivados e executáveis explicitamente.

MatchRules é estado puro RefCounted: participantes por ID, equipe/vida/spawn/score, cronômetros, countdown, objetivos, validação de captura/dano, morte, respawn e resultado. ObjectiveState possui ID, dono, valor, original, portador, posição e cinco estados. snapshot() retorna dados isolados do estado; nenhum Node integra a autoridade de regras. MatchEventBus encaminha sinais a HUD, locutor e composição.

MatchManager instancia apenas o mapa selecionado (scenes/maps/*.tscn), jogador e nove MatchBots. Rules controla resultado; Manager traduz dados para física e apresentação. Retorno remove mapa imediatamente da árvore, limpa atores/eventos/loot/zona, interrompe voz e libera Player. Restart cria estado fresco. Configurações: resources/match_default.tres, loot_default.tres, safe_zone_default.tres e resources/maps/*.tres.

Bots reutilizam Player, WeaponData, carregadores, HealthComponent, locomotion e animações locais. Decisões de 0,25–0,31 s escalonadas por ID; A* em grade segue pegadas de colisão da geometria. Visão/tiros raycast exigem LOS; busca no Royale tem memória temporal de 5 s e patrulha na zona. Papéis do 5v5: defender, atacar, escoltar portador, recuperar pacote. São bots offline; não representam humanos conectados.

Configurações em user://competitive_settings.cfg: perfil, volume geral/locutor, narrador, mouse/ADS e bindings. LOW é o padrão sem preferências salvas. Compatibility é o renderer padrão. Um jogador humano local; equipe selecionada controla lado no 5v5 e voz/apresentação no Royale, onde todos são adversários individuais.

Este incremento entrega partidas offline testáveis. Rede, servidor autoritativo e duas instâncias sincronizadas continuam pendentes em MULTIPLAYER_PLAN.md. Não há lobby online ou persistência de partidas.
