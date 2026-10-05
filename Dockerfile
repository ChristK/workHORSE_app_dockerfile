# The prerequisite (R 4.2.1, packages frozen on 2022-08-01), pinned by digest so
# that re-pushing its latest tag cannot change this image. After rebuilding the
# prerequisite on purpose, put the digest that docker push prints here.
FROM chriskypri/workhorse-r-prerequisite:latest@sha256:82ac770f11cc5266c9826434642dcca55e170e61552d2f8e9cd4f0ed270e725b
LABEL maintainer="Chris Kypridemos <ckyprid@liverpool.ac.uk>"

# R ignores SIGTERM when it runs as PID 1, so docker stop would wait 10 s and
# then kill it. It exits cleanly on SIGINT.
STOPSIGNAL SIGINT

# workHORSE commit to build (default: master). Passing the SHA records it in the
# image and makes Docker rebuild from here when master has moved, e.g.
#   --build-arg WORKHORSE_SHA=$(git ls-remote https://github.com/ChristK/workHORSE.git refs/heads/master | cut -f1)
ARG WORKHORSE_SHA=master
LABEL workhorse.commit=$WORKHORSE_SHA
RUN git clone https://github.com/ChristK/workHORSE.git /root/workHORSE/ \
 && git -C /root/workHORSE checkout --detach "$WORKHORSE_SHA"
RUN mkdir -p /mnt/storage_fast/synthpop/

# Keep the prerequisite's package versions: R CMD INSTALL installs no
# dependencies (they are all in the prerequisite), and any later
# install.packages() uses the same 2022-08-01 snapshot instead of today's CRAN.
ENV CRAN=https://packagemanager.rstudio.com/all/__linux__/focal/2022-08-01+Y3JhbiwyOjQ1MjYyMTU7RTY0MEEyRTM
RUN echo "options(repos = c(CRAN = '$CRAN'))" >> /usr/local/lib/R/etc/Rprofile.site \
 && R CMD INSTALL --clean /root/workHORSE/Rpackage/workHORSE_model_pkg/

# Large data files from the workHORSE GitHub release, checked against
# gh_deploy_files.csv. The build fails if any file is missing or corrupt, or if
# the commit is older than these checks (its gh_deploy.R could save error
# messages as data).
RUN test -f /root/workHORSE/gh_deploy_files.csv \
 || { echo "workHORSE $WORKHORSE_SHA has no gh_deploy_files.csv: build a commit from 2026-10-05 or later"; exit 1; } \
 && Rscript /root/workHORSE/gh_deploy.R /root/workHORSE

EXPOSE 9898
CMD ["R", "-e", "shiny::runApp('/root/workHORSE/', port = 9898, host = '0.0.0.0', launch.browser = FALSE)"]
