# Protege o Corre! — 5v5 offline

Entrada: scenes/competitive_main.tscn (F5 pelo project.godot). Escolher Polícia ou Coletivo Aurora e selecionar o modo. Um jogador local e nove bots, cinco de cada lado. Configuração em resources/match_default.tres: 600 s, 5 capturas, respawn de 5 s, retorno de pacote abandonado após 30 s e proteção de spawn de 1,5 s.

Mapa procedural independente de 160 × 110 m, definido em resources/maps/protege_o_corre.tres e MatchArena. Três rotas em z = -38 / 0 / 38, prédios, muros, cobertura baixa, bases opostas e bloqueadores que impedem LOS direta entre todos os pontos adversários de spawn. A* usa as mesmas pegadas de colisão, com margem de 0,85 m. Geometria estática usa MultiMesh por material; sem mundo aberto, tráfego ou veículos neste modo.

E coleta um dos três objetivos adversários; entrega automática dentro de 5 m do próprio depósito vale um ponto. G derruba; aliados recuperam pacote derrubado. IDs e estados são únicos: AT_BASE, CARRIED, DROPPED, RETURNING, CAPTURED. Objetivo capturado volta após 2 s para permitir atingir 5 pontos. Recaptura não pontua duas vezes. E junto ao arsenal repõe reserva sem duplicar armas. No tempo limite, maior placar vence; empate permanece empate.

Bots têm papéis de defesa, ataque, escolta e recuperação, por estado real. Navegação segue A*, tiros exigem raycast LOS e validação local de equipes/vida/proteção. Armas, carregadores, recarga e dano são compartilhados com Player; agressividade configurável. Ainda não há decisões sofisticadas de supressão, granadas, animação dedicada de cobertura ou navegação de lajes. HUD mostra equipe/placar, tempo, pacote, feed e resultado com kills/mortes.

Controles: WASD, Shift, Ctrl (crouch/slide), Espaço, T tactical sprint, RMB ADS, LMB tiro, R recarga, Q ombro, 1–3/roda armas, E objetivo/arsenal, G derrubar, Tab/Esc menu, F6 qualidade. Configurações permitem remapear ações principais e persistem em user://competitive_settings.cfg. Touch de movimento/combate preservado; disposição ainda exige aparelho real.
