# GleSYS API/Ansible Demo for deplopying a WordPress environment.

This is an automated procedure to:

  * Create and config a database server.
  * Create and config 2 or more web servers.
  * Create and config a loadbalancer to balance the trafic between the web servers.
  * Create and config a file storage valume and share it with the web servers.
  * Install WordPress, base install with Ansible (http://docs.ansible.com)
  * Set DNS record for the specified domain.

..............................................................



Finally, run the script ./deploy.sh (be sure to meet the requirements in the parent's [README.md](https://github.com/glesys/ansible-wp-auto-deploy/blob/master/README.md) ) and don't forget to put your API Credentials :

```
	cd cluster/
	export API_USER="PLACE YOUR GLESYS PROJECT ID HERE"
	export API_KEY="PLACE YOUR API KEY HERE"
	./deploy.sh USERNAME FQDN  # (for example: ./deploy.sh wp_user blog.domain.com)
```
## This will be installed on the remote host

	- Two or more web servers
		Debian 9 as template
		Apache 2.4
		PHP 7.0
		Postfix (SMTP)
		Latest WordPress (post-setup config is done with http://wp-cli.org )
	
	- One database server
		debian 9 as template
		MariaDB 10
	
	- One load balancer
	

## GleSYS API calls used for this demo


   * [Create Server](https://github.com/GleSYS/API/wiki/API-Documentation#servercreate)
   * [List Domain Records](https://github.com/GleSYS/API/wiki/API-Documentation#domainlistrecords)
   * [Add Domain Record](https://github.com/GleSYS/API/wiki/API-Documentation#domainaddrecord)
   * [Update PTR for IP](https://github.com/GleSYS/API/wiki/API-Documentation#ipsetptr)
   * [Load Balancer](https://github.com/GleSYS/API/wiki/API-Documentation#loadbalancer)
   * [File Storage](https://github.com/GleSYS/API/wiki/API-Documentation#filestorage)

#Support
If you need further help send an email to support@glesys.se
