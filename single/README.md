# GleSYS API/Ansible Demo

This is an automated procedure to:

  * create a server with provided FQDN
  * set DNS record for the specified domain
  * set PTR record to the newly created servers IP
  * install WordPress, base install with Ansible (http://docs.ansible.com)

..............................................................



Finally, run the script ./deploy.sh (be sure to meet the requirements in the parent's [README.md](https://github.com/glesys/ansible-wp-auto-deploy/blob/master/README.md) ) and don't forget to put your API Credentials :


```
	cd single/
	export API_USER="PLACE YOUR GLESYS PROJECT ID HERE"
	export API_KEY="PLACE YOUR API KEY HERE"
	./deploy.sh USERNAME FQDN  # (for example: ./deploy.sh wp_user blog.domain.com)
```


## This will be installed on the remote host


	Debian 9 as template
	Apache 2.4
	PHP 7.0
	Postfix (SMTP)
	Latest WordPress (post-setup config is done with http://wp-cli.org )
	MariaDB 10


## GleSYS API calls used for this demo


   * [Create Server](https://github.com/GleSYS/API/wiki/API-Documentation#servercreate)
   * [List Domain Records](https://github.com/GleSYS/API/wiki/API-Documentation#domainlistrecords)
   * [Add Domain Record](https://github.com/GleSYS/API/wiki/API-Documentation#domainaddrecord)
   * [Update PTR for IP](https://github.com/GleSYS/API/wiki/API-Documentation#ipsetptr)


## Support
If you need further help send an email to support@glesys.se
