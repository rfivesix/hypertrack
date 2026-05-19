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
5.  **Output Constancy**: The output format is restricted to a raw JSON array of objects containing exactly three fields:
    *   `name`: Simple string name of the food ingredient.
    *   `estimatedGrams`: Estimated weight of the portion in grams.
    *   `confidence`: Probability score between `0.0` and `1.0`.

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
*   **State Mismatch**: If the ingredient name specifies a different preparation state than the database entry (e.g., "raw chicken" matched to "cooked chicken"), a `state_mismatch` warning is raised.
*   **Physiological Density Guard**: If the database match features calories $> 950$ kcal per 100g or has a severe macro-to-calorie energy mismatch, a warning is raised.

---

## 4. Target-Fit Verification (Recommendation Mode)

When generating meal plans to fit specific remaining macronutrient budgets, the validation engine calculates dynamic tolerances:

*   **Calorie Budget Tolerance**: 
    $$\text{Tolerance}_{\text{kcal}} = \max\left(80\text{ kcal}, \, 20\% \text{ of target calorie budget}\right)$$
*   **Protein & Carb Budget Tolerance**: 
    $$\text{Tolerance}_{\text{macro}} = \max\left(10\text{g}, \, 25\% \text{ of target macro budget}\right)$$
*   **Fat Budget Tolerance**: 
    $$\text{Tolerance}_{\text{fat}} = \max\left(6\text{g}, \, 30\% \text{ of target fat budget}\right)$$

If any calculated food combinations miss these dynamic bounds, the target fit is classified as failed, blocking automatic acceptance.

---

## 5. The 3-Pass Self-Repair Loop

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
```

### 1. Scoring Formula
The engine computes an overall quality score starting at 100, subtracting points based on issue severity:
*   **Info Issue**: $-2$ points.
*   **Warning Issue**: $-8$ points.
*   **Error Issue**: $-24$ points.
*   **Out of Target Fit**: $-12$ points.

### 2. Validation Threshold
A candidate only passes validation if:
*   The overall score is **$\ge 70$**.
*   There are **zero critical errors** (e.g., no unmatched items, no invalid quantities).
*   If in recommendation mode, the portions **must fit within all macro tolerances**.

### 3. Repair Feedback Generation
If the candidate fails, the engine generates a structured feedback block detailing the precise index of the offending items and the error codes (e.g., `extreme_quantity`, `unmatched_item`). The orchestrator submits this log back to the LLM as a correction prompt, allowing the AI to adjust weights and terms. The loop runs for a maximum of **3 passes** before returning a final failed validation status to prevent infinite execution cycles.
