# Desempenho

Hardware informado: 8 GB RAM DDR3. Win32_VideoController reportou NVIDIA Quadro 600, 1.073.741.824 bytes (1 GB) de VRAM. Teste renderizado confirmou OpenGL 3.3, driver NVIDIA 353.30. Não foram medidos FPS médio, p95/frame time, draw calls ou memória sob gameplay prolongado.

Compatibility é agora padrão desktop/mobile. LOW continua inicial; F6 conserva LOW/MEDIUM/HIGH. Sombras do sol ativam em MEDIUM/HIGH; SSAO/SSIL/SSR/SDFGI/glow só ativam com Forward+. F6 não troca renderer em runtime. Forward+ pode ser solicitado via CLI/editor em hardware adequado, ainda sem validação GPU nesta máquina. Não se habilitam efeitos caros transitoriamente no startup. LOW não cria ReflectionProbe; presets superiores criam probe como na base.

Efeitos de disparo: pool fixo de 12, duas malhas por slot, vida 55 ms, substituição circular. Dois raycasts por tiro; crouch faz query de cápsula somente ao levantar. Câmera reutiliza esfera. Far plane 900 m. Estimativa qualitativa: custo de lógica pequeno e limitado por tiro, pool evita crescimento de nodes/timers; redução de custo gráfico não quantificada. Cidade/população ainda são carregadas integralmente; sem streaming/LOD completo ou limites de luzes por distância.

Validação pendente: 10 minutos em 720p, modos F6, condução/voo, touch, memória, GPU, clipping, densidade. Captura de 90 frames com --max-fps 30 é smoke gráfico, não benchmark nem garantia de 30 FPS.
