import os
import glob
import time
import json
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from dataset import (
    CLASSES, CLASS_TO_IDX,
    get_transforms, SkinDiseaseDataset, compute_class_weights
)
from model import build_model

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, 'data', 'processed')
MODELS_DIR = os.path.join(BASE_DIR, 'models')

def load_split_paths(split_name):
    paths = []
    labels = []
    split_dir = os.path.join(DATA_DIR, split_name)
    for cls_name in CLASSES:
        cls_dir = os.path.join(split_dir, cls_name)
        if not os.path.exists(cls_dir):
            continue
        for file in glob.glob(os.path.join(cls_dir, '*.*')):
            if file.lower().endswith(('.jpg', '.jpeg', '.png')):
                paths.append(file)
                labels.append(CLASS_TO_IDX[cls_name])
    return paths, labels

def train_epoch(model, dataloader, criterion, optimizer, device):
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0

    for images, labels in dataloader:
        images = images.to(device)
        labels = labels.to(device)

        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        running_loss += loss.item() * images.size(0)
        _, preds = torch.max(outputs, 1)
        correct += (preds == labels).sum().item()
        total += labels.size(0)

    epoch_loss = running_loss / max(total, 1)
    epoch_acc = (correct / max(total, 1)) * 100.0
    return epoch_loss, epoch_acc

def evaluate(model, dataloader, criterion, device):
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0

    with torch.no_grad():
        for images, labels in dataloader:
            images = images.to(device)
            labels = labels.to(device)

            outputs = model(images)
            loss = criterion(outputs, labels)

            running_loss += loss.item() * images.size(0)
            _, preds = torch.max(outputs, 1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)

    val_loss = running_loss / max(total, 1)
    val_acc = (correct / max(total, 1)) * 100.0
    return val_loss, val_acc

def run_training(epochs_stage1=4, epochs_stage2=10, batch_size=16):
    os.makedirs(MODELS_DIR, exist_ok=True)
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Training on device: {device}")

    # 1. Load Data
    train_paths, train_labels = load_split_paths('train')
    val_paths, val_labels = load_split_paths('val')

    if len(train_paths) == 0:
        raise RuntimeError("No training images found! Run prepare_dataset.py first.")

    print(f"Loaded {len(train_paths)} training images, {len(val_paths)} validation images across {len(CLASSES)} classes.")

    train_dataset = SkinDiseaseDataset(train_paths, train_labels, transform=get_transforms(is_training=True))
    val_dataset = SkinDiseaseDataset(val_paths, val_labels, transform=get_transforms(is_training=False))

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=0)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=0)

    # 2. Build Model
    model = build_model(num_classes=len(CLASSES), pretrained=True)
    model.to(device)

    # Class-weighted Label Smoothing Cross Entropy
    weights = compute_class_weights(train_labels, num_classes=len(CLASSES)).to(device)
    criterion = nn.CrossEntropyLoss(weight=weights, label_smoothing=0.1)

    history = {'train_loss': [], 'val_loss': [], 'train_acc': [], 'val_acc': []}
    best_val_loss = float('inf')
    best_model_path = os.path.join(MODELS_DIR, 'best_skin_model.pth')

    start_time = time.time()

    # ── STAGE 1: Train Classification Head (Feature Extractor Frozen) ───────
    print("\n" + "="*60)
    print("STAGE 1: Training Classification Head (Feature Extractor Frozen)")
    print("="*60)
    model.freeze_backbone()
    optimizer_s1 = torch.optim.AdamW(model.classifier.parameters(), lr=1e-3, weight_decay=1e-4)

    for epoch in range(1, epochs_stage1 + 1):
        t_loss, t_acc = train_epoch(model, train_loader, criterion, optimizer_s1, device)
        v_loss, v_acc = evaluate(model, val_loader, criterion, device)

        history['train_loss'].append(t_loss)
        history['val_loss'].append(v_loss)
        history['train_acc'].append(t_acc)
        history['val_acc'].append(v_acc)

        print(f"Epoch {epoch:02d}/{epochs_stage1:02d} [Stage 1] - "
              f"Train Loss: {t_loss:.4f} | Train Acc: {t_acc:.2f}% || "
              f"Val Loss: {v_loss:.4f} | Val Acc: {v_acc:.2f}%")

        if v_loss < best_val_loss:
            best_val_loss = v_loss
            torch.save(model.state_dict(), best_model_path)
            print(f"  --> Checkpoint saved: Val Loss decreased to {v_loss:.4f}")

    # ── STAGE 2: Fine-Tuning Top Bottleneck Layers ─────────────────────────
    print("\n" + "="*60)
    print("STAGE 2: End-to-End Fine-Tuning Top Bottleneck Layers")
    print("="*60)
    model.unfreeze_backbone(unfreeze_last_n_blocks=4)

    optimizer_s2 = torch.optim.AdamW([
        {'params': model.features.parameters(), 'lr': 1e-4},
        {'params': model.classifier.parameters(), 'lr': 5e-4}
    ], weight_decay=1e-4)

    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer_s2, T_max=epochs_stage2, eta_min=1e-6)

    for epoch in range(1, epochs_stage2 + 1):
        t_loss, t_acc = train_epoch(model, train_loader, criterion, optimizer_s2, device)
        v_loss, v_acc = evaluate(model, val_loader, criterion, device)
        scheduler.step()

        history['train_loss'].append(t_loss)
        history['val_loss'].append(v_loss)
        history['train_acc'].append(t_acc)
        history['val_acc'].append(v_acc)

        print(f"Epoch {epoch:02d}/{epochs_stage2:02d} [Stage 2] - "
              f"Train Loss: {t_loss:.4f} | Train Acc: {t_acc:.2f}% || "
              f"Val Loss: {v_loss:.4f} | Val Acc: {v_acc:.2f}%")

        if v_loss < best_val_loss:
            best_val_loss = v_loss
            torch.save(model.state_dict(), best_model_path)
            print(f"  --> Checkpoint saved: Val Loss decreased to {v_loss:.4f}")

    total_time = time.time() - start_time
    print("\n" + "="*60)
    print(f"Training completed in {total_time:.1f}s. Best Val Loss: {best_val_loss:.4f}")
    print(f"Best model weights saved to: {best_model_path}")

    # Save metadata & history
    history_path = os.path.join(MODELS_DIR, 'training_history.json')
    with open(history_path, 'w') as f:
        json.dump(history, f, indent=2)

    return best_model_path

if __name__ == '__main__':
    run_training(epochs_stage1=3, epochs_stage2=6)
