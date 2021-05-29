FROM chriskypri/workhorse-r-prerequisite:HF-REAL
LABEL maintainer "Chris Kypridemos <ckyprid@liverpool.ac.uk>"
RUN git clone --branch HF-REAL https://github.com/ChristK/workHORSE.git /root/workHORSE/
RUN mkdir /mnt/storage_fast/
RUN mkdir /mnt/storage_fast/synthpop/
RUN R -e 'remotes::install_local("/root/workHORSE/Rpackage/workHORSE_model_pkg/")'
RUN Rscript /root/workHORSE/gh_deploy.R "/root/workHORSE/"

EXPOSE 9898
CMD R -e 'shiny::runApp("/root/workHORSE/", port = 9898, host = "0.0.0.0", launch.browser = FALSE)'
