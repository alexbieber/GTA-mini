# Armas

Editar resources/weapons/pistol.tres, smg.tres e rifle.tres no inspector. WeaponData é Resource e Arsenal mantém spec/IDs/preços para lojas e caixas existentes. Dados incluem dano, alcance, cadência, carregador, reserva inicial, recarga, recoil, ADS/spread em movimento, mobilidade e multiplicadores regionais. Resources compartilhados são dados; munição mutável fica em Player.

Pistola: 12/24 inicial, semiautomática, recarga 1,5 s. Fuzil: 30/18, automático, 2,2 s. SMG: 30/50, automática, 1,9 s. Munição inicial é total distribuído, não soma gratuita. R recarrega, troca/veículo/morte cancelam sem transferir munição. Compra/pickup adiciona reserva. Recarga só transfere faltantes ao finalizar. Sem autoshoot semiautomático, munição negativa ou recarga durante bloqueio.

Armas continuam disponíveis na loja via 1–3 e na caixa da base; 4 compra munição. Não se concede equipamento gratuito no Caos Livre. R conserva respawn após morte/prisão. Número de armas e controles touch serão ampliados nos modos; escopeta/precisão pendentes. Não há persistência em disco.
