import os
import glob
import json
import torch
import numpy as np
from torch.utils.data import DataLoader
from sklearn.metrics import (
    accuracy_score, precision_recall_fscore_support,
    confusion_matrix, classification_report
)
from dataset import (
    CLASSES, CLASS_TO_IDX, IDX_TO_CLASS,
    CLASS_DISPLAY_NAMES, get_transforms, SkinDiseaseDataset
)
from model import build_model

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, 'data', 'processed')
MODELS_DIR = os.path.join(BASE_DIR, 'models')

def evaluate_test_set():
    model_path = os.path.join(MODELS_DIR, 'best_skin_model.pth')
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model checkpoint not found at {model_path}. Train the model first.")

    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    # Load test data
    test_paths = []
    test_labels = []
    test_dir = os.path.join(DATA_DIR, 'test')
    for cls_name in CLASSES:
        cls_dir = os.path.join(test_dir, cls_name)
        if not os.path.exists(cls_dir):
            continue
        for file in glob.glob(os.path.join(cls_dir, '*.*')):
            if file.lower().endswith(('.jpg', '.jpeg', '.png')):
                test_paths.append(file)
                test_labels.append(CLASS_TO_IDX[cls_name])

    if len(test_paths) == 0:
        raise RuntimeError("No test images found in data/processed/test.")

    print(f"Evaluating {len(test_paths)} test images across {len(CLASSES)} classes...")

    test_dataset = SkinDiseaseDataset(test_paths, test_labels, transform=get_transforms(is_training=False))
    test_loader = DataLoader(test_dataset, batch_size=16, shuffle=False)

    # Load model
    model = build_model(num_classes=len(CLASSES), pretrained=False)
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.to(device)
    model.eval()

    all_preds = []
    all_targets = []
    all_probs = []

    with torch.no_grad():
        for images, labels in test_loader:
            images = images.to(device)
            outputs = model(images)
            probs = torch.softmax(outputs, dim=1)

            _, preds = torch.max(probs, 1)

            all_preds.extend(preds.cpu().numpy())
            all_targets.extend(labels.numpy())
            all_probs.extend(probs.cpu().numpy())

    all_preds = np.array(all_preds)
    all_targets = np.array(all_targets)
    all_probs = np.array(all_probs)

    # Top-1 and Top-3 accuracy
    top1_acc = accuracy_score(all_targets, all_preds) * 100.0

    # Top-3 accuracy calculation
    top3_correct = 0
    for i in range(len(all_targets)):
        top3_indices = np.argsort(all_probs[i])[-3:]
        if all_targets[i] in top3_indices:
            top3_correct += 1
    top3_acc = (top3_correct / len(all_targets)) * 100.0

    # Macro & Weighted metrics
    p_macro, r_macro, f1_macro, _ = precision_recall_fscore_support(all_targets, all_preds, average='macro', zero_division=0)
    p_weight, r_weight, f1_weight, _ = precision_recall_fscore_support(all_targets, all_preds, average='weighted', zero_division=0)

    # Per-class metrics
    p_class, r_class, f1_class, support_class = precision_recall_fscore_support(
        all_targets, all_preds, labels=range(len(CLASSES)), zero_division=0
    )

    cm = confusion_matrix(all_targets, all_preds, labels=range(len(CLASSES)))

    print("\n" + "="*70)
    print("AI SKIN DISEASE MODEL EVALUATION REPORT")
    print("="*70)
    print(f"Overall Top-1 Accuracy: {top1_acc:.2f}%")
    print(f"Overall Top-3 Accuracy: {top3_acc:.2f}%")
    print(f"Macro F1-Score:        {f1_macro * 100:.2f}%")
    print(f"Weighted F1-Score:     {f1_weight * 100:.2f}%")
    print("\n" + "-"*70)
    print(f"{'Class Name':<28} | {'Prec (%)':<9} | {'Rec (%)':<8} | {'F1 (%)':<8} | {'Support'}")
    print("-"*70)

    per_class_results = {}
    for idx, c in enumerate(CLASSES):
        p = p_class[idx] * 100
        r = r_class[idx] * 100
        f1 = f1_class[idx] * 100
        sup = int(support_class[idx])
        display = CLASS_DISPLAY_NAMES.get(c, c)
        print(f"{display:<28} | {p:8.1f}% | {r:7.1f}% | {f1:7.1f}% | {sup:5d}")
        per_class_results[c] = {
            'precision': round(p, 2),
            'recall': round(r, 2),
            'f1_score': round(f1, 2),
            'support': sup
        }
    print("="*70)

    report = {
        'top1_accuracy': round(top1_acc, 2),
        'top3_accuracy': round(top3_acc, 2),
        'macro_precision': round(p_macro * 100, 2),
        'macro_recall': round(r_macro * 100, 2),
        'macro_f1': round(f1_macro * 100, 2),
        'weighted_f1': round(f1_weight * 100, 2),
        'per_class': per_class_results,
        'confusion_matrix': cm.tolist()
    }

    report_path = os.path.join(MODELS_DIR, 'evaluation_report.json')
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"\nReport saved to: {report_path}")
    return report

if __name__ == '__main__':
    evaluate_test_set()
