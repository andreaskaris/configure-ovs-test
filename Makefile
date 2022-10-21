.PHONY: deps
deps: ## Install dependencies.
	yum install -y nmstate ansible
.PHONY: configure-ovs
configure-ovs:          ## Import configure-ovs script and run it.
	ansible-playbook playbooks/configure-ovs.yml --extra-vars="mode=$@"
.PHONY: reset
reset:          ## Reset interface configuration. 
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: single
single: reset          ## Deploy a single interface configuration.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: single-staic
single-static: reset          ## Deploy a single interface configuration with static IP addressing.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: single-ipv6
single-ipv6: reset          ## Deploy a single interface configuration for IPv6.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: single-ipv6-static
single-ipv6-static: reset          ## Deploy a single interface configuration for IPv6, static.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: bond
bond: reset          ## Deploy a configuration with a bond.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: bond-invalid-intf
bond-invalid-intf: reset          ## Deploy a configuration with a bond with one invalid slave interface.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
.PHONY: bond-vlan
bond-vlan: reset          ## Deploy a configuration with a bond and vlan.
	ansible-playbook playbooks/apply.yml --extra-vars="mode=$@"
help:           ## Show this help.
	@egrep '^[^ |^.]+:' $(MAKEFILE_LIST) | sed -e 's/:.*##/:\t/'
