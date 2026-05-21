# BYOK AI Meal Capture & Deterministic Validation Engine

Train Libre provides an advanced, on-device AI meal analysis engine that translates food descriptions or meal photos into precise, loggable items. To safeguard user data, this feature operates on a **Bring Your Own Key (BYOK)** model and verifies all outputs through a local deterministic validation pipeline.

---

## 1. Bring Your Own Key (BYOK) Security Architecture

Train Libre does not deploy intermediate servers to handle AI requests. All calls are dispatched directly from the user's mobile device to the selected AI provider.

### Encrypted Key Storage
User-configured API keys are stored directly inside native system secure vaults (iOS Keychain and Android Keystore) via `FlutterSecureStorage`:
*   `ai_api_key_openai`: Secure key for OpenAI.
*   `ai_api_key_gemini`: Secure key for Google Gemini.
*   `ai_api_key_anthropic`: Secure key for Anthropic Claude.
*   `ai_api_key_mistral`: Secure key for Mistral.
*   `ai_api_key_xai`: Secure key for xAI Grok.

The active selected provider and the selected model are similarly saved in secure local settings, isolating all credentials from external developers.

---

## 2. System Prompt & LLM Boundaries

To maintain data integrity and prevent AI hallucination of nutritional values, the system prompt strictly restricts the AI's responsibilities:

1.  **Macro/Calorie Ban**: The AI is strictly prohibited from estimating, guessing, or returning any nutritional numbers (calories, protein, carbs, fat). Nutritional calculations are resolved deterministically by Train Libre using its local database.
2.  **Decomposition Rule**: The AI must break down every composite meal into its basic, atomic components. For example, "Spaghetti Bolognese" must be decomposed into: *spaghetti, beef mince, tomatoes, onions, garlic, olive oil, parmesan cheese*.
3.  **Short Base Names**: Ingredient names must be returned in their simplest, generic forms (e.g., "Apfel" instead of "Grüner Apfel", "Ei" instead of "Großes gekochtes Ei") to maximize local database match rates.
4.  **Consolidation**: Duplicate items must be consolidated before returning (e.g., if the user describes eating 3 eggs, the AI must return a single entry for "Egg" with a combined weight).
5.  **Holistic Context Anchor (`mealContext`)**: The system requests and structures a `mealContext` block, establishing a culinary baseline for validation:
    *   `expectedKcalRange`: Estimated total calorie boundaries (min/max).
    *   `cookingState`: Expected preparation state of ingredients (e.g., raw, cooked, grilled).
    *   `expectedMacroProfile`: Expected macronutrient percentage balances (Protein, Carbs, Fat).
6.  **Output Constancy**: The output format is restricted to a structured JSON object containing:
    *   `meal_name`: Name of the overall meal.
    *   `description`: Descriptive overview of the meal.
    *   `items`: A list of food ingredients with name, estimated grams, confidence, and state hints.
    *   `mealContext`: The holistic culinary anchors used for cross-checks.

---

## 3. Deterministic Validation Engine

Once the AI returns its JSON list, the raw suggestions are processed by the local `AiMealValidationEngine`. This engine applies a series of rigid checks:

### Merge Heuristics & Normalization
Before evaluating database matches, the engine normalizes all text tokens and checks for duplicates. If duplicate ingredients are detected, they are automatically merged: the weights are summed, and the maximum confidence is retained.

### Database Matching & Quality Classification
The engine matches ingredients against the local SQLite database using fuzzy string matching and barcodes:
*   **Exact Match (Score $\ge 0.95$)**: Perfect textual alignment or matching barcode.
*   **Strong Match (Score $\ge 0.78$)**: Excellent alignment (e.g., token overlaps).
*   **Partial Match (Score $\ge 0.55$)**: Moderate overlap (triggers an information warning).
*   **Weak Match (Score $\ge 0.35$)**: Weak overlap (triggers a warning or error based on the application mode).
*   **Unmatched (Score $< 0.35$)**: Results in an `unmatched_item` error. The item must be manually matched before saving.

### Validation Rules & Plausibility Checks
The engine raises warnings or errors if the suggested portions violate physiological plausibility:
*   **Grams $\le 0$**: Triggers a critical `invalid_quantity` error.
*   **Grams $> 3000$g**: Triggers a critical `extreme_quantity` error.
*   **Grams $\le 5$g**: Triggers a `tiny_quantity` warning.
*   **Grams $> 1200$g**: Triggers a `large_quantity` warning.
*   **Confidence $< 0.5$**: Triggers a `low_ai_confidence` warning.

---

## 4. Multi-Dimensional Cross-Check Validation Rules

To prevent erroneous database matching and portion estimation, Train Libre implements four strict multi-dimensional cross-check rules connecting matched database entities with the holistic culinary anchors:

### C1: expected Kcal Range Check
Verifies whether the sum of the calories of all matched database ingredients is within the expected total meal calorie range from the culinary anchor:
*   **Warning (`anchor_kcal_deviation`)**: Raised if the total matched calories deviate by $>25\%$ from the nearest boundary of the expected range.
*   **Error (`anchor_kcal_extreme`)**: Raised if the total matched calories deviate by $>50\%$ from the nearest boundary, escalating to a hard validation failure.

### C2: Expected Macro Profile Check
Compares the matched database macronutrient distribution against the expected macro percentage profile in the culinary anchor:
*   **Warning (`anchor_macro_profile_deviation`)**: Raised if the actual protein, carbs, or fat percentage deviates by $>15\%$ from the anchor profile.

### C3: Cooking State Mismatch Check
Detects preparation state discrepancies between the AI's parsed item and the matched database entry (e.g., a "raw chicken breast" matched to "cooked chicken breast"):
*   **Warning (`state_mismatch`)**: Raised when a text state hint mismatch is detected.
*   **Error (`state_mismatch_extreme`)**: Escalates to a critical validation error if the caloric density delta between the matched raw item and its correct state variant exceeds $30\%$, indicating a serious portion-logging discrepancy.

### C4: Portion Density Anomaly Detection
Checks for implausible ingredient quantities based on standard portion densities:
*   **Warning (`implausible_portion_density`)**: Raised if the matched database product density deviates significantly, meaning the effective portion density is $>2\times$ or $<0.5\times$ of the default database product density, indicating potential gram calculation anomalies.

---

## 5. The "Top-N Fuzzy Alternatives" Candidate Selection System

When a validation issue or match anomaly occurs, Train Libre does not let the LLM blindly guess replacements. Instead, the local Dart engine uses a **Candidate Selection** model:

1.  **Local Database Querying**: The `ProductLocalDataSource` queries the SQLite database via `fuzzyMatchCandidatesForRepair`, pulling the top 5 to 10 closest fuzzy matches using Jaro-Winkler string similarity.
2.  **State-Aware Re-ranking**: Candidates are re-ranked based on preparation state matches (e.g., prioritising cooked or grilled items if a cooking hint is present).
3.  **Prompt Menu Injection**: These database candidates (including their exact database names, calories, and macronutrient distributions) are structured as a selection menu and injected directly into the repair prompt payload under a `CANDIDATES` block.
4.  **Semantic Selection**: The LLM acts as a semantic selector rather than an estimator, choosing the mathematically and culinary-wise best-fitting database candidate.

---

## 6. The 3-Pass Self-Repair Loop

To recover from invalid JSON formats, incorrect ingredient portions, or missing database matches, Train Libre runs a closed feedback loop managed by `AiRepairOrchestrator`:

```
               [LLM Candidate Output]
                         |
                         v
             [AiMealValidationEngine]
                         |
           Is Score >= 70 & No Errors?
             /                       \
          (Yes)                      (No)
           /                           \
[Pass Validation]            [Format Feedback Log]
                                        |
                            Has Loop Run < 3 Times?
                              /                 \
                           (Yes)                (No)
                            /                     \
                   [Re-request LLM]       [Fail Validation]
               (Injects Top-N Candidates &
                Holistic mealContext Anchor)
```

### 1. Scoring Formula
The engine computes an overall quality score starting at 100, subtracting points based on issue severity:
*   **Info Issue**: $-2$ points.
*   **Warning Issue**: $-8$ points.
*   **Error Issue**: $-24$ points.

### 2. Validation Threshold
A candidate only passes validation if:
*   The overall score is **$\ge 70$**.
*   There are **zero critical errors** (e.g., no unmatched items, no extreme kcal deviations, no invalid quantities).

### 3. Repair Feedback Generation
If the candidate fails, the engine generates a structured feedback block detailing the precise index of the offending items and the error codes (e.g., `state_mismatch`, `anchor_kcal_extreme`). The orchestrator submits this log alongside the list of verified **Top-N Database Candidates** and the **`mealContext`** back to the LLM. The loop runs for a maximum of **3 passes** before returning a final failed validation status.
