# ------------------------------------------------------------
# ΠΑΡΑΜΕΤΡΟΙ ΧΡΗΣΤΗ
# ------------------------------------------------------------
FILTER ?= sharpen          # όνομα φακέλου kernel χωρίς ".hex"
IMAGE  ?= cameraman.png    # είσοδος εικόνας

# ------------------------------------------------------------
# Αρχεία πηγής
# ------------------------------------------------------------
RTL   = convolution.v
TB    = convolution_tb.v

# ------------------------------------------------------------
# Ονόματα που παράγονται
# ------------------------------------------------------------
SIM   = simv             # εκτελέσιμο Icarus
KDIR  = kernels

# -- Clear το FILTER από κρυφά CR / TAB / κενά ------------
CR    := $(shell printf '\r')
space :=
space +=
FILT  := $(firstword $(subst $(space), ,$(subst $(CR), ,$(strip $(FILTER)))))

KHEX  := $(KDIR)/$(FILT).hex
SHEX  := $(KDIR)/shift_$(FILT).hex

# ------------------------------------------------------------
.PHONY: all sim img clean
all: clean img                       # πλήρης ροή

# ------------------------------------------------------------
# 1.  εικόνα -> input.hex
# ------------------------------------------------------------
input.hex: $(IMAGE)
	python3 img_to_hex.py $< $@

# ------------------------------------------------------------
# 2.  simulation (compile + run)  --> output.hex
#     * ΚΑΘΕ ΦΟΡΑ* ξαναμεταγλωττίζει με -DFILTER_NAME="..."
# ------------------------------------------------------------
sim: input.hex $(KHEX) $(SHEX) $(RTL) $(TB)
	@echo "###  Kernel   : $(KHEX)"
	@echo "###  Shift    : $(SHEX)"
	iverilog -g2012 -DFILTER_NAME=\"$(FILT)\" -o $(SIM) $(RTL) $(TB)
	cp $(KHEX)  kernel.hex
	cp $(SHEX)  shift.hex
	vvp $(SIM)

# ------------------------------------------------------------
# 3.  output.hex -> output.png
# ------------------------------------------------------------
img: sim
	python3 hex_to_img.py output.hex output.png
	@echo "✓ output.png έτοιμο (filter=$(FILT))"

# ------------------------------------------------------------
# 4.  clean
# ------------------------------------------------------------
clean:
	rm -f $(SIM) *.hex kernel.hex shift.hex output.png sim.vcd
