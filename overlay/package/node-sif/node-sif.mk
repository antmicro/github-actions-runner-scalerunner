NODE_SIF_VERSION = node-16-buster
NODE_SIF_SOURCE = image.tar.gz
NODE_SIF_SITE = https://github.com/antmicro/github-actions-singularity-node/releases/download/$(NODE_SIF_VERSION)

define NODE_SIF_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/image.sif \
		$(TARGET_DIR)/opt/sif/node.sif
endef

$(eval $(generic-package))
