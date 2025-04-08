AR = nasm
LD = ld

# List all .asm files in the current directory
ASM_SOURCES = $(wildcard *.asm)

# Create corresponding object files for each .asm file
ASM_OBJECTS = $(ASM_SOURCES:.asm=.o)

# Default target to build the executable
all: termo

# Build the final executable
termo: $(ASM_OBJECTS)
	$(LD) -s -o termo $(ASM_OBJECTS)

# Compile all .asm files to .o files
%.o: %.asm
	$(AR) -f elf64 -o $@ $<

# Clean up object files and the executable
clean:
	rm -f $(ASM_OBJECTS) termo

.PHONY: all clean
