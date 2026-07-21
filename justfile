# show available recipes
default:
    @just --list

# the playbook run against localhost
playbook := "setup.yml"

# install/refresh required Ansible collections
setup:
    ansible-galaxy collection install community.general

# lint YAML across the repo
yamllint:
    yamllint .

# lint roles and playbooks with ansible-lint
lint:
    ansible-lint

# syntax-check the main playbook
syntax:
    ansible-playbook --syntax-check {{playbook}}

# run everything CI would (mirror before pushing)
check: yamllint lint syntax

# dry-run the main playbook against localhost
dry-run:
    ansible-playbook -i localhost, --connection local --check {{playbook}}

# apply the main playbook against localhost
run:
    ansible-playbook -i localhost, --connection local {{playbook}}
