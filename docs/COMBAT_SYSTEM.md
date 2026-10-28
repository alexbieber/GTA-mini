# Combate — incremento jogável de 14/10/2026

Atualização da sprint competitiva: cobertura estática por C/touch, degraus de até 0,26 m e impacto visual limitado foram adicionados. Os modos utilizam combatentes próprios, equipes, eliminação/respawn e LOS; cobertura/IA e novas cenas estão documentadas em GAME_MODES.md. A lista histórica de pendências abaixo corresponde ao incremento anterior.

Player mantém APIs de veículos, inventário e saúde. WeaponData (.tres) define pistola, SMG e fuzil; carregadores/reservas pertencem ao jogador. Hitscan escolhe alvo pela câmera e valida o percurso a partir de um cano simulado à altura do peito. Parede próxima tem prioridade sobre alvo visto pela câmera. Head/torso/pernas usam altura relativa da cápsula; não são hitboxes ósseas.

HealthComponent oferece armadura opcional, dano, morte, cura e reset explícito. Player e Pedestrian o reutilizam. Veículos continuam com sua API apply_damage. NPCs feridos fogem; ao zerar vida, usam a queda temporária existente e recuperam saúde ao levantar. Eliminação permanente será responsabilidade dos modos competitivos.

HUD mostra carregador/reserva, recarga, retículo dinâmico e hitmarker. ShotEffects pré-aloca 12 slots de tracer/flash sem timers por disparo. O modelo de arma é um placeholder geométrico original, com deslocamento de recuo e pose de recarga.

Não implementados neste incremento: cobertura, IA armada, áudio de tiros, decalques por superfície, IK, ragdoll, granadas, escopeta e rifle de precisão. A aceitação global do master prompt continua aberta. Próximo incremento: regras de partidas offline com bots.
