TARGET := Pixelpulse2.flatpak
SRC := org.adi.Pixelpulse2.json

.PHONY: all clean

all: $(TARGET)

$(TARGET): repo
	flatpak build-bundle $< $@ org.adi.Pixelpulse2

repo: build
	flatpak build-export $@ $<

build: clean
	flatpak-builder --verbose $@ $(SRC)

clean:
	rm -rf $(TARGET) build repo
