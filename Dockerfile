ARG PYTHON_VERSION=3.11
FROM python:${PYTHON_VERSION} AS ny_tree_census_base

ARG UNAME=dockeruser
ARG UID=1001
ARG GID=1001

USER root

RUN groupadd \
    --gid ${GID} \
    --non-unique \
    ${UNAME}

RUN useradd \
    --create-home \
    --gid ${GID} \
    --home /${UNAME} \
    --non-unique \
    --shell /bin/bash \
    --uid ${UID} \
    ${UNAME}

RUN curl \
-o quarto.deb \
-L https://github.com/quarto-dev/quarto-cli/releases/download/\
v1.5.55/quarto-1.5.55-linux-amd64.deb && \
dpkg -i quarto.deb && \
rm -rf quarto.deb

RUN apt update -y
RUN apt install r-base -y
RUN R -e "install.packages('shiny', repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('rmarkdown', repos='https://cran.rstudio.com/')"
RUN apt install gdebi-core -y
RUN wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
RUN gdebi shiny-server-1.5.22.1017-amd64.deb --non-interactive
RUN rm -rf shiny-server-1.5.22.1017-amd64.deb
RUN chown -R ${UNAME} /var/lib/shiny-server/

COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

USER ${UNAME}
WORKDIR /${UNAME}/penguins-dashboard

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/${UNAME}/.local/bin:/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
RUN poetry config installer.max-workers 10

COPY --chown=${UNAME} . .
RUN poetry run quarto install tinytex

RUN poetry install

RUN poetry run quarto check
RUN poetry run quarto render penguins.qmd
RUN rm penguins.qmd

CMD ["/bin/bash", "-c", "shiny-server"]
