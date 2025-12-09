"""Application-wide configuration settings."""
import os
from pathlib import Path
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).parent.parent
ENV_PATH = PROJECT_ROOT / ".env"
if ENV_PATH.exists():
    load_dotenv(dotenv_path=ENV_PATH)


def _get_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.lower() in {"1", "true", "yes", "y", "on"}


class Settings:
    """Simple settings loader using environment variables."""

    DEBUG: bool = _get_bool("DEBUG", False)
    DISABLE_AUTH_FOR_DEV: bool = _get_bool("DISABLE_AUTH_FOR_DEV", False)
    DEV_AUTH_USER_ID: int = int(os.getenv("DEV_AUTH_USER_ID", "1"))


settings = Settings()
