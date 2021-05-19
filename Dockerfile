FROM chriskypri/workhorse-r-prerequisite:stable
LABEL maintainer "Chris Kypridemos <ckyprid@liverpool.ac.uk>"
RUN git clone --branch stable https://github.com/ChristK/workHORSE.git temp
RUN cp -rvf temp/* /root/workHORSE/
RUN rm -rf temp
RUN mkdir /mnt/storage_fast/
RUN mkdir /mnt/storage_fast/synthpop/
RUN R -e 'remotes::install_local("/root/workHORSE/Rpackage/workHORSE_model_pkg/")'


EXPOSE 9898
CMD R -e 'shiny::runApp("/root/workHORSE/", port = 9898, host = "0.0.0.0", launch.browser = FALSE)'
