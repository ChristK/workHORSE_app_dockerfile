FROM chriskypri/workhorse-r-prerequisite

RUN git clone https://github.com/ChristK/workHORSE.git temp
RUN cp -rvf temp/* /root/workHORSE/
RUN rm -rf temp

# following already exists on pworkhorse-r-prerequisite
# RUN cd workHORSE
# RUN wget -c https://filedn.com/lj14yWNHbMFXQ0F4Fkti6a8/workHORSE_data_files.tar -O - | tar -x
# RUN rm DELETEms*

COPY Rprofile.site /usr/lib/R/etc/

RUN mkdir /mnt/storage_fast/
RUN mkdir /mnt/storage_fast/synthpop/

RUN R -e 'remotes::install_local("/root/workHORSE/Rpackage/workHORSE_model_pkg/", force = TRUE)'

EXPOSE 9898

CMD ["R", "-e", "chooseCRANmirror(ind=1); \
                 shiny::runApp('/root/workHORSE', port = 9898) "]
