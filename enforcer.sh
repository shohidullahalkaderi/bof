#!/usr/bin/env bash
#
# Arch Linux Memory Corruption Protection Enforcer (BOF & UAF Focused)
#

WRAPPER_PATH="/usr/local/bin/g++"

cat << 'EOF' > "$WRAPPER_PATH"
#!/usr/bin/env bash

# 1. Block flags used to bypass memory protections
FORBIDDEN_FLAGS=(
    "-fno-stack-protector"
    "execstack"
    "-no-pie"
    "-fno-pie"
)

for arg in "$@"; do
    for flag in "${FORBIDDEN_FLAGS[@]}"; do
        if [[ "$arg" == *"$flag"* ]]; then
            echo -e "\033[0;31m[SECURITY VIOLATION] Compilation Blocked!\033[0m" >&2
            echo -e "\033[0;33mForbidden memory protection bypass flag detected: '$flag'\033[0m" >&2
            exit 1
        fi
    done
done

# 2. Check for existing memory corruption protections
HAS_ASAN=false
HAS_FORTIFY=false
HAS_STACK_PROTECTOR=false

for arg in "$@"; do
    [[ "$arg" == *"-fsanitize=address"* ]] && HAS_ASAN=true
    [[ "$arg" == *"-D_FORTIFY_SOURCE"* ]] && HAS_FORTIFY=true
    [[ "$arg" == *"-fstack-protector"* ]] && HAS_STACK_PROTECTOR=true
done

# Build dynamic injection flags for missing memory protections
INJECTION_FLAGS=()

if [ "$HAS_ASAN" = false ]; then
    INJECTION_FLAGS+=("-fsanitize=address")
fi

if [ "$HAS_FORTIFY" = false ]; then
    INJECTION_FLAGS+=("-O2" "-D_FORTIFY_SOURCE=3")
fi

if [ "$HAS_STACK_PROTECTOR" = false ]; then
    INJECTION_FLAGS+=("-fstack-protector-strong")
fi

# Always include debug symbols (-g) for tracing memory layout
INJECTION_FLAGS+=("-g")

# Execute compilation with enforced memory corruption defenses
exec /usr/bin/g++ "${INJECTION_FLAGS[@]}" "$@"
EOF

chmod +x "$WRAPPER_PATH"
echo -e "\033[0;32m[+] Memory corruption enforcer installed (ASan, Stack Canaries, and Fortify Source active).\033[0m"