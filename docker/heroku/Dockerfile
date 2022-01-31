FROM perl:5.30.3-slim-threaded-bullseye

RUN apt-get update
RUN apt-get install -y gcc openssl libssl-dev zlib1g-dev sudo perlbrew uuid-runtime

# debian don't use wheel group historial reason
# https://unix.stackexchange.com/a/4461/352321
RUN sed -i -e 's|#includedir /etc/sudoers.d|@includedir /etc/sudoers.d|g' /etc/sudoers
RUN echo "%fswiki        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/fswiki
RUN chmod 0440 /etc/sudoers.d/fswiki
RUN visudo -c

RUN useradd -rm -d /home/fswiki -s /bin/bash fswiki
USER fswiki
WORKDIR /home/fswiki

# after created user, use normal user
RUN perl -v
ENV PERL_CPANM_OPT "--local-lib=~/perl5"
ENV PATH "/home/fswiki/perl5/bin:$PATH"
ENV PERL5LIB "/home/fswiki/perl5/lib/perl5:$PERL5LIB"
ENV FSWIKI_HOME "/home/fswiki"

RUN cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
RUN cpanm Carton --notest
COPY ./cpanfile /home/fswiki/cpanfile
RUN carton install

COPY . /home/fswiki
RUN sudo chown -R fswiki:fswiki $FSWIKI_HOME

COPY ./docker/heroku/docker-entrypoint.sh /tmp
RUN sudo chmod +x /tmp/docker-entrypoint.sh
ENTRYPOINT ["/tmp/docker-entrypoint.sh"]
