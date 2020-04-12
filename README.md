# zabbix-ssl-check

## Introduction

This repo contains autodiscovery rules and a set of scripts for Zabbix, which you can use to monitor your SSL certificates.
It automatically discovers which SSL certificates are installed on your server and adds the needed checks for you automatically.
It will inform you when the certificate is about to expire (via an macro you can specify how long in advance you want to be notified).
It doesn't only checks the certificate files on disk, but it also makes an actual connection to the service and checks what it recieved from there.
When it recieves a different certificate via the connection check than it finds on disk, you will get an alert too.

Note: this doesn't only support HTTPS certificates, but all daemons on the internet that have an TLS connection can be checked with this repo (eg. SMTPS or IMAPS services too)

## Installation

### Zabbix webinterface

First we need to import the template in the Zabbix webinterface. This is needed in order to start the autodiscovery and actual checks. This installation is as follows:

1. Go to you Zabbix webinterface
2. Select the option "Configuration" in the top menu
3. Select the option "Templates" in the submenu
4. At the top right corner you see the button "Import", click on it
5. Click the "Browse..." button and select the `zbx_template_ssl_services.xml` file
6. The checkboxes are configured correctly by default, but just to make sure, there should be checkboxes in the rows "Templates" and "Discovery rules" in the column "Create new"
7. Click the "Import" button at the bottom of the screen

You should now have a template called "Template SSL services"

### Zabbix Server

On the Zabbix server itself a few scripts should be installed too. These scripts are needed to make an external connection to the services that are discovered. The actual TLS connection is made from the Zabbix server itself, so it needs some scripts to do so.
The installation of these scripts is as follows:

1. Log in on your Zabbix server via SSH
2. Find out in what directory the external scripts should be placed for your Zabbix Server:

   `grep ExternalScripts /etc/zabbix/zabbix_server.conf`

   which gave me the following result:

   `ExternalScripts=/usr/lib/zabbix/externalscripts`
   
   So I need to go to `/usr/lib/zabbix/externalscripts/`
3. Upload the scripts starting with `sslcert_` to this directory (scp, sftp, copy and paste via an editor, whatever works for you)
4. Give the scripts the correct permissions:

   ```  
   chown root:zabbix sslcert_*
   chmod 750 sslcert_*
   ```

### Zabbix Agent

On the Zabbix Agent a few scripts are also needed. One of these script does the autodiscovery, so you won't have to add your SSL certificates by hand. The rest of the scripts check if the certificate isn't expired and are used to validate that the certificate on dis is the same as what the service is providing.  
I recommend that you install these scripts on your Agent with some sort of automation tool, like Puppet, Ansible or Salt Stack. I will explain the manual installation here, so you can convert it to your automation tool of choice

1. Log in on a Zabbix Agent
2. Go to the dynamic zabbix agent configuration directory:

   `cd /etc/zabbix/zabbix_agentd.d/`
   
3. Upload the `userparameter_ssl.conf` file into this directory
4. Restart your Zabbix Agent
5. Go to the directory `/usr/local/bin`:

   `cd /usr/local/bin`
   
6. Upload the script starting with `zabbix_ssl_cert_` into this directory
7. Fix the permissions on these scripts:

   ```
   chown root:zabbix zabbix_ssl_cert*
   chmod 750 zabbix_ssl_cert*

### Configure and test a host

All that is left now is the configuration of a host so it will actually start checking the SSL certificates. You do this as follows:

1. Go to your Zabbix webinterface
2. Select the option "Configuration" in the top menu
3. Select the option "Hosts" in the submenu
4. Click on the name of the host for which you want to enable this check
5. Go to the tab "Templates" right next to "Host" which is opened by default
6. In the text field at "Link new templates" you type "ssl" and the suggestion "Template SSL Services" should become visible
7. Click this suggestion
8. Click the "Update" button at the bottom of the screen

It can be a pain to wait for Zabbix to start running these checks by itself, so you can force it like this:

1. Go to your Zabbix webinterface
2. Select the option "Configuration" in the top menu
3. Select the option "Hosts" in the submenu
4. Behind the host you just edited you find the link "Discovery", click on it
5. Tick the box before "Template SSL services: Configured SSL certificates"
6. Click the button "Check now" at the bottom of the screen

Now you should see newly discovered items about your SSL certificates. To force the retrieval of data for these items:

1. Go to your Zabbix webinterface
2. Select the option "Configuration" in the top menu
3. Select the option "Hosts" in the submenu
4. In the search from at the Hosts field, start typing the name of your server. A suggestion box with your server name will pop up, click it
5. In the Application field type "SSL Certificates"
6. Press "Apply"
7. You will now get a list of all the autodiscovered items for this server. Click the checkbox just above this table, to select all the items
8. Scroll to the bottom of the screen and click the "Check now" button, so all the items will retrieve the needed information

# Configuration

There is really only one setting that can be tuned. The amount of time a certificate is still valid before you get a notification. By default this is set to 7 days (604800 seconds), but you can overrule this on a per host basis.
There is a macro called `{$WARNINGTIME_SEC}` which you can use to overrule the default.

# Only external checks

This script adds two types of checks when it discovers an certificate on a host: it checks in the certificate file when it expires, and it sends a TLS connection to the service itself to also see what the expiration date is send from the service.
This second check you can also manually configure, to be able to check TLS services for which you want to know the status, but can't install an Zabbix Agent on, for some reason. You can configure additional external checks like this:

1. Log in on your Zabbix webinterface
2. Select the option "Configuration" in the top menu
3. Select the option "Hosts" in the submenu
4. Click on "Items" behind your Zabbix server
5. At the top right you see a button called "Add item". Click it
6. Fill in a name that describes this extra check
7. At "Type" choose for "External Check"
8. The "Key" is `sslcert_expiredate.sh[<your_domainname>, https]`, off course you need to place your own domain name in this statement.
9. "Type of information" should be set to "Text"
10. I recommend to set "Update interval" to "1d", so it will check the certificate once a day. Normally your certificates don't change that often, so once a day is plenty (imho)
11. Select the application "SSL Certificates" or create this application if needed.
12. Click the "Add" button at the bottom

Now this external TLS service will be checked too.
You can also choose the "Key" `sslcert_secondsvalid.sh[<your_domainname>, https]` to retrieve the exact number of seconds the certificate is still valid. "Type of information" should be set to "Integer (unsigned)". If the value of this item becomes 0, the certificate has already expired.