import os

def show_inline_math_other():
    features_dir = "/Users/richardgeorgschotte/Projekte/train-libre/documentation/features"
    for filename in ["byok_ai_validation.md", "muscle_recovery_model.md"]:
        filepath = os.path.join(features_dir, filename)
        with open(filepath, "r") as f:
            for line_num, line in enumerate(f, 1):
                if "$" in line and "$$" not in line:
                    print(f"{filename}:{line_num}: {line.strip()}")

if __name__ == "__main__":
    show_inline_math_other()
