# Power Shell Scipts

1 - <b>ConfigureRPCPorts.ps1</b> - Due Docker container has a problem to handle a huge amount of exposed ports from a container, when you conteinerize a RPC application you need to restric the amount of ports of it. This script restric the Windows RPC ports to 64535 to 65535.

2 - <b>CreateComPlusApp.ps1</b>

3 - <b>Wait-Service.ps1</b>

4 - <b>Create Bulk-Import-Users-to-AAD</b> -   This script read a .csv file and insert them to Azure Active Directory tenant
    You need to download the following two components in order to be able to connect to our Azure AD:
    
    Microsoft Online Services Sign-In Assistant for IT Professionals RTW https://www.microsoft.com/en-us/download/details.aspx?id=41950

    Azure Active Directory Module for Windows PowerShell (64-bit )http://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185
