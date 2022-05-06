UTILITY_SIF_VERSION = v0.1.2
UTILITY_SIF_SOURCE = gha-utility-container-$(UTILITY_SIF_VERSION).zip
UTILITY_SIF_SITE = https://github.com/antmicro/github-actions-singularity-utility-container/releases/download/$(UTILITY_SIF_VERSION)

define UTILITY_SIF_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/image.sif \
		$(TARGET_DIR)/opt/sif/utility.sif
endef

define UTILITY_SIF_EXTRACT_CMDS
	$(UNZIP) -d $(@D) $(UTILITY_SIF_DL_DIR)/$(UTILITY_SIF_SOURCE)
endef

$(eval $(generic-package))
