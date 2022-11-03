FROM codercom/enterprise-base:ubuntu

USER root

RUN apt update -y && apt upgrade -y
RUN apt install -y curl wget git vim software-properties-common

# Install Go
RUN curl -L https://gist.githubusercontent.com/zekroTJA/87d560e04c68703efe384bd273c3901c/raw/836cf9b4b1f52cfd83ed222daa09412c1bcf4d6a/golang-download-latest.sh | bash -
ENV GOROOT /usr/local/go
ENV PATH $PATH:$GOROOT/bin
ENV GOPATH /home/coder/go
ENV GOBIN $GOPATH/bin
ENV PATH $PATH:$GOBIN

# Install Nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
&& apt install -y nodejs

# Install dotnet
RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& rm packages-microsoft-prod.deb \
&& apt-get update \
&& apt-get install -y dotnet-sdk-6.0

USER coder

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
&& source "$HOME/.cargo/env" || true

# Install Python
RUN sudo add-apt-repository -y ppa:deadsnakes/ppa \
&& sudo apt -y update \
&& sudo apt install python3.11 -y

RUN echo 'export PATH=$PATH:$GOROOT/bin' >> ~/.profile

# Install ZSH and Oh-my-ZSH
RUN curl -fsSL https://gist.githubusercontent.com/feluxerich/010e7f84681b64b9bf7168b2c85cdcfe/raw/zsh.sh | sh -
