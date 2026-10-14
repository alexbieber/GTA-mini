# Sprint F — preparação, sem multiplayer implementado

O projeto atual é offline. Não há host, cliente, lobby replicado, RPC de gameplay, reconciliação, servidor ou teste entre duas instâncias. Nenhuma conexão isolada será tratada como partida online concluída.

Fundação já implementada: IDs por participante/objetivo, MatchRules separado de Nodes, snapshots copiados, estados de zona/objetivos, validação de vida/equipe/spawn/alcance de interação/captura, resolução determinística de empate e eventos de locução. A composição local é autoridade somente da simulação offline. Preparação não certifica segurança contra cliente malicioso.

Próximo incremento deverá adicionar transporte Godot, registro persistente de sessão, lobby de equipe, relógio/ticks do servidor, spawn replicado e inputs com número de sequência. Servidor valida cadência/munição/posição/LOS/dano, interação/portador/deposito, score, eliminados e zona. Cliente envia intenções, nunca incrementa score ou declara morte. Zona, objetivos e eventos de locutor precisam de IDs/ordem para deduplicação e reconnect. Desconexão remove participante/derruba pacote e resolve sobreviventes conforme política documentada.

Gate online: duas instâncias independentes devem completar partida e concordar em spawn, dano, munição, morte/respawn, portador, captura, score, centro/raio de zona, locução e vitória. Testar perda/atraso de pacotes, reconexão, timeout, concorrência de captura, morte simultânea e cliente tentando alterar equipe/posição/dano. Somente após isso o menu poderá anunciar multiplayer funcional.
