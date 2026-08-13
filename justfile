# show available recipes
default:
    @just --list

# the playbook run against localhost
playbook := "setup_workstation.yml"

# install/refresh required Ansible collections
setup:
    ansible-galaxy collection install -r requirements.yml

# lint roles and playbooks (yamllint runs embedded via the yaml rule)
lint:
    ansible-lint --profile production

# syntax-check the main playbook
syntax:
    ansible-playbook --syntax-check {{playbook}}

# run everything CI would (mirror before pushing)
check: lint syntax

# dry-run the main playbook against localhost
dry-run:
    ansible-playbook -i localhost, --connection local --check {{playbook}}

# apply the main playbook against localhost
run:
    ansible-playbook -i localhost, --connection local {{playbook}}

# prove idempotency: a second run must report changed=0
verify: run
    ansible-playbook -i localhost, --connection local {{playbook}} \
        | tee /dev/stderr | grep -qE 'changed=0.*failed=0' \
        || { echo "not idempotent — see the changed tasks above"; exit 1; }
