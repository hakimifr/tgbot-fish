FROM alpine:latest

# Install packages
RUN apk add --no-cache python3-dev jq aria2 pv openssl neofetch curl-dev glib-dev openssl-dev ffmpeg python3 curl bash which zip git nano fortune file
RUN apk add --no-cache --virtual=build-dependencies make g++ wget asciidoc
RUN apk add --update coreutils && rm -rf /var/cache/apk/*

# YTDL
RUN wget -c https://yt-dl.org/downloads/latest/youtube-dl -O /usr/local/bin/youtube-dl && \
    chmod +x /usr/local/bin/youtube-dl

# TMATE
RUN wget -c https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-amd64.tar.xz && \
    tar -xvf tmate-2.4.0-static-linux-amd64.tar.xz && \
    mv tmate-2.4.0-static-linux-amd64/tmate /usr/local/bin/ && \
    chmod +x /usr/local/bin/tmate

# MEGADL
RUN wget https://megatools.megous.com/builds/megatools-1.10.3.tar.gz && \
    tar zxf megatools-1.10.3.tar.gz && \
    cd megatools-1.10.3 && \
    ./configure && \
    make && \
    make install

# Python
RUN python3 -m ensurepip \
    && pip3 install --upgrade pip setuptools \
    && pip3 install wheel telethon \
    && rm -r /usr/lib/python*/ensurepip && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache

# PIP
RUN pip3 install speedtest-cli pycryptodome docopt
RUN pip3 install git+https://github.com/nlscc/samloader.git
RUN pip3 install --upgrade pycryptodome git+https://github.com/R0rt1z2/realme-ota
WORKDIR /app
RUN chmod 777 /app

# Copy all files to workdir
COPY . .
CMD ["bash","start.sh"]
