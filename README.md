# Conecta+

Aplicativo Flutter de descoberta e gerenciamento de eventos.

## Publicar regras do Firebase

Depois de revisar as regras, publique-as no projeto correto com:

```powershell
firebase deploy --project conecta-mais-3e519 --only firestore:rules,storage
```

O upload no Storage exige login e restringe o arquivo a imagens de até 5 MB.
O formulário do app permite que o próprio usuário ative o perfil de criador;
essa regra simplificada é adequada para a demonstração do TCC, não para um
serviço público de produção.

O perfil também permite consultar eventos em que o usuário está inscrito. Essa
consulta lê os eventos e verifica os registros de participação individuais,
além de aceitar inscrições no formato legado. A home é exibida mesmo para
visitantes não autenticados; login só é solicitado para ações que o exigem.
O perfil permite atualizar o nome e a foto. O botão “Enviar convite” nos
detalhes abre o compartilhamento do dispositivo com nome, data, local e preço
do evento. E-mails são alterados após confirmação pelo link enviado pelo
Firebase Auth. Eventos também têm endereço e link para abrir o Google Maps.

## Migrar eventos existentes

Eventos criados antes do uso de timestamps e da contagem `vagasOcupadas` devem
ser migrados antes de aplicar as novas regras. Faça primeiro um backup/export
do Firestore. Para cada documento em `eventos`, converta `dataHoraEvento` de
texto ISO para Timestamp, inicialize `vagasOcupadas` com a quantidade de
inscritos, crie `participantes/{uid}` com `{ "uid": "<uid>" }` para cada UID da
lista antiga e remova `participantesIds` do documento público. Sem essa
migração, os documentos antigos continuam legíveis, mas não aceitam novas
inscrições nem edições que dependam do novo formato.

## Assinatura Android de release

Crie um keystore de release e um arquivo `android/key.properties` local (não
versione esse arquivo) com:

```properties
storePassword=SENHA_DO_KEYSTORE
keyPassword=SENHA_DA_CHAVE
keyAlias=ALIAS_DA_CHAVE
storeFile=C:\\caminho\\para\\upload-keystore.jks
```

Builds de release falham explicitamente se essa configuração não existir; os
builds de debug continuam usando a configuração padrão.
