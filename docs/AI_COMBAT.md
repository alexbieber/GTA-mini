# IA — estado anterior aos modos

Atualização: MatchBot implementa combate offline nos dois mapas, com A*, LOS de percepção e disparo, recarga, papel/objetivos e decisões escalonadas; no Royale, memória de 5 s e procura na zona. O código legado de pedestres abaixo permanece arquivado. Sem navegação de lajes, supressão ou busca tática sofisticada de cobertura.

Pedestres conservam patrulha, espera, fuga, reação e perseguição de oficiais. Tiros assustam NPCs próximos mesmo sem acerto; testemunhas civis agora exigem LOS para registrar crime. NPC recebe dano regional, com reação e queda legada.

Não existe ainda IA tática armada: oficiais perseguem como na base, sem navmesh, cobertura, recarga ou memória de combate. O grafo viário existe e pode apoiar navegação de bots nos modos. A próxima etapa deve separar combatentes de população civil, garantir LOS dos tiros, equipes e eliminação/respawn próprios, sem tornar polícia do mundo livre dependente de partida.
