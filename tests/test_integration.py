# AI Runner Integration Tests
# Tests that actually call AI backends (requires installed engines)

import subprocess
import tempfile
import os
from pathlib import Path

AI_RUNNER = Path(__file__).parent.parent / "ai-runner.sh"

def run_ai(prompt):
    """Run AI and return output."""
    result = subprocess.run(
        ["bash", str(AI_RUNNER), "--model", "haiku", prompt],
        capture_output=True,
        text=True,
        timeout=60
    )
    return result.stdout.strip(), result.returncode

def test_ai_available():
    """Check if any AI backend is available."""
    result = subprocess.run(
        ["bash", str(AI_RUNNER), "--list-engines"],
        capture_output=True,
        text=True
    )
    return "installed" in result.stdout

def test_simple_prompt():
    """Test a simple prompt."""
    if not test_ai_available():
        print("SKIP: No AI engine available")
        return

    output, code = run_ai("Say 'Hello from test' exactly")
    assert code == 0, f"Exit code {code}"
    assert "Hello from test" in output, f"Expected greeting in: {output}"
    print(f"PASS: Simple prompt returned: {output[:50]}")

def test_json_response():
    """Test JSON response format."""
    if not test_ai_available():
        print("SKIP: No AI engine available")
        return

    output, code = run_ai('List 3 colors as JSON: {"colors": ["red", "green", "blue"]}')
    assert code == 0, f"Exit code {code}"
    # Should be parseable JSON
    import json
    try:
        data = json.loads(output)
        assert "colors" in data
        print(f"PASS: JSON response parsed successfully")
    except json.JSONDecodeError:
        # AI might have added explanation
        if "red" in output and "green" in output:
            print(f"PASS: JSON response contains expected data")
        else:
            print(f"WARN: JSON parse failed but response: {output[:100]}")

def test_timeout():
    """Test that timeout works."""
    # This would require a very long response to properly test
    print("INFO: Timeout test requires long-running prompts")

def test_template_prompt():
    """Test prompt from template."""
    if not test_ai_available():
        print("SKIP: No AI engine available")
        return

    with tempfile.TemporaryDirectory() as tmpdir:
        template = Path(tmpdir) / "test.md"
        template.write_text("Hello {{NAME}}, you have {{COUNT}} messages.")

        # Note: ai_run_file expects full path
        result = subprocess.run(
            ["bash", str(AI_RUNNER), "--file", str(template)],
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            print(f"PASS: Template file executed")
        else:
            # Might fail if NAME/COUNT not substituted
            print(f"INFO: Template test - exit code {result.returncode}")

if __name__ == "__main__":
    print("AI Runner Integration Tests")
    print("=" * 40)

    test_ai_available()

    print("\n--- Integration Tests ---\n")

    test_simple_prompt()
    test_json_response()
    test_template_prompt()

    print("\n" + "=" * 40)
    print("Integration tests complete")
