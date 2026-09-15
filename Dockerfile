# docker build --tag bof-privilege-escalation .
# docker run --rm bof-privilege-escalation bash -c "cd /lab/exploits && bash bof.sh"
FROM archlinux:latest

# Update system and install essential development tools
RUN pacman -Syu --noconfirm base-devel gdb

# Set working directory inside container
WORKDIR /lab

# Copy source code and exploit scripts
COPY src/ /lab/src/
COPY exploits/ /lab/exploits/

# Default command opens an interactive shell in the exploits folder
WORKDIR /lab/exploits
CMD ["bash"]

