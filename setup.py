from setuptools import setup, find_packages

setup(
    name="omnai",
    version="1.0.0-rc3",
    description="Unified AI runner for Claude, OpenCode, Ollama, and more",
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    scripts=["omnai.sh"],
    python_requires=">=3.10",
)
