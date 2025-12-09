import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Add backend to sys.path
backend_path = Path(__file__).parent
sys.path.append(str(backend_path))

# Load .env
load_dotenv(backend_path / ".env")

print(f"Python version: {sys.version}")
try:
    import openai
    print(f"openai version: {openai.__version__}")
    import httpx
    print(f"httpx version: {httpx.__version__}")
except ImportError as e:
    print(f"Import Error: {e}")

api_key = os.getenv("OPENAI_API_KEY")
print(f"API Key present: {bool(api_key)}")

if api_key:
    print(f"API Key length: {len(api_key)}")
    print(f"API Key prefix: {api_key[:7]}...")

try:
    from openai import OpenAI
    client = OpenAI(api_key=api_key)
    print("Client initialized successfully")
except Exception as e:
    print(f"Client init failed: {e}")
    import traceback
    traceback.print_exc()
