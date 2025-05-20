# Ansible minor mode

This is a fork of https://gitlab.com/emacs-ansible/emacs-ansible - though forked from the old Github repository, with the latest Gitlab changes pulled. Reason for this is that Gitlab now makes me jump through Clownflare just to log in, and I can't be bothered with that.

As my changes are rather invasive I'd not expect upstream to be interested in merging that anyway.

## Requirement

- yasnippet
- auto-complete

## Installation

If you prefer this variant over upstream, just clone it, and add it to your load path.

## Usage

### Enable minor mode

    M-x ansible-mode

or hook

    (add-hook 'yaml-mode-hook '(lambda () (ansible-mode 1)))

### Snippets for yasnippet

- Ansible module snippet

### Dictionary for auto-complete

- Ansible module key dictionary

### Ansible Vault support

Set up a password in `ansible-vault-password-file`: (default value:
"~/.vault_pass")

    (setq ansible-vault-password-file "path/to/pwd/file")

Bind keys:

    (global-set-key (kbd "C-c b") 'ansible-decrypt-buffer)
    (global-set-key (kbd "C-c g") 'ansible-encrypt-buffer)

You can also set automatic {en,de}cryption by adding
`ansible-auto-decrypt-encrypt` to `ansible-hook`:

    (add-hook 'ansible-hook 'ansible-auto-decrypt-encrypt)
