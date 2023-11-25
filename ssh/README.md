## Executando scripts remotos via ssh com chaves assimétricas
O SSH, Secure Shell, é o mecanismo responsável por conectar o terminal de uma máquina ao terminal de outra máquina remotamente através da internet. 
                            
Ou seja, é um tipo de protocolo de comunicação criptografada entre computadores, normalmente servidores de aplicações, arquivos, emails, etc…
Através do ssh é possível executar comando de uma máquina local em um servidor remoto, o ssh é fundamental para a manutenção remota com um alto nível de segurança, de computadores que estão geograficamente distantes.
Este protocolo está presente em quase todas as distribuições Linux, portanto não é necessário instalação e configuração, mas caso o comando ssh não esteja disponível no terminal, basta instalar via apt: 
```bash
$ apt-get install openssh-server -y
```
Normalmente as configurações padrões já são suficiente, mas caso seja necessário alguma customização basta consultar o manuel, digite:
```bash
$ man ssh
```
Bom o uso é bem simples, só com o comando:
```bash
$ ssh thalyson@servidor
```
já é possível iniciar uma nova sessão remota, basta digitar a senha do usuário thalyson e os terminais estarão conectados em poucos segundos.
    
Mas em algumas situações digitar a senha não é muito interessante, imagine a situação ao qual um servidor local precisa se conectar aos servidores de aplicações remotas para copiar os arquivos de backups todos os dias às 3:30 da manhã. Seria desumano pedir para alguém ficar acordado ou acordar todos os dias esse horário somente para digitar uma senha…

Para simplificar a vida do sysadmin existe o conceito de autenticação via chave pública e privada.
Nesse mecanismo duas chaves de criptografia são geradas, uma chave de criptografia pública e uma chave de criptografia privada. O SSH é responsável por sincronizar a chave pública alocada no servidor remoto, com a chave privada alocada na máquina local, as duas chaves combinadas geram ,portanto, uma via de comunicação criptografada e segura.

Vamos à prática.
O comando:
```bash
$ ssh-keygen -t rsa
```
Irá criar as chaves públicas e privadas, mas antes ele vai te fazer algumas perguntas

 - output_keyfile
	 - Onde os arquivos serão salvos, por padrão ele vai criar os arquivos id_rsa.pub (Chave pública) e id_rsa (Chave privada) no diretório /root/.ssh/, mas se você digitar um caminho válido como /root/.ssh/id_server_1, as chaves id_server_1.pub e id_server_1 serão criadas no diretório /root/.ssh
 - new_passphrase
	 - Depois ele vai pedir para você definir uma frase de segurança, a frase de segurança nada mais é do que uma senha para acessar a chave privada. Uma camada a mais de segurança, mas não é obrigatória. Eu normalmente crio informando a frase de segurança em branco, Só aperto enter mesmo.
    
Certo, temos as chaves agora vamos configurar o servidor. É bem simples.

Basta digitar:
```bash
$ ssh-copy-id -i ~/.ssh/id_rsa.pub thalyson@server
```
Vai ser preciso digitar a senha do usuário na primeira vez que a chave pública for copiada para o servidor remoto, feito isso, se nenhum erro ocorrer significa que tudo deu certo.

Agora é só testar:

```bash
$ ssh thalyson@server
```
O acesso ao servidor será automático, mas se você tiver criado uma chave privada com senha você terá que informar essa senha no momento da conexão.

O que acontece é que...
O ssh por ser um protocolo ele vai transmitir e receber pacotes criptografados, ou seja, ele vai criptografar o comando informado com a chave privada, gerando assim um cadeado específico, e irá transmitir esse cadeado para o servidor remoto que por sua vez irá utilizar a chave pública para abrir o cadeado e executar o comando, depois ele pega o resultado tranca em outro cadeado com a chave pública e devolve para o outro lado. No outro lado, por sua vez, a informação é descriptografada e o resultado é exibido no terminal.

Terminais devidamente autenticados com conexão perfeitamente criptografada, agora é a hora de avançar.

É muito comum precisarmos copiar arquivos tanto da máquina local para o servidor remoto, quanto do servidor remoto para a máquina local. Para tanto existe um utilitário bastante habilidoso para lidar com essa tarefa o OpenSSH secure file copy, o **scp**.

O uso do scp é simples.

Para copiar um arquivo da máquina local para o servidor remoto

```bash
$ scp /origem/arquivo.txt thalyson@server:/destino/arquivo.txt
```
Nesse exemplo eu copiei o arquivo presente no path **/origem/arquivo.txt** da máquina local para o path **/destino/arquivo.txt** da máquina remota.

Sendo assim, para copiar um arquivo do servidor remoto para a máquina local, basta inverter os argumentos
```bash
$ scp thalyson@server:/origem/arquivo.txt /destino/arquivo.txt
```
E então o arquivo que está no path **/origem/arquivo.txt** da máquina remota será criado no path **/destino/arquivo.txt** da máquina local.

Nesse ponto é importante ter um pouquinho de atenção com aos paths local e remoto, só lembrando que todo path que começa com **/** se refere a um caminho absoluto, o que não começa com **/** se refere ao path relativo.

Avançando...

Vamos criar dois arquivos, um que será enviado ao servidor remoto e outro que ficará na máquina local, ambos se comunicarão entre si para gerar um backup apenas como exemplo.

Então, *let’s bori codar.*

Crie o arquivo spinarak.sh e adicione o conteúdo abaixo
```bash
#!/bin/bash
# https://www.pokemon.com/br/pokedex/spinarak
# With threads from its mouth, it fashions sturdy webs that won’t break even if you set a rock on them
BACKUP_FILE_NAME=$1 
tar Jcf  $BACKUP_FILE_NAME /var/log/auth.log
```

 - #!/bin/bash
	 - A primeira linha define o shebang bash
 - as duas próximas linhas são comentários relacionados ao pokemón escolhido para esse exemplo.
 - BACKUP_FILE_NAME=$1
	 - Eu defini uma variável chamada **BACKUP_FILE_NAME** que irá receber o valor do primeiro argumento enviado ao spinarak.sh
 - tar  Jcf  $BACKUP_FILE_NAME  /var/log/auth.log
	 - Esta linha vai compactar o arquivo de registro de login e logoff da máquina remota e irá gerar um arquivo com o nome que será passado ao script.

Agora eu vou criar o arquivo itkca.sh com o conteúdo abaixo:
```bash
#!/bin/bash
TODAY=$(date +%Y%m%d%H%m%S)

USER=thalyson  # usuário
SERVER=server  #host

BACKUP_FILE_NAME="backup.$TODAY.txz"

ssh  $USER@$SERVER  ./spinarak.sh  $BACKUP_FILE_NAME
scp  $USER@$SERVER:$BACKUP_FILE_NAME  $BACKUP_FILE_NAME
```
Certo, agora vamos copiar o spinarak.sh para o servidor

```bash
$ scp spinarak.sh thalyson@server:/root/spinarak.sh
```
É importante lembrar que o arquivo precisa de permissão de execução

```bash
$ ssh thalyson@server chmod +x /root/spinarak.sh
```

O arquivo tikcah.sh também vai precisar de permissão para ser executado na máquina local, portanto dê a ele a permissão

```bash
$ sudo chmod +x ./itkcah.sh
```

Agora quando o arquivo itkcah.sh for executado, em alguns poucos segundos você terá o backup de todos os login e logoff feitos na máquina remota =)

Recapitulando...

Em um breve resumo a comunicação via ssh é muito comum e a utilização de chaves assimétricas pública e privada é muito importante na vida de um programador, e também facilita bastante a execução remota de rotinas automatizadas entre computadores.