# Matriz de referência — OPERAÇÃO CAOS

Auditoria de 14/10/2026. Base GTA-mini local: `f8187d327dbe327076ca23f5d8150d81f542c381`.
Escopo: Godot. Unity permanece como referência secundária, sem alterações.

## Evidências e limites

- **D1**: [WASM Arcade](https://wasmarcade.com/gta-5), descrição e tabela de controles. Documentação do agregador, não comprovação de funcionamento do host. Esta tabela não é reproduzida integralmente.
- **O1**: [host direto](https://gta.deloskiyt.pl/), REA `ev_d2f20e30d9c8a2aaa1648874b2f538c4c4b41e18cd318e3129467acd8946230b`: canvas, botões Story/Sandbox e carregamento visíveis. Escolher modo não prova que história ou sandbox funcionem.
- **O2**: após Espaço enviado pelo CDP, REA `ev_0d8caea4a57cf7f60ef396aeaf4294b77d0fe28fe9d033afcbc7d161c804876d`: seleção de mapa, botões Back e duas opções de mapa; carregamento em 66%. Screenshot REA `ev_e53954e599f69a7cb6fed8412dfab601008167666f41b86e2ea8ab850dd33bfa` confirma tela de carregamento/seleção, não gameplay.
- **O3**: após tecla 5 enviada pelo CDP para a opção de mapa, REA `ev_9583a726934a25f2dff90803ee9d8fc69973a4a6c716fe7d25c14bdd0d5c81dd` confirmou carregamento de Sandbox/mapa e áudio em 66%. Screenshot `ev_ceab04658ea4bb671ff6a4b4b711d546d3ac480928bacd500f08e104a39de42e` mostrou relatório de ausência de log do engine por 150 s. Gameplay não observado; não concluir que o host nunca funciona em outro ambiente.
- **L**: leitura do código local, cenas e créditos. Código existente não significa teste visual concluído. Testes executados e pendentes constam em TEST_RESULTS.md.
- **P**: requisito de design do usuário; não atribuído à referência. **H**: hipótese a observar futuramente.

REA disponível: descoberta CDP, DOM/acessibilidade, metadados de recursos/rede, screenshots e observação temporal. A primeira tentativa encontrou endpoint indisponível; um Chrome headless separado permitiu observação. Captura de fontes desligada. Nenhum asset ou código da referência foi incorporado. Workers de origem não atribuída e atividade anterior à conexão não foram inspecionados. Headless não equivale a uma sessão interativa com GPU validada.

## Catálogo

Cada linha contém fonte, comportamento documentado/observado, estado local, proposta original, dependências e aceitação/teste. “Pendente” é trabalho futuro, não implementação entregue.

| ID / funcionalidade | Fonte e comportamento da referência | Base atual (L) | Implementação original / estado | Dependências | Aceitação e teste |
|---|---|---|---|---|---|
| A1 Movimento | D1: movimento direcional anunciado; gameplay não observado | Player, câmera relativa, gravidade, caminhada | Preservado; teste de física adicionado | player.gd, colisões | Caminhar e colidir; manual em rampa/escada |
| A2 Corrida | D1: corrida documentada | Shift e stamina; touch incompleto | RUN touch implementado | TouchControls, stamina | Consumir/recuperar stamina; teste manual e modos touch automatizados |
| A3 Salto | D1: salto documentado | Ausente no Godot | Implementado com buffer de 120 ms e tolerância de 100 ms | Locomotion, Player | Salta, aterrissa, sem salto duplo; teste automatizado |
| A4 Câmera | D1: controle por mouse | Órbita, FOV por velocidade, shake, modos carro/avião | Colisão volumétrica e parede próxima corrigidas | CameraRig, camada world | Parede a 1,5 m impede atravessamento; automatizado |
| A5 Câmeras alternativas | D1: alternância e olhar para trás anunciados | Ausentes | Pendente: presets terceira pessoa e olhar para trás | CameraRig, input | Troca sem perder alvo; manual |
| A6 Animações | H: transições de gameplay não observadas | Idle/movimento existentes | Preservadas; salto usa idle, clip original pendente | Models, AnimationPlayer | Sem clip ausente; revisão visual manual |
| B1 Armas e mira | D1: disparo/mira anunciados | Pistol/SMG/rifle, raycast, dispersão; sem ADS | Pendente: ombro de mira, retículo, alinhamento câmera/cano | Arsenal, CameraRig | Obstáculos bloqueiam projétil; fixture automatizada/manual |
| B2 Recarga | D1: recarga anunciada | Munição única por arma, sem carregador | Pendente: carregador/reserva/tempo e cancelamento | WeaponState, Arsenal | Não criar munição, interromper troca; automatizado |
| B3 Dano | H/P: valores não observados | Player/veículos têm HP; NPC cai em um acerto | Pendente: HealthComponent comum | CombatSystem, sinais | Dano varia por arma e alvo; automatizado |
| B4 Cobertura | D1: cobertura anunciada | Ausente | Pendente: sondagem lateral, abrigo, saída e exposição | Colisões, mira, animação | Cobertura bloqueia tiros e não prende jogador; manual/fixture |
| B5 Combate tático | P: combate sério | Soco, quedas temporárias; sem IA armada | Pendente: percepção, posições, disparo com linha de visão | Health, Navigation, faction | Inimigo não atira através de parede; automatizado/manual |
| B6 Furtividade | D1: modo furtivo documentado | Ausente | Pendente: agachar, ruído e detecção | Cápsula, percepção | Passa em teto baixo, faz menos ruído; manual |
| C1 Entrada/saída | D1: interação com veículos anunciada | Roubo, ejeção de motorista, carro/avião | Preservar; pendente testar ponto de saída seguro | Vehicle, Player | Entrar/sair sem nascer em parede; manual |
| C2 Direção e freio | D1: direção e freio de mão documentados | Física arcade CharacterBody3D; velocidades por tipo | Preservar; pendente perfis de aceleração/aderência | Vehicle, dados | Circuito por categoria; manual |
| C3 Colisão/dano | H/P: detalhes não observados | Impacto, HP, wrecked e reparo | Pendente: padronizar eventos e dano por impacto | Health, Vehicle | Impacto único não duplica dano; automatizado |
| C4 Trânsito | H/P | Grafo viário, semáforos globais, raycast frontal | Pendente: rotas completas e recuperação de bloqueio | RoadGraph, orçamento IA | 10 min sem impasse permanente; manual/telemetria |
| C5 Buzina/áudio | D1: buzina anunciada | Sem áudio funcional | Pendente: buzina original e estímulo sonoro | Audio, percepção | Buzina não dispara em UI; manual |
| D1 Pedestres | H/P | Caminham, esperam, fogem, se escondem, caem | Preservar; pendente navegação contornando obstáculos | Pedestrian, Navigation | Não atravessa parede nem fica preso; fixture/manual |
| D2 Policiais a pé | H/P | Oficiais perseguem diretamente | Pendente: patrulha, percepção e prisão com LOS | Wanted, Navigation | Não prende através de parede; automatizado |
| D3 Inimigos | P | Ausentes como sistema de combate | Pendente: estados patrulha/investigação/combate | Faction, Health, Combat | Reagem ao jogador conforme relação; automatizado/manual |
| D4 Aliados | P | Ausentes | Pendente: seguir, defender e fogo amigo configurável | Faction, Navigation | Segue sem bloquear portas; manual |
| E1 Crimes/procura | H/P | 5 níveis, crimes, cooldown e testemunhas | Preservar; pendente testemunhas civis com LOS | WantedSystem, CrimeEvent | Crime oculto não ganha testemunha por parede; automatizado |
| E2 Perseguição/busca | H/P | LOS, campo visual, última posição, busca e decay | Preservar; pendente estados explícitos e orçamento | Wanted, veículos, percepção | Perde contato e busca última posição; fixture/manual |
| E3 Escalada | P | Mais viaturas/velocidade, até 5 unidades | Pendente: patrulha, reforços e bloqueios por nível | Dispatch, trânsito, pooling | Reforços fora de vista e em locais válidos; manual |
| F1 Mundo aberto | D1: exploração anunciada; O2 só menu de mapa | Distrito procedural, lojas, base, água e aeroporto | Preservar; mapa/história originais em expansão | City, assets CC0 | Percorrer distrito sem erro; smoke/manual |
| F2 Streaming | D1: carregamento de dados anunciado; O1/O2 mostram progresso | Godot carrega distrito inteiro; Unity troca cenas | Pendente: chunks com histerese e limite de instâncias | IDs persistentes, WorldManager | Cruzar fronteira sem perder missão; automatizado/manual |
| F3 Dia/noite | H/P | Alternância manual com N/UI, iluminação | Preservar; relógio contínuo pendente | DayNight, gráficos | Alternar sem perder preset; automatizado/manual |
| F4 Clima | H/P | Ausente | Pendente: sol/neblina/chuva com partículas limitadas | DayNight, áudio, gráficos | Baixo desliga partículas caras; manual |
| F5 Navegação | H/P | Grade e caminhos de calçada, escolha gulosa | Pendente: A* viário e navegação de NPC | RoadGraph, chunk | Contorna bloqueio com rota válida; automatizado |
| F6 Natação | H/P | Água visual, sem natação no Player Godot | Pendente: volumes de água e estado de movimento | Player, volumes | Entra/sai da água sem queda infinita; manual |
| G1 Story/Sandbox | D1; O1 confirma botões, O2 seleção | Um ciclo de missão + free roam | Pendente: modos originais separados de fase de missão | MissionManager, save | Sandbox não exige missão introdutória; automatizado |
| G2 Objetivos/recompensas | H/P | Roubar→escapar→garagem, pickups/dinheiro | Pendente: missões Resource, recompensa idempotente | MissionManager, eventos | Morrer antes da entrega não conclui missão; automatizado |
| G3 Eventos emergentes | P: humor absurdo | Interações pontuais, sem diretor | Pendente: diretor de eventos com cooldown e orçamento | Factions, territory, missions | Evento pode falhar/cancelar sem travar missão; automatizado |
| H1 HUD/minimapa | D1: mapa/menu anunciado; HUD não observado | HP, dinheiro, estrelas, arma, radar, objetivo | Preservar; retículo/contexto de cobertura pendente | HUD, eventos | Indicadores acompanham estado; manual |
| H2 Inventário | D1: seleção de armas documentada | Armas possuídas e munição, teclas/scroll | Pendente: menu pausável e carregadores | WeaponState, UI | Troca não perde munição; automatizado |
| H3 Salvamento | D1: saves anunciados; não verificados | Sem persistência de jogo | Pendente: esquema versionado, arquivo temporário/backup | Stable IDs, progressão | Salvar/carregar reproduz estado; arquivo corrompido recuperável; automatizado |
| H4 Pausa/mapa | D1: pausa e mapa anunciados | Esc libera mouse; não pausa simulação | Pendente: pause menu, mapa original e opções | UI, process_mode | Menu pausa física e mantém UI; automatizado/manual |
| I1 Troca de personagem | D1: troca anunciada | Um Player | Pendente: elenco original e estado por personagem | Save, PlayerRig, Camera | Troca preserva HP/inventário/posição; automatizado |
| I2 Progressão | P | Dinheiro/compras, sem reputação | Pendente: reputação e desbloqueios por facção | Faction, Mission, Save | Recompensa aplicada uma vez; automatizado |
| I3 Interações | H/P | Loja de armas, hospital, respray, bar e pickups | Preservar; sistema contextual pendente | Interaction, missão | Interação mais próxima válida; manual |
| I4 Facções | P: relações dinâmicas | Ausentes | Pendente: matriz de relações com reputação/clamp | FactionSystem, Crime, Combat | Hostilidade altera resposta; automatizado |
| I5 Territórios | P: disputa territorial | Ausentes | Pendente: zonas, influência e disputa por evento | Faction, World, Save | Influência muda dono só no limiar; automatizado |
| J1 Áudio | H/P | Sem SFX/música; listener Unity não é áudio | Pendente: passos, motor, tiros e sirene originais | AudioBus, pools | Volume/mute e teto de vozes; manual |
| J2 Efeitos | H/P | Tracer, shake, luzes e água | Preservar; limites/pooling pendentes | Combat, GraphicsProfile | Efeito termina e não cresce RAM; manual/telemetria |
| J3 Gráficos | D1: perfil de pouca memória anunciado, não medido | Efeitos caros ativados na base | LOW/MEDIUM/HIGH implementados, F6; LOW inicial | GraphicsProfile, DayNight | LOW sem GI/SSR/SSAO/sombras do sol; automatizado; GPU manual |
| J4 Desempenho | P: PCs antigos | Sem benchmark, culling de gameplay ou chunks | Pendente: LOD, IA escalonada, pools e limites | Telemetria, streaming | Meta 30 FPS/720p e memória documentada em máquina alvo; manual |

## Auditoria estrutural

`scenes/main.tscn` instancia `game.gd`; cidade, personagem, câmera, HUD, veículos e NPCs são construídos em runtime. `game.gd` acumula responsabilidades e deve ser dividido gradualmente. `assets/` possui modelos FBX/GLB, texturas, HDRIs e créditos CC0; não foi feita auditoria externa de cada origem. `LICENSE` é MIT e deve ser preservada. `tools/bake_facades.py` exige Pillow e possui caminho absoluto de outra máquina. Não havia suíte Godot ou CI executável versionada antes desta etapa.

Defeitos identificados para próximas entregas: NPC sem HP; testemunhas civis sem LOS; `_respawn()` usa `_stolen` para entrar em FREE antes da entrega; arquivos Android/FBX têm avisos de importação; sem clip de salto; nenhuma medição gráfica em hardware antigo. Não substituir os sistemas existentes em bloco.
