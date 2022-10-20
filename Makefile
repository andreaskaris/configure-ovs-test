.PHONY: configure-ovs
configure-ovs:          ## Reset interface configuration. 
	ansible-playbook playbooks/configure-ovs.yml --extra-vars="mode=$@"
.PHONY: reset
reset:          ## Reset interface configuration. 
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: single
single: reset          ## Deploy a single interface configuration.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: single-ipv6
single-ipv6: reset          ## Deploy a single interface configuration.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: bond
bond: reset          ## Deploy a configuration with a bond.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: bond-vlan
bond-vlan: reset          ## Deploy a configuration with a bond and vlan.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
help:           ## Show this help.
	@egrep '^[^ |^.]+:' $(MAKEFILE_LIST) | sed -e 's/:.*##/:\t/'
