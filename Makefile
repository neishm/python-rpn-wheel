# For compiling librmn

LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.1.10


.PHONY: all packages

packages: librmn vgrid python-rpn env-include env-code-tools code-tools r.gppf dot-tools

librmn:
	git clone https://github.com/armnlib/librmn.git

vgrid:
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git

python-rpn:
	git clone https://github.com/meteokid/python-rpn.git

env-include:
	git clone joule:/home/dormrb02/GIT-depots/env-include.git

env-code-tools:
	svn export svn://mrbsvn/env/env-code-tools@106

code-tools:
	git clone /home/ib/asph/lib/projects/code-tools/git code-tools

r.gppf:
	git clone /users/dor/asph/lib/projects-moved/r.gppf/git r.gppf

dot-tools:
	git clone /users/dor/asph/lib/projects/dot-tools/git dot-tools

test: librmn env-code-tools code-tools r.gppf
	(cd librmn/template_utils/gmm; env RPN_TEMPLATE_LIBS=$(PWD) PATH=$(PATH):$(PWD)/env-code-tools/bin:$(PWD)/code-tools/static/bin:$(PWD)/r.gppf/bin:$(PWD)/dot-tools/bin make locallib)
