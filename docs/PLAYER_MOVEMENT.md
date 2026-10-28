# Movimento

Atualização: C ativa cobertura estática elegível, movimento lateral junto ao obstáculo e saída por C, salto ou movimento para longe. Cobertura baixa agacha e expõe ao ADS após checar espaço de pé. Paredes altas exigem borda para disparar; Hitscan continua bloqueando tiros pelo muro. Degraus de até 0,26 m são transpostos com testes físicos de teto/caminho/suporte; escadas e rampa da Favela foram testadas. Sem transições animadas dedicadas entre cantos.

Preservados salto, coyote time de 0,10 s, buffer de 0,12 s, stamina e touch. WASD usa InputMap; setas continuam alternativas. Ctrl alterna agachamento e verifica cápsula completa antes de levantar. Correndo acima de 6 m/s, Ctrl inicia slide de 0,65 s com cooldown de 1,6 s e atrito; termina agachado. T inicia tactical sprint de 1,4 s, cooldown de 4 s, somente no chão e em movimento. ADS e recarga impedem sprint; slide/tactical impedem disparo.

Estados observáveis: Idle, Jog, Sprint, Crouch, Crouch Walk, Jump, Fall, Land, Aim, Fire, Reload, Slide, Tactical Sprint e Death. Não há clip dedicado para todos esses estados nem modo Walk separado de Jog. Clips locais idle/run são reutilizados. Agachamento reduz visual proporcionalmente à escala original e cápsula de 1,72 m para 1,10 m; apresentação ainda provisória.

Touch conserva joystick, RUN, JUMP e controles de direção, adicionando FIRE, ADS, RELOAD e CROUCH. A disposição precisa de validação em telefone físico. InputMap aparece em Project Settings; CombatInput instala apenas ações ausentes. Veículos mantêm entradas legadas.
