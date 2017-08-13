# -*- coding: utf-8 -*-
"""
Created on Sat Aug 12 18:59:05 2017

@author: esssfff
"""

import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('10.36.154.164', username='t3200450', password='Oss@2017')
stdin, stdout, stderr = ssh.exec_command('pwAdmin -l | grep BGNA')
print stdout.readlines()
ssh.close()
