# Desempenho

## Sprint competitiva — medidas de 14/10/2026

Máquina identificada: Intel Core i7-3770 @ 3,40 GHz (4 núcleos/8 threads), cerca de 8 GiB físicos, NVIDIA Quadro 600 1 GiB, OpenGL 3.3 / driver 353.30. Godot 4.7.2, 1280 × 720, Compatibility, LOW, áudio Dummy. Não se usa renderer dummy nas amostras renderizadas abaixo.

| Amostra renderizada de 30 s | FPS médio | p95 frame | Draw calls no último frame | Memória estática do motor |
|---|---:|---:|---:|---:|
| Protege o Corre! 5v5 | 59,97 | 17,09 ms | 141 | 48,5 MiB |
| Favela Royale, 10 participantes | 60,01 | 17,18 ms | 135 | 51,9 MiB |

Scripts: tests/benchmark_competitive.gd, logs JSON em docs/measurements/. Cada amostra teve seis eliminações automáticas por bots, além de navegação e combate; jogador humano ficou parado. Capturas curtas estão próximas do limite de sincronização de 60 Hz; não medem FPS máximo sem VSync. Sem garantia de 60 FPS em toda situação ou 30 FPS estáveis por 10 minutos. Faltam teste prolongado, movimento humano, som real, heat/throttling e todos os perfis.

Carregamento no teste renderizado: menu 522/671 ms; mapa 162 ms (Corre) / 381 ms (Royale), sem incluir boot do processo/importação inicial. Uma leitura Windows durante Corre reportou working set 198,6 MiB e pico até aquele instante 241,2 MiB. Uma leitura no Royale reportou working set 192,2 MiB e pico até aquele instante 192,2 MiB. Essas leituras são snapshots de Windows, não picos garantidos da partida inteira; não confundir memória estática do Godot com RAM total/VRAM.

Comparação headless da cena carregada (tests/measure_startup.gd): mundo aberto arquivado, 5126 ms / 505,1 MiB estáticos / 9427 nodes; menu competitivo, 739 ms / 30,5 MiB / 122 nodes. Rodados em processos separados simultâneos, sem controle de cache do SO; indicam redução de carga, não benchmark de latência universal. Nos snapshots renderizados anteriores, o menu antigo tinha 1878 draw calls/217,4 MiB; o novo menu tem 20 draw calls/cerca de 40 MiB. As cenas diferem e os números não são uma prova isolada de ganho de GPU.

Otimizações implementadas: somente arena selecionada; menu sem Player/City; recursos e atores de partida liberados ao retornar; MultiMesh para módulos estáticos por material; menos de 24 materiais por mapa; tanques de 12 segmentos; colisões simples; A* compartilhado com colisões; decisões de bots em 0,25–0,31 s; pool de 12 efeitos (tracer/flash/impacto); sombras apenas em presets superiores; cutoff visual de módulos a 280 m. Não há streaming, LOD geométrico completo, culling de instâncias internas ao MultiMesh ou bake de occlusion; mapas compactos substituem o custo do mundo aberto. LOW usa cores/materiais compartilhados, sem texturas PBR/HDRI de cidade.

O texto abaixo descreve o incremento anterior e permanece como histórico.

Hardware informado: 8 GB RAM DDR3. Win32_VideoController reportou NVIDIA Quadro 600, 1.073.741.824 bytes (1 GB) de VRAM. Teste renderizado confirmou OpenGL 3.3, driver NVIDIA 353.30. Não foram medidos FPS médio, p95/frame time, draw calls ou memória sob gameplay prolongado.

Compatibility é agora padrão desktop/mobile. LOW continua inicial; F6 conserva LOW/MEDIUM/HIGH. Sombras do sol ativam em MEDIUM/HIGH; SSAO/SSIL/SSR/SDFGI/glow só ativam com Forward+. F6 não troca renderer em runtime. Forward+ pode ser solicitado via CLI/editor em hardware adequado, ainda sem validação GPU nesta máquina. Não se habilitam efeitos caros transitoriamente no startup. LOW não cria ReflectionProbe; presets superiores criam probe como na base.

Efeitos de disparo: pool fixo de 12, duas malhas por slot, vida 55 ms, substituição circular. Dois raycasts por tiro; crouch faz query de cápsula somente ao levantar. Câmera reutiliza esfera. Far plane 900 m. Estimativa qualitativa: custo de lógica pequeno e limitado por tiro, pool evita crescimento de nodes/timers; redução de custo gráfico não quantificada. Cidade/população ainda são carregadas integralmente; sem streaming/LOD completo ou limites de luzes por distância.

Validação pendente: 10 minutos em 720p, modos F6, condução/voo, touch, memória, GPU, clipping, densidade. Captura de 90 frames com --max-fps 30 é smoke gráfico, não benchmark nem garantia de 30 FPS.
