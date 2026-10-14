# Resultados de testes — 14/10/2026

## Incremento de combate (segunda execução)

Novas verificações em tests/test_combat.gd cobrem munição/recarga/cancelamento, cadência, armadura/morte, crouch/teto, escala visual, slide/tactical sprint, tiros bloqueados por parede próxima ao personagem, ADS/sensibilidade/recoil e pool limitado. Integração agora verifica respawn após roubo sem liberar FREE antes da entrega. Resultado final: combat 40/40, stage_one 24/24 e game_integration 14/14; todos exit 0, sem erros de script. git diff --check passou. Testes de teclado/mouse usam eventos físicos correspondentes aos dispositivos do Godot 4.7.

Executado também tests/capture_combat.gd com renderer gl_compatibility na Quadro 600: captura PNG em %TEMP%/caos-combat.png, retorno 0, inspecionada. Revelou escala vertical incorreta ao ficar em pé, corrigida; nova captura confirmou proporções preservadas e HUD ADS. Primeira execução encontrou WASAPI indisponível; segunda usou --audio-driver Dummy e iniciou sem erros de script. Não foi teste manual de combate nem validação de áudio.

Referência YouTube não reproduzível pela ferramenta web. REA não encontrou endpoint CDP ativo em 127.0.0.1:9222; somente disponibilidade foi consultada. Não houve inspeção de gameplay da referência nesta execução. Multiplayer, cobertura, IA tática e benchmark continuam pendentes.

## Ambiente

Windows, PowerShell, Godot `4.7.2.stable.official.ed1daf0bf` encontrado em `C:/Users/User/Downloads/Godot_v4.7.2-stable_win64_console.exe`. Os comandos abaixo usam `godot` como abreviação desse caminho. Testes headless com renderer dummy: nenhuma medição de FPS/GPU inferida desses resultados.

## Execução

| Verificação | Comando | Resultado |
|---|---|---|
| Importação inicial da base | `godot --headless --editor --path . --import --quit` | Exit 0; avisos/erros de assets descritos abaixo |
| Importação após alteração | Mesmo comando | Exit 0; sem erro de script; aviso de Android build-tools |
| Inicialização da base | `godot --headless --path . --quit-after 3` | Exit 0; cena principal carregou sem erro no log |
| Etapa 1 | `godot --headless --path . --script tests/test_stage_one.gd` | 24 checks, 0 falhas, exit 0 |
| Integração da cena real | `godot --headless --path . --script tests/test_game_integration.gd` | 12 checks, 0 falhas, exit 0 |

Etapa 1: salto no chão, coyote, buffer antes de aterrissar, buffer expirado, ausência de salto duplo, movimento físico, aterrissagem, bloqueio no título/veículo, câmera com parede próxima e trajeto livre, modos carro/avião, clamp de pitch, touch consumível/visibilidade e LOW/HIGH. Checks adicionais verificam stamina e limite de movimento diagonal.

Integração: instancia a cena existente e seus assets, cidade/grafo, título, LOW inicial, missão inicial, assentamento do spawn, salto por Espaço, entrada/saída do coupe, resposta de procura, preservação de perfil no dia/noite, consumo de munição e F6. Não completa a missão inteira nem prova todas as interações existentes.

O primeiro teste de integração falhou porque avaliava a altura após um número fixo de frames de renderização; o startup procedural pode executar vários ticks de física entre esses frames. O teste foi corrigido para esperar o chão e observar o pico em frames de física. O salto não foi ajustado para esconder a falha.

## Problemas preexistentes

- Importação inicial do AN-2: referência a `res://assets/aircraft/palette.png` ausente e um Texture2D vazio (`res://`). O importador prosseguiu; o runtime usa textura própria via Models. Falha visual potencial permanece para inspeção manual. Nenhum asset proprietário usado como substituto.
- HDRIs: headers GAMMA/PRIMARIES não suportados são ignorados pelo importador.
- Android: diretório build-tools indisponível. Não impede testes desktop; export Android não validado.
- A importação atualiza metadados `.import`; alterações automáticas serão removidas do diff de entrega, mantendo caches locais ignorados.
- Sem animação específica de salto; idle durante voo. Sem cobertura/recarga/save/facções nesta entrega.

## Referência web e REA

Ferramentas MCP REA disponíveis e executadas: list_browser_targets, inspect_web_page, capture_web_screenshot. O primeiro endpoint não respondia; um Chrome headless separado criou sessão CDP. Uma tentativa PowerShell de lançamento foi bloqueada pela política; o launcher Node permitido abriu o processo. Nenhuma proteção do site foi alterada.

O host direto exibiu Story/Sandbox, depois seleção de mapa e carregamento de Sandbox após inputs comuns enviados pelo CDP. Ficou em 66%/carregamento de áudio e apresentou relatório de travamento. As evidências constam na matriz. REA fez observação passiva; inputs foram enviados por CDP separado. Não observamos combate, direção, polícia, missões ou troca de personagem em gameplay. Fontes de scripts não capturadas; recursos observados apenas como metadados. Nenhum código/asset proprietário incorporado.

## Verificação manual pendente

1. Abrir Godot e jogar: WASD/Shift/Espaço, rampas, tetos baixos, paredes e cantos com mouse.
2. Repetir entrada/saída e freio de mão em carro; embarcar/decolar/pousar no avião.
3. Touch real: arrastar stick e câmera, RUN/JUMP sem interferência nos botões existentes.
4. Alternar F6 e dia/noite, verificar shaders e iluminação nos três perfis em GPU real.
5. Completar roubo/fuga/entrega e testar morte/prisão. O defeito conhecido de respawn antes da entrega está no roadmap.
6. Benchmark 720p em máquina antiga: hardware, renderer, FPS/frame time e memória após 10 min. Metas ainda não medidas.

## Política de cobertura

Checks headless cobrem lógica e física; não certificam compatibilidade com toda GPU, visual, áudio, FPS ou gameplay da referência. Trabalho futuro permanece explicitamente pendente no roadmap.
