Name: Overdrive-AMC
Description

Overdrive-AMC is a robust, interactive Bash management layer for automated media processing. Designed specifically for headless NAS environments running qBittorrent and FileBot, it bridges the gap between raw container logic and manual oversight.

The script provides a unified control panel to:

    Monitor Real-Time Storage: Dynamically inspects Docker mount points to provide per-disk capacity and free space reporting directly in the terminal.

    Automate Configuration: Features an "Auto-Inject" system that locates and modifies docker-compose files to link the host script and environment variables into the container runtime.

    Execute AMC Logic: Simplifies complex FileBot "Automated Media Center" (AMC) commands with dedicated modes for standard moves, dry runs (simulation), and "forced" processing that bypasses exclusion logs.

    Self-Healing Maintenance: Includes built-in routines to verify system dependencies, perform Debian-based package upgrades, and scrub junk files from temporary directories.

    Secure Redundancy: Integrates Gmail/SMTP notifications and PGP-backed configuration backups to ensure your environment variables and automation strings are never lost.

# overdrive-amc
A high-performance Bash interface for headless NAS media automation. It bridges Docker, qBittorrent, and FileBot with real-time storage tracking, auto-injecting AMC logic into Compose files, and PGP-backed cloud backups. Features deep system maintenance, dependency self-healing, and dry-run simulations. Optimized for speed and UI clarity.
