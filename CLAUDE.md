# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an **Ansible Collection** (`wolskinet.infrastructure`) that provides infrastructure automation roles for multi-OS environments (Ubuntu 22+, Debian 12/13, Arch Linux, macOS).

## Prerequisites

### Philosopy/Style

The user is assumed to be a moderately experienced user. That means we can assume the user knows what they are doing and don't need multiple warnings, or erroring out if the configuration isn't supported.

Likewise, as long as our roles are clearly named, and we're using clearly named variables we don't need to add comments that repeat the obvious. Comments should be included where we may do something non-standard (like merging variables to get around ansible's variable hierarchy) or unexpected.

Finally, where there is an existing ansible module (ansible.builtin or community.general) or role by an accepted expert in ansible (like Jeff Geerling), this collection should use those roles to take advantage of the community support and updates, rather than rolling our own.

In the same light, ansible.builtin.command should be considered a last resort where a suitable module can be found -- and ansible.builtin.shell needs my explicit permission to include in a role.

### Supported Operating Systems

The role is intended to support Archlinux, MacOSX, Debian 12+, and Ubuntu 22+. That should be clear to the user in the documentation. There doesn't need to be any excessive version checking.
