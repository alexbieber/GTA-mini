# Matriz de funcionalidades — reconstrução FPS

Data: 14/10/2026. Auditoria inicial M1; atualizar a coluna do projeto após cada marco. O código pode mudar durante a implementação. [Evidência da referência](HOOD_WARFARE_REFERENCE.md) e [progresso de implementação](IMPLEMENTATION_PROGRESS.md) são registros separados.

`IMPLEMENTADO`: comportamento integrado e testado no projeto. `PARCIAL`: implementação incompleta ou validação pendente. `AUSENTE`: sem sistema identificado no escopo inspecionado. `BLOQUEADO`: teste impedido por dependência externa identificada. `NÃO VERIFICADO`: evidência insuficiente. Presença de uma declaração/documentação não significa teste REA.

As colunas de referência distinguem o Steam da aplicação browser independente. Todo gameplay do **executável Steam é NÃO VERIFICADO** nesta auditoria; apenas sua página pública foi observada. Os IDs completos dos replays browser estão no relatório. `C`=controles, `B`=bots, `T`=território.

| Funcionalidade | Referência browser via REA | OPERAÇÃO CAOS no início da reconstrução | Evidência/correção necessária |
|---|---|---|---|
| Menu e início offline | IMPLEMENTADO (C/B/T) | IMPLEMENTADO | Cena competitive_main e testes de menu existentes |
| Perspectiva FPS | IMPLEMENTADO (B, screenshot) | PARCIAL | CameraRig/competitive_game presentes; validar nova versão |
| WASD, mouse e aceleração | NÃO VERIFICADO | PARCIAL | Player/locomotion; medir colisão e deslocamento sustentado |
| Corrida e stamina | NÃO VERIFICADO | PARCIAL | Player/TacticalConfig; validar exaustão/recuperação |
| Agachar e salto | IMPLEMENTADO (C, estados HUD) | IMPLEMENTADO | Tests stage/combat existentes; nova revisão requer rechecagem |
| Escadas/rampas/mantle | NÃO VERIFICADO | PARCIAL | Escadas/rampas testadas historicamente; mantle recente |
| Sensibilidade/FOV | NÃO VERIFICADO | PARCIAL | Controles existentes; testar persistência e limites |
| Pistola/SMG/rifle/shotgun | PARCIAL (troca visual C) | PARCIAL | Arsenal/WeaponData; shotgun em implementação M2 |
| Hitscan, recuo e dispersão | NÃO VERIFICADO | PARCIAL | Tiros históricos testados; nova arma/integração a validar |
| Carregador/reserva/recarga | NÃO VERIFICADO (cliques sem consumo) | IMPLEMENTADO | Recursos e tests combat; incluir shotgun |
| Regiões de dano/hitmarker | NÃO VERIFICADO | IMPLEMENTADO | Hitscan/HealthComponent e testes anteriores |
| Animação FPS e efeitos | PARCIAL (visual B) | PARCIAL | Viewmodel procedural/pool; IK e animações ainda provisórios |
| Vida/morte/respawn | NÃO VERIFICADO | IMPLEMENTADO | Regras/integração anteriores; revalidar modo de bandeiras |
| Bots enfrentando equipes | IMPLEMENTADO (B, placar/killfeed) | IMPLEMENTADO | MatchBot/manager e testes anteriores |
| FOV/LOS, sons, cobertura, retirada IA | NÃO VERIFICADO | PARCIAL | BotBrain/dificuldades/NavAgent em desenvolvimento |
| Três dificuldades | PARCIAL (seleção T, sem comparar desempenho) | PARCIAL | Presets AI identificados; executar cenários |
| Capture the Flag 5v5 | NÃO VERIFICADO | PARCIAL | Modo anterior usa pacotes; exige bandeira única e aliada em casa |
| Controle de território | PARCIAL (T, objetivo; captura não testada) | AUSENTE | Não confundir captura de bandeira com território |
| BR oito participantes | NÃO VERIFICADO | PARCIAL | Royale existente tem dez; reduzir por recurso e revalidar |
| Loot/zona/último sobrevivente | NÃO VERIFICADO | IMPLEMENTADO | Tests regras/modos/mapa existentes; novos parâmetros a testar |
| HUD e placar | IMPLEMENTADO (B/C/T) | PARCIAL | HUD existente; status de bandeiras e stamina a integrar |
| Pausa | IMPLEMENTADO (C, menu) | PARCIAL | Separar pausa offline e menu em partida LAN |
| Áudios gravados por equipe | NÃO VERIFICADO | PARCIAL | 20 OGG preservados; eventos antigos, contexto sem transcrição |
| Chat de voz multiplayer | NÃO VERIFICADO | AUSENTE | Gravações de announcer não constituem voice chat |
| ENet/lobby/seleção LAN | NÃO VERIFICADO | PARCIAL | Código LAN presente; conexão/validação servidor ainda a testar |
| XP e desbloqueios | NÃO VERIFICADO | AUSENTE | Não identificado nas fontes do projeto inspecionadas |
| LOW/Compatibility/instancing/pool | NÃO VERIFICADO | IMPLEMENTADO | Recursos, cenário e medições da versão anterior |
| LOD/occlusion/resolução reduzida | NÃO VERIFICADO | PARCIAL | Instancing/corte de distância não comprovam LOD/occlusion |
| Meta 30 FPS, 720p LOW | NÃO VERIFICADO | PARCIAL | Versão anterior medida; reconstrução precisa amostra nova |

O mundo aberto já está arquivado fora do menu principal. Arquivos e gravações não foram removidos. Esta matriz não declara networking ou nova IA concluídos por leitura de código. Nenhum teste de runtime Godot foi executado pelo agente responsável por esta auditoria de referência; os marcos seguintes devem anexar seus próprios resultados.
