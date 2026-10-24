import sys
import os

# Determine base directory: only alter sys.path when running as script (not frozen)
if not getattr(sys, "frozen", False):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    if base_dir not in sys.path:
        sys.path.insert(0, base_dir)

from backend.server import main

if __name__ == "__main__":
    main()
