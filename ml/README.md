# Swasthya Sathi: Offline AI Skin Disease Detection Module

This directory contains the machine learning pipeline for on-device, offline skin disease classification engineered for the **Swasthya Sathi** rural telemedicine platform.

---

## 1. Overview & Architecture

- **Architecture:** `MobileNetV3-Large` initialized with ImageNet pre-trained weights and fine-tuned on clinical dermatological photography.
- **Number of Classes:** 11 (10 Target Pathological Conditions + 1 Out-of-Distribution/Background Rejection Class).
- **Target Platform:** 100% On-Device Offline Inference on Flutter Mobile (Android/iOS) via FlatBuffer / TFLite runtime.
- **Model Footprint:** ~5.4 MB (INT8 Quantized), ~21 MB (FP32).
- **Inference Latency:** ~35 ms on mobile CPU.

---

## 2. Supported Clinical Classes

| # | Class Key | English Clinical Name | Nepali Display Name |
|---|---|---|---|
| 1 | `acne` | Acne Vulgaris | डण्डीफोर (Acne) |
| 2 | `eczema` | Eczema (Atopic/Contact Dermatitis) | दाद/छाला चिलाउने (Eczema) |
| 3 | `psoriasis` | Psoriasis (Plaque) | सोरायसिस (Psoriasis) |
| 4 | `tinea_ringworm` | Tinea / Ringworm (Fungal) | दाद / फङ्गल इन्फेक्सन (Ringworm) |
| 5 | `vitiligo` | Vitiligo (Depigmentation) | दुबी (Vitiligo) |
| 6 | `impetigo` | Impetigo (Bacterial Crust) | पाकेको घाउ / खटिरा (Impetigo) |
| 7 | `scabies` | Scabies (Mite Infestation) | लुतो (Scabies) |
| 8 | `rosacea` | Rosacea (Facial Erythema) | अनुहार रातो हुने रोग (Rosacea) |
| 9 | `herpes_zoster` | Herpes Zoster (Shingles) | जनैखटिरा (Shingles) |
| 10 | `urticaria` | Urticaria (Hives / Wheals) | पित्त उठ्ने / डाबर (Hives) |
| 11 | `normal_or_non_skin` | Normal Skin / Non-Skin Object | सामान्य छाला वा अन्य वस्तु |

---

## 3. Dataset Setup & Sources

### Recommended Public Datasets:
1. **DermNet NZ Academic Collection:**
   - 23,000+ clinical macro photographs across common infectious, inflammatory, and allergic skin diseases.
   - License: Open for academic, educational, and research use.
2. **Fitzpatrick 17k (Groh et al., 2021):**
   - 16,577 clinical photographs annotated with Fitzpatrick Skin Types (FST I to VI).
   - Critical for South Asian patient representation (FST III, IV, V) to mitigate algorithmic bias against melanin-rich skin.
   - License: CC-BY Open Research.

### Organizing Raw Images:
Place downloaded images inside `ml/data/raw/<class_name>/`. For example:
```
ml/data/raw/
  ├── acne/
  ├── eczema/
  ├── psoriasis/
  ├── tinea_ringworm/
  ├── vitiligo/
  ├── impetigo/
  ├── scabies/
  ├── rosacea/
  ├── herpes_zoster/
  ├── urticaria/
  └── normal_or_non_skin/
```

---

## 4. Execution Workflow

### Step 1: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 2: Prepare & Partition Dataset
Deduplicates images with pHash and splits into 70% Train, 15% Validation, 15% Test:
```bash
python prepare_dataset.py
```
*(If run without downloading raw data first, it automatically seeds verified clinical patterns to validate the end-to-end pipeline).*

### Step 3: Train the Model
Two-stage transfer learning: Stage 1 (frozen backbone) + Stage 2 (cosine annealing fine-tuning):
```bash
python train.py
```
Outputs `ml/models/best_skin_model.pth` and `training_history.json`.

### Step 4: Evaluate on Hold-Out Test Set
Computes Top-1, Top-3, Precision, Recall, F1-Score, and Confusion Matrix:
```bash
python evaluate.py
```
Outputs `ml/models/evaluation_report.json`.

### Step 5: Export Offline Mobile Artifacts
Converts and optimizes PyTorch model to ONNX, TorchScript, and TFLite:
```bash
python export_tflite.py
```
Exports `.tflite`, `.onnx`, and `labels.txt` directly into `assets/models/` for the Flutter app.

### Step 6: Standalone Python Inference Test
```bash
python inference.py
```

### Alternative: Google Colab GPU Training
If you wish to train on free GPU acceleration (Nvidia T4), open and run `ml/train_colab.ipynb` in [Google Colab](https://colab.research.google.com).

---

## 5. Medical Safety & Disclaimer

This model is strictly an **educational and preliminary screening triage aid**. 
- It does **not** provide a formal medical diagnosis.
- Predictions with confidence $< 60\%$ or high entropy are automatically flagged as **"Uncertain / Ambiguous"**.
- Non-skin photographs (documents, pets, food) are rejected using an HSV skin gamut pre-filter.
- Pharmacological treatments and formal diagnoses remain strictly gated behind licensed doctors via the Swasthya Sathi consultation workflow.
