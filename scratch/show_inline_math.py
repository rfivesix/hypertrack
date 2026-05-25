with open("/Users/richardgeorgschotte/Projekte/train-libre/documentation/features/bayesian_tdee_estimator.md", "r") as f:
    for line_num, line in enumerate(f, 1):
        if "$" in line and "$$" not in line:
            print(f"Line {line_num}: {line.strip()}")
