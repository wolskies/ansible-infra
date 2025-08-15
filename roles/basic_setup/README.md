## Ansible Role: Basic Setup
Ansible role for configuring/onboarding new machine (server or workstation)

## Description
This Ansible role is meant for basic configuration of a new machine: users, packages, etc in the local environment.  It is intended to be used alongside additional roles to provide for hardening, and setup of basic services (dotfiles, shell, etc)

## Installation
To install this role, clone from this repository into the ansible roles folder.

## Usage
This role is meant to be used alongside other roles in a playbook (see `new_machine.yml` in Playbooks):

`ansible-playbook playbooks/new_machine.yml -i inventory/inventory.yaml -l aragorn --ask-become-pass --ask-vault-pass`

### To-Do's

- Sudo not available on bare-bones Debian install

- SSH keys not loaded - any tasks requiring GitLab fail (e.g. load dotfiles)

- Create playbook for starship install
    - check if starship is installed
    - download installer & run

- Fastfetch not available on Debian 12... create installer?