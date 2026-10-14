# Progresso — reconstrução FPS urbana

Nome: OPERAÇÃO CAOS. Direção atual: FPS original inspirado em funcionalidades observáveis, CTF 5v5 e Battle Royale de oito participantes. As direções antigas de pacote/10 participantes foram substituídas por esta solicitação. Vozes, assets locais e mundo aberto arquivado são preservados.

| Marco | Estado | Evidência atual |
|---|---|---|
| Checkpoint | IMPLEMENTADO | Git 3e5f1a4, antes da reconstrução |
| M1 Auditoria REA e arquitetura | IMPLEMENTADO com limites | HOOD_WARFARE_REFERENCE, GAMEPLAY_FEATURE_MATRIX, REBUILD_ARCHITECTURE; gameplay Steam NÃO VERIFICADO |
| M2 FPS e armas | PARCIAL, em execução | FPS/placas/mantle: 52 checks prévios; escopeta/shared WeaponSystem/FOV/aceleração novos aguardam fechamento |
| M3 5v5 e bandeiras | PARCIAL, em execução | Migração para duas bandeiras e exigência de bandeira aliada na base |
| M4 Battle Royale | PARCIAL, em execução | Arena/zona/loot reaproveitados; configuração reduzida para oito participantes |
| M5 Bots | PARCIAL, em execução | NavigationAgent/FSM/percepção/dificuldades, aguardam integração final |
| M6 Vozes e interface | PARCIAL | Bancos originais e hashes; sem transcrições verificadas; pausa/progressão/interface em execução |
| M7 LAN | PARCIAL, em execução | ENet/lobby/autoridade em teste entre processos; não anunciar concluído antes do gate |
| M8 Otimização e testes finais | PARCIAL | Compatibility/LOW/instâncias/pool já existentes; métricas anteriores não certificam reconstrução |

Atualizar este relatório após executar cada marco. Compilação não substitui gameplay. Evidências REA e testes do projeto são autoridades distintas. Resultados anteriores: 193 checks de regressão e 52 do primeiro incremento FPS; novos resultados e capturas serão listados quando concluídos.
