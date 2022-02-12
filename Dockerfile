FROM perl:5.30.3-slim-threaded-bullseye

RUN apt-get update
RUN apt-get install -y gcc openssl libssl-dev zlib1g-dev sudo perlbrew uuid-runtime

# debian don't use wheel group historial reason
# https://unix.stackexchange.com/a/4461/352321
RUN sed -i -e 's|#includedir /etc/sudoers.d|@includedir /etc/sudoers.d|g' /etc/sudoers
RUN echo "%fswiki        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/fswiki
RUN chmod 0440 /etc/sudoers.d/fswiki
RUN visudo -c

ENV FSWIKI_HOME "/app/fswiki"
RUN useradd -rm -d ${FSWIKI_HOME} -s /bin/bash fswiki
USER fswiki
WORKDIR ${FSWIKI_HOME}

# after created user, use normal user
RUN perl -v
ENV PERL_CPANM_OPT "--local-lib=${FSWIKI_HOME}/local"
ENV PATH "${FSWIKI_HOME}/local/bin:$PATH"
ENV PERL5LIB "${FSWIKI_HOME}/local/lib/perl5"

RUN cpanm --local-lib="${FSWIKI_HOME}/local" local::lib
RUN eval $(perl -I ${PERL5LIB} -Mlocal::lib)
RUN cpanm Carton --notest
COPY ./cpanfile $FSWIKI_HOME/cpanfile

RUN carton install
COPY . $FSWIKI_HOME
RUN sudo chown -R fswiki:fswiki $FSWIKI_HOME

COPY docker-entrypoint.sh /usr/bin/
RUN sudo chmod +x /usr/bin/docker-entrypoint.sh
EXPOSE 5000
ENTRYPOINT ["docker-entrypoint.sh"]
