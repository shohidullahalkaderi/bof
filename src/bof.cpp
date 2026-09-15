#include <iostream>
#include <cstdio>
#include <fstream>
#include <unistd.h> // Required for setuid, setgid, execve, and geteuid

// The target function executed when control flow is hijacked
void grant_root() {
    // Attempt to set privileges to root immediately
    setuid(0);
    setgid(0);

    std::cout << "\n[+] SUCCESS: exploited! Root privileges attained.\n";
    std::ofstream outfile("BOFcompromised.txt");
    if (outfile.is_open()) {
        outfile << "Buffer Overflow exploit successful!\n";
        
        // Check and log the actual Effective User ID to verify root access
        uid_t current_euid = geteuid();
        outfile << "Effective User ID (EUID): " << current_euid << "\n";
        
        if (current_euid == 0) {
            outfile << "Privilege Status: ROOT (UID 0)\n";
            std::cout << "[+] Verification: Confirmed root access (EUID 0).\n";
        } else {
            outfile << "Privilege Status: STANDARD USER (UID " << current_euid << ")\n";
            std::cout << "[-] Verification Warning: Running as standard user (EUID " << current_euid << "). Check SUID permissions.\n";
        }

        outfile.close();
        std::cout << "[+] Action: 'BOFcompromised.txt' successfully created.\n";
    }

    // Spawn an interactive shell
    char *args[] = {(char *)"/bin/sh", NULL};
    execve(args[0], args, NULL);
}

// A normal function that should execute under normal conditions
void normal_function() {
    std::cout << "[-] Standard execution path.\n";
}

// Struct layout guarantees 'target_func' sits directly after 'buffer' in memory
struct BufferOverflowTarget {
    char buffer[32];
    void (*target_func)();
};

void vulnerable_function() {
    BufferOverflowTarget obj;
    obj.target_func = normal_function;

    // Read payload from stdin; overflowing 'buffer' directly overwrites 'target_func'
    fread(obj.buffer, 1, 40, stdin);

    obj.target_func();
}

int main() {
    vulnerable_function();
    return 0;
}