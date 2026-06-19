# Política de Privacidade do Dry Eye Widget

Última atualização: 19 de junho de 2026

Esta Política de Privacidade explica como o Dry Eye Widget trata informações durante o uso do aplicativo para Windows e macOS. O princípio central é simples: o aplicativo foi projetado para funcionar localmente e não enviar dados de atividade do usuário para fora da máquina.

## 1. Resumo

O Dry Eye Widget não possui telemetria de atividade, analytics de uso, monitoramento remoto ou envio de histórico de comportamento.

| Tema | Como o Dry Eye Widget trata |
| --- | --- |
| Dados de atividade | Não coleta, não registra e não envia para fora da máquina. |
| Detecção de inatividade | Consulta localmente apenas os segundos desde a última entrada do usuário. |
| Teclas, cliques e cursor | Não grava teclas, cliques, coordenadas, trajetória ou histórico do cursor. |
| Janelas e aplicativos | Não identifica aplicativos abertos, títulos de janelas ou sites acessados. |
| Capturas de tela | Não tira screenshots nem analisa a tela. |
| Câmera (presença) | **Opcional e desligada por padrão.** Quando ativada, tira **uma única foto local**, verifica se há um rosto e **descarta a imagem na hora** — sem gravar nem enviar. |
| Aprendizado de inatividade | Estado agregado guardado **cifrado** no próprio dispositivo (Keychain/DPAPI), sem histórico de eventos e sem acesso remoto. |
| Configurações | Salvas localmente para manter preferências do usuário. |
| Questionário OSDI | Quando usado, respostas, pontuação, gravidade e data ficam salvas localmente para histórico do próprio usuário. |
| Tempo de tela | Quando ativado, salva histórico diário agregado de tempo ativo de tela, descartando períodos de inatividade. |
| Atualizações | A checagem opcional consulta o GitHub Releases e não inclui dados de atividade. |

## 2. Dados que o aplicativo não coleta

O Dry Eye Widget não coleta, armazena, compartilha, vende ou envia para fora da máquina dados de atividade do usuário.

Isso inclui, sem limitação:

- histórico de navegação;
- sites visitados;
- aplicativos abertos;
- nomes ou títulos de janelas;
- textos digitados;
- senhas;
- conteúdo da área de transferência;
- teclas pressionadas;
- cliques;
- coordenadas do mouse;
- caminho percorrido pelo cursor;
- capturas de tela;
- imagens da webcam, **exceto** quando o usuário ativa explicitamente a confirmação de presença pela câmera (ver seção 3.1), que processa **um único quadro localmente e o descarta**, sem gravar nem enviar;
- áudio do microfone;
- conteúdo de arquivos locais;
- produtividade, presença, atenção ou classificações comportamentais;
- logs detalhados sobre quando o usuário trabalhou, parou, voltou ou se afastou.

O aplicativo também não usa esses dados para publicidade, perfilamento, vigilância, pontuação de produtividade ou análise comportamental.

## 3. Como funciona a detecção de inatividade

A detecção de inatividade do Dry Eye Widget usa recursos locais do sistema operacional para consultar o tempo decorrido desde a última entrada global do usuário no sistema, como movimento do mouse, clique ou tecla.

Essa consulta retorna apenas um valor de tempo, em segundos. O aplicativo usa esse valor para:

- pausar o timer quando o usuário parece estar longe do computador;
- exibir um aviso pequeno de pausa por inatividade;
- retomar automaticamente o timer quando o sistema perceber nova atividade;
- permitir retomada manual por um botão minimalista, quando disponível.

Esse mecanismo não informa qual tecla foi pressionada, onde o usuário clicou, qual janela estava aberta, qual site estava sendo acessado ou qual conteúdo estava na tela. O Dry Eye Widget não transforma esse contador local em histórico de atividade e não o envia para servidores externos.

O limiar que separa "pausa" de "ausência" é **aprendido localmente** a partir dos padrões do próprio usuário. Esse aprendizado é guardado apenas como um **estado agregado** (poucos números, sem eventos brutos nem linha do tempo), **cifrado em repouso** pelo sistema (Keychain no macOS, DPAPI no Windows), sem acesso remoto. Há um botão nas configurações para apagar esse aprendizado.

### 3.1 Confirmação opcional de presença pela câmera

A partir da versão 1.8, o Dry Eye Widget oferece um recurso **opcional e desligado por padrão**: confirmar a presença do usuário pela câmera quando o sistema fica ocioso. Quando — e somente quando — o usuário ativa esse recurso e concede a permissão de câmera do sistema:

- no momento em que a inatividade atinge o limiar, o app captura **um único quadro** da câmera;
- o processamento é **100% local** (no macOS, via o framework Vision do sistema): verifica apenas **se há um rosto enquadrado**;
- a imagem é **descartada imediatamente** após essa verificação — **não** é gravada em disco, **não** é enviada pela rede e **não** é transformada em histórico;
- o resultado usado pelo app é apenas um sinal "presente / ausente".

O recurso pede **consentimento explícito** antes de o sistema solicitar a permissão de câmera, pode ser **desligado a qualquer momento** e, quando desligado, a câmera **nunca** é acionada. No Windows, a confirmação por câmera ainda não está disponível.

## 4. Dados salvos localmente

Para funcionar de forma conveniente, o aplicativo pode salvar preferências e estados simples no próprio computador, como:

- intervalos de pausa e duração dos lembretes;
- configurações de notificação, áudio e modo suave;
- idioma, tema, escala e preferências visuais;
- posição do widget na tela;
- progresso de timers para retomada após reiniciar o app;
- preferência de iniciar ou não com o sistema;
- histórico local do questionário OSDI, quando o usuário usa esse recurso;
- histórico diário agregado de tempo de tela, quando o usuário ativa essa coleta.

Esses dados são usados apenas para manter a configuração do usuário, a continuidade da experiência e a visualização local do próprio histórico. Eles ficam armazenados localmente pelo mecanismo de preferências do aplicativo ou do sistema operacional.

O Dry Eye Widget não envia essas preferências para servidores próprios, serviços de analytics ou terceiros.

## 5. Comunicações externas

O Dry Eye Widget não envia dados de atividade do usuário para fora da máquina.

A única comunicação externa prevista pelo aplicativo é a verificação opcional de atualizações no GitHub Releases, quando esse recurso é acionado no app. Essa consulta compara a versão instalada com a versão mais recente publicada.

A verificação de atualizações não inclui histórico de atividade, inatividade, teclas, cliques, cursor, janelas abertas, capturas de tela ou preferências médicas do usuário.

Como em qualquer acesso a um endereço externo, o GitHub, o navegador, o sistema operacional, o provedor de internet ou a rede corporativa podem processar metadados técnicos da conexão, como endereço IP, horário da requisição, user-agent e registros de rede. Esses metadados não são dados de atividade coletados pelo Dry Eye Widget e não são controlados pelo aplicativo.

## 6. Notificações locais

Quando habilitadas, as notificações do Dry Eye Widget são exibidas localmente pelo sistema operacional. Elas servem para avisar sobre pausas, retomadas, descanso ocular ou lembretes configurados.

As notificações não exigem envio de dados de atividade para fora da máquina.

## 7. Inicialização com o sistema

Se o usuário ativar a opção de iniciar com o sistema, o Dry Eye Widget pode registrar essa preferência no mecanismo local de inicialização do Windows ou do macOS.

Essa função apenas abre o aplicativo automaticamente. Ela não coleta dados de atividade e não cria monitoramento remoto.

## 8. Controle do usuário

O usuário pode controlar o uso do aplicativo pelas configurações disponíveis no próprio Dry Eye Widget e pelo sistema operacional.

Em geral, o usuário pode:

- desativar notificações;
- desativar sons;
- desativar a inicialização com o sistema;
- desativar a confirmação de presença pela câmera;
- desativar a coleta de tempo de tela;
- apagar o aprendizado local de inatividade;
- ajustar tempos e pausas;
- fechar o aplicativo;
- desinstalar o aplicativo;
- apagar dados locais do app pelos mecanismos do sistema operacional, quando desejar limpar preferências.

Se o usuário sincronizar, copiar ou fizer backup de pastas locais por meio de ferramentas externas, essas ferramentas podem tratar os arquivos conforme suas próprias políticas. Isso fica fora do controle do Dry Eye Widget.

## 9. Segurança

O aplicativo reduz riscos de privacidade ao evitar coleta de dados de atividade e ao manter as preferências no próprio computador. Ainda assim, a segurança do ambiente também depende do sistema operacional, permissões, antivírus, políticas corporativas, backups e ferramentas de sincronização instaladas pelo usuário.

## 10. Crianças e adolescentes

O Dry Eye Widget não é direcionado à coleta de dados de crianças ou adolescentes. Como o aplicativo não coleta nem envia dados de atividade para fora da máquina, ele não cria cadastro, perfil ou monitoramento remoto de menores.

Responsáveis devem orientar o uso do computador, pausas e cuidados oculares conforme a idade, rotina e recomendações profissionais.

## 11. Alterações desta política

Esta Política de Privacidade pode ser atualizada para refletir mudanças no aplicativo, na documentação ou em requisitos legais. A data de última atualização deve ser revisada sempre que houver alteração relevante.

## 12. Contato

Dúvidas, sugestões, relatos de bugs ou pedidos relacionados à privacidade devem ser enviados pelos canais oficiais do repositório do Dry Eye Widget, como issues ou discussões no GitHub quando disponíveis.
