# Câmera híbrida

CameraRig conserva exploração, carro e avião e resolução de obstáculos por esfera/ray. Combate aproxima o braço para 3,8 m; ADS para 2,6 m e FOV 48 (exploração 70). Valores e sensibilidade ADS (0,55) são configuráveis no script. Q troca ombro. ADS interpola pelo tempo da arma; saída leva 0,12 s. Após tiro, contexto de combate permanece 2 s. Com arma equipada, alvo da câmera fica à frente do personagem mesmo em exploração, para tornar o tiro livre coerente com retículo.

Recoil vertical/horizontal é separado da órbita manual, limitado e recuperado exponencialmente. Recoil strength permite desligar recuo visual. Volume de colisão permanece world; terceiros podem ocupar a câmera. Limite de pitch a pé ampliado. Far plane reduzido de 2800 para 900 m; visão de aeronaves distantes exige avaliação manual.

ADS, FOV, sensibilidade, recuperação e retorno de modo são cobertos por testes. Captura renderizada em Compatibility foi inspecionada; não certifica jogabilidade manual ou primeira pessoa. Primeira pessoa/IK não implementados.
