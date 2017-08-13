# -*- coding: utf-8 -*-
"""
Spyder Editor
"""

import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('146.250.143.82', username='qesttsu', password='ericsson123')
ssh.connect('claro', username='qesttsu', password='Altera.5')

stdin, stdout, stderr = ssh.exec_command('df -h')
print stdout.readlines()
ssh.close()