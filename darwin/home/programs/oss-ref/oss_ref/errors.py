class OssRefError(Exception):
    """An expected command failure with a stable process exit code."""

    exit_code: int = 1


class UsageError(OssRefError):
    exit_code: int = 2


class ValidationError(UsageError):
    pass
