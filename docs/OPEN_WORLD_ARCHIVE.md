# Mundo aberto arquivado — Sprint A

A cena res://scenes/main.tscn e scripts/game.gd permanecem intactos como entrada do mundo aberto histórico. Abrir essa cena explicitamente no editor e executar F6 mantém o roubo/fuga/entrega, veículos, população e polícia. Ela não é carregada pela nova cena principal e não aparece no menu competitivo.

project.godot agora inicia res://scenes/competitive_main.tscn, composta por interface, câmera, iluminação procedural leve e MatchManager. Nenhum City, tráfego, pedestre ou carro é instanciado no menu. Personagem e arena são criados somente na seleção e liberados ao retornar. Modelos/animações de personagem, armas, movimento, câmera e touch são compartilhados. HDRIs/PBR de cidade e veículos ficam preservados em assets, sem seleção automática nesta entrada.

Há um único project.godot neste repositório. origin continua o fork https://github.com/guilherme-alves-puc/GTA-mini.git; upstream continua a origem histórica. Os commits anteriores e o commit sincronizado 1a6971f foram preservados, sem reescrever histórico.
