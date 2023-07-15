ARG ZEPHYR_CI_IMAGE_VERSION="v0.26.4"

FROM ghcr.io/zephyrproject-rtos/zephyr-build:${ZEPHYR_CI_IMAGE_VERSION}

ARG NRF_COMMAND_LINE_TOOLS_URL="https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-22-1/nrf-command-line-tools_10.22.1_amd64.deb"
ARG SEGGER_JLINK_VERSION="V788l"

USER root

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh library-scripts/*.env /tmp/library-scripts/
RUN set -x \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true"\
    && usermod --shell "$(which zsh)" "${USERNAME}" \
    && usermod -a -G dialout "${USERNAME}" \

    && apt-get install -y minicom picocom \

    ###########################################################################
    ##  start nrfjprog  #######################################################
    && apt-get install -y udev \
	&& /lib/systemd/systemd-udevd --daemon manually \

	&& wget \
            -nv  "$NRF_COMMAND_LINE_TOOLS_URL"\
            -O "/tmp/nrf-command-line-tools.deb" \
	&& ( dpkg -i "/tmp/nrf-command-line-tools.deb" || apt-get -f install -y || true) \
	&& rm "/tmp/nrf-command-line-tools.deb" \

	&& wget --post-data 'accept_license_agreement=accepted&submit=Download+software' \
			-nv "https://www.segger.com/downloads/jlink/JLink_Linux_${SEGGER_JLINK_VERSION}_x86_64.deb" \
			-O "/tmp/JLink_Linux_x86_64.deb" \
	&& ( dpkg -i "/tmp/JLink_Linux_x86_64.deb" || apt-get -f install -y || true ) \
	&& rm "/tmp/JLink_Linux_x86_64.deb" \
    ##  end nrfjprog  #########################################################
    ###########################################################################

    ###########################################################################
    ##  start TI UniFlash  ####################################################
    && wget \
            -nv https://dr-download.ti.com/software-development/software-programming-tool/MD-QeJBJLj8gq/8.3.0/uniflash_sl.8.3.0.4307.run \
            -O "/opt/uniflash_sl.8.3.0.4307.run" \
    && chmod +x "/opt/uniflash_sl.8.3.0.4307.run" \
    ## TODO: install uniflash
    ##  start TI UniFlash  ####################################################
    ###########################################################################

    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

USER "${USERNAME}"
