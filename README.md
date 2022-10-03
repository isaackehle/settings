# General MacOS Development Environment settings and other goodies

Everything you or I need to know about setting up a Mac

## Order of Operations

1. Open a terminal, and install [brew.sh](https://brew.sh/)
2. Install iterm from [here](./iterm.md)
3. Install zsh from [here](/zsh.md)
4. Install [Microsoft Edge Beta](https://www.microsoftedgeinsider.com/en-us/download)
5. Install [python3](./development/python.md)
6. Install docker or other virtual machines from [here](/vm.md)
7. Dev Tools

   - [aws.md](/aws.md): AWS Configurations
   - [webdev.md](/webdev.md): Typical things needed for doing web development

## MacOS Computer name

```bash
sudo scutil --set HostName MyComputerName
sudo scutil --set ComputerName MyComputerName
sudo scutil --set LocalHostName MyComputerName
```

## General Summary

- [installations.md](/installations.md): Goodies to install, and the commands to do it
- [transfer.md](/transfer.md): How to transfer to an old computer to a new
- [ruby.md](/ruby.md): Ruby installation via `rvm`
