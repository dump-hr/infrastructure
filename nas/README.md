# nas

NAS is used as central place to store footage archive of all DUMP events.

## Update configuration

Install ansible dependencies:

```
ansible-galaxy collection install community.general
```

Run ansible playbook:

```
ansible-playbook playbook.yml -i inventory.ini -vkK --ask-vault-pass
```

## Backups

All backups are stored in private SharePoint [site](https://dumphr.sharepoint.com/sites/nas-backup/Shared%20Documents/Forms/AllItems.aspx)
and are running at 23:00 every Wednesday and Saturday.

As restic (program we use for encrypted backups) doesn't have sharepoint
interface, rclone is used as proxy between them and is running as a service on
machine. Client secret from [sharepoint-backup](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/51ca1c13-acba-480c-9da8-081272faf7c7) 
azure application is used for sharepoint site r/w access and it will expire
in **August 2024** so it should need to be renewed before that.

[This](https://rclone.org/onedrive/) guide from rclone documentation can be used
as reference for updating or creating new rclone sharepoint configuration.

Also note that our storage quota per site on SharePoint is 25TB (total for all
sites is 9.5PB) so other options will have to be explored when we approach that
storage size.

## ZFS

TBD

### ZFS migration of November 2022

TBD

## Hardware

TBD