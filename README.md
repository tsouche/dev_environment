# Win11 development environment

This project is about delivering a versionned Dev environment to code on Win11:
- I use VS Code running on Win11 as IDE
- I deploy a Ubuntu container with Docker Desktop on Win11
- In this container, I deploy SSH and rust toolchain

I then use VS Code to access the container, thus benefitting from the best of both worlds:
- I can do my usual work on Win11, using mostly office tools
- and I dev within a Linux environment
 
## Directories

    |-----------|-------------------------|------------------|
    |           | on the laptop           | in the container |
    |-----------|-------------------------|------------------|
    | container | C:\rust-dev\container\  |                  |  
    | code      | C:\rust-dev\projects\   | /workspace/      | 
    |-----------|-------------------------|------------------|

## Create the container image

The container is defined with a dockerfile, in order to garantee version control at any moment.
- the base image is **Ubuntu 24.04**: the last LTS image 
- create a non-root user: **'rustdev'**
- define tits password: '**Hp77M&zzu$JoG1**'
- install **Rust** for this user
- install and configure a **open-ssh server** to allow rustdev to connect
- add rustdev to the **sudo group** (will give more flexibility later, in need be)
- use **/workspace** as code directory: we will pesist the data (on the laptop) via a volume

The dockerfile is located in C:\rustdev\container\

## Deploy the container using Docker Desktop

We build the image which we call **rust-ubuntu-dev** by running from within from C:\\rustdev\container\, we run: 
```docker build -t rust-ubuntu-dev .```

We then launch the container, exposing the port 2222 for SSH connexion:
```docker run -d \
      -p 2222:22 \
      -v C:/rustdev/projects:/workspace \
      --name rust-dev-container \
      rust-ubuntu-dev```

The code will be persisted located in C:\rust-dev\projects\, which is mapped into /workspace (which belongs to 'rustdev' user).

## VS code configuration

VS code must connect to the container. To do so it requires an extension: 
