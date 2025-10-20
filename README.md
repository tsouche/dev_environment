# dev_environment

This project is about delivering a versionned Dev environment to code on Win11:
- I use VS Code running on Win11 as IDE
- I deploy a Ubuntu container with Docker Desktop on Win11
- In this container, I deploy SSH and rust toolchain

I then use VS Code to access the container, thus benefitting from the best of both worlds:
- I can do my usual work on Win11, using mostly office tools
- and I dev within a Linux environment
 


# Linux container

The linux container is defined with a dockerfile, in order to garantee version control at any moment.

- the base image is <b>Ubuntu 24.04</b>: the last LTS image 
- create a non-root user: 'rustdev'
- define tits password: 'Hp77M&zzu$JoG1'
- install Rust for this user
- configure the SSH server to allow rustdev to connect
- add rustdev to the sudo group (will give more flexibility later, in need be)
- use /home/rustdev as home directory and pesist the data via a volume on the laptop

# VS code configuration

VS code must connect to the container. To do so it requires an extension: 
