NODE_SIF_VERSION = node-16-v0.1.5
NODE_SIF_SOURCE = $(NODE_SIF_VERSION).zip
NODE_SIF_SITE = https://github.com/antmicro/github-actions-singularity-node/releases/download/$(NODE_SIF_VERSION)

ifeq ($(BR2_aarch64),y)
	NODE_SIF_VARIANT = buster-slim-arm64
else ifeq ($(BR2_x86_64),y)
	NODE_SIF_VARIANT = alpine3.14
endif

define NODE_SIF_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/node-16-$(NODE_SIF_VARIANT).sif \
		$(TARGET_DIR)/opt/sif/node.sif
endef

define NODE_SIF_EXTRACT_CMDS
	$(UNZIP) -d $(@D) $(NODE_SIF_DL_DIR)/$(NODE_SIF_SOURCE)
endef

$(eval $(generic-package))
