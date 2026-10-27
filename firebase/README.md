# Regras do Firebase

Publique `firestore.rules` e `storage.rules` pelo Firebase Console ou Firebase CLI antes de distribuir o app.

As regras impedem que o cliente promova a própria conta para organizador. A promoção deve ser feita por uma função administrativa confiável, como Cloud Functions ou o Firebase Console. As regras de Storage permitem apenas imagens de até 5 MB no caminho `eventos/` para usuários autenticados.
